from sentence_transformers import SentenceTransformer
from supabase import create_client
from dotenv import load_dotenv
import os, torch, json
from tqdm import tqdm

load_dotenv()
supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

def generar_embeddings():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Usando: {device.upper()}")

    modelo = SentenceTransformer("paraphrase-multilingual-mpnet-base-v2", device=device)
    print("Modelo listo.\n")

    pagina = 0
    page_size = 1000
    total_procesados = 0

    while True:
        # Traer siguiente página de pendientes
        rows = supabase.table("productos_raw")\
            .select("id, nombre, marca, categoria_1")\
            .is_("embedding", "null")\
            .range(pagina * page_size, (pagina + 1) * page_size - 1)\
            .execute().data

        if not rows:
            break

        print(f"Página {pagina + 1}: {len(rows)} productos")

        # Generar embeddings con GPU
        textos = [
            f"{r['nombre']} {r['marca'] or ''} {r['categoria_1'] or ''}".strip()
            for r in rows
        ]
        embeddings = modelo.encode(
            textos,
            show_progress_bar=True,
            convert_to_numpy=True,
            batch_size=512,
            device=device
        )

        # Subir via RPC en batches de 200
        batch_size = 200
        for i in range(0, len(rows), batch_size):
            batch_rows = rows[i:i+batch_size]
            updates = [
                {"id": batch_rows[j]["id"], "embedding": embeddings[i+j].tolist()}
                for j in range(len(batch_rows))
            ]
            supabase.rpc("update_embeddings", {"updates": updates}).execute()

        total_procesados += len(rows)
        print(f"  ✓ Total procesados hasta ahora: {total_procesados}\n")

        # Si trajo menos de page_size, era la última página
        if len(rows) < page_size:
            break

        pagina += 1

    print(f"¡Listo! Total embeddings generados: {total_procesados}")

if __name__ == "__main__":
    generar_embeddings()