from sentence_transformers import SentenceTransformer
from supabase import create_client
from dotenv import load_dotenv
import os, time

load_dotenv()
supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

def generar_embeddings():
    print("Cargando modelo... (primera vez descarga ~970MB)")
    modelo = SentenceTransformer("paraphrase-multilingual-mpnet-base-v2")
    print("Modelo listo.")

    rows = supabase.table("productos_raw")\
        .select("id, nombre, marca, categoria_1")\
        .is_("embedding", "null")\
        .execute().data

    total = len(rows)
    print(f"Productos pendientes: {total}")

    if total == 0:
        print("¡Todos los productos ya tienen embedding!")
        return

    batch_size = 256
    for i in range(0, total, batch_size):
        batch = rows[i:i+batch_size]
        textos = [
            f"{r['nombre']} {r['marca'] or ''} {r['categoria_1'] or ''}".strip()
            for r in batch
        ]

        embeddings = modelo.encode(textos, show_progress_bar=True)

        for j, row in enumerate(batch):
            supabase.table("productos_raw")\
                .update({"embedding": embeddings[j].tolist()})\
                .eq("id", row["id"])\
                .execute()

        print(f"  ✓ {min(i+batch_size, total)}/{total}")

    print("\n¡Embeddings completos!")

if __name__ == "__main__":
    generar_embeddings()