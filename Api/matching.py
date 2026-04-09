import json
import os
import numpy as np
from tqdm import tqdm
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

UMBRAL_SIMILITUD = 0.85
BATCH_SIZE = 500


# =========================
# CARGAR PRODUCTOS
# =========================
def cargar_productos():
    todos = []
    page_size = 1000
    pagina = 0

    print("Cargando productos paginado...")

    while True:
        try:
            rows = supabase.table("productos_raw")\
                .select("id, nombre, marca, categoria_1, precio, imagen_url, sitio, embedding")\
                .is_("master_id", "null")\
                .not_.is_("embedding", "null")\
                .range(pagina * page_size, (pagina + 1) * page_size - 1)\
                .execute().data
        except Exception as e:
            print("Error cargando productos:", e)
            break

        if not rows:
            break

        todos.extend(rows)
        print(f"  Cargados {len(todos)}")

        pagina += 1

    return todos


# =========================
# UTIL
# =========================
def parse_embedding(e):
    if isinstance(e, str):
        return json.loads(e)
    return e


# =========================
# MATCHING
# =========================
def hacer_matching():
    print("Cargando productos...")
    rows = cargar_productos()
    total = len(rows)

    if total == 0:
        print("No hay productos para procesar")
        return

    print(f"Total: {total}")

    # embeddings
    embeddings = np.array(
        [parse_embedding(r["embedding"]) for r in rows],
        dtype=np.float32
    )

    # evitar errores numéricos
    embeddings = np.nan_to_num(embeddings)

    # normalizar
    norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
    embeddings = embeddings / np.clip(norms, 1e-8, None)

    # estructuras
    master_embeddings = []
    master_index_map = np.full(total, -1, dtype=np.int64)
    masters_nuevos = []

    print("Haciendo matching...")

    for i in tqdm(range(total)):
        emb = embeddings[i]

        if master_embeddings:
            matriz = np.array(master_embeddings, dtype=np.float32)
            sims = matriz @ emb

            idx = int(np.argmax(sims))
            sim = float(sims[idx])
        else:
            sim = 0

        if sim >= UMBRAL_SIMILITUD:
            master_index_map[i] = idx
        else:
            row = rows[i]

            master_embeddings.append(emb)
            master_index_map[i] = len(master_embeddings) - 1

            masters_nuevos.append({
                "nombre_normalizado": (row["nombre"] or "").title(),
                "marca": row.get("marca"),
                "categoria": row.get("categoria_1"),
                "imagen_url": row.get("imagen_url"),
                "precio_min": row.get("precio") or 0,
                "sitio_precio_min": row.get("sitio"),
            })

    print(f"Masters nuevos: {len(masters_nuevos)}")

    # =========================
    # SUBIR MASTERS (UPSERT)
    # =========================
    print("Subiendo masters a Supabase...")

    masters_ids_reales = []

    for i in tqdm(range(0, len(masters_nuevos), BATCH_SIZE)):
        batch = masters_nuevos[i:i+BATCH_SIZE]

        try:
            res = supabase.table("productos_master")\
                .upsert(batch, on_conflict="nombre_normalizado,marca")\
                .execute()

            for item in res.data:
                masters_ids_reales.append(item["id"])

        except Exception as e:
            print("Error insertando batch:", e)

    # =========================
    # MAPEAR IDs REALES
    # =========================
    print("Mapeando IDs reales...")

    updates = []

    for i in range(total):
        idx_master = master_index_map[i]

        if 0 <= idx_master < len(masters_ids_reales):
            real_id = masters_ids_reales[idx_master]
        else:
            real_id = None

        updates.append({
            "id": rows[i]["id"],
            "master_id": real_id
        })

    # =========================
    # UPDATE EN BATCH
    # =========================
    print("Actualizando productos...")

    for i in tqdm(range(0, total, BATCH_SIZE)):
        batch = updates[i:i+BATCH_SIZE]

        try:
            supabase.rpc("update_master_ids", {
                "updates": batch
            }).execute()
        except Exception as e:
            print("Error actualizando batch:", e)

    print("✅ Matching completo")


# =========================
# MAIN
# =========================
if __name__ == "__main__":
    hacer_matching()