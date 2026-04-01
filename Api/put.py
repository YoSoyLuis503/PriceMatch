import json
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()


supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
def cargar_walmart_a_supabase(productos):
    with open(productos, 'r', encoding='utf-8') as f:
        datos = json.load(f)
    

    maestro_batch = []
    precios_batch = []
    
    for p in datos:
   
        maestro_batch.append({
            "gtin": p.get("gtin"),
            "nombre_estandar": p.get("nombre"),
            "marca": p.get("marca"),
            "categoria_n3": p.get("categoria_nivel3"),
            "imagen_url_referencia": p.get("imagen_url")
        })
        
        precios_batch.append({
            "gtin": p.get("gtin"),
            "sitio": "walmart",
            "precio": p.get("precio"),
            "url_directa": p.get("url_producto")
        })

    chunk_size = 500
    for i in range(0, len(maestro_batch), chunk_size):
        batch = maestro_batch[i:i + chunk_size]
        print(f"Subiendo Maestros: {i} a {i + len(batch)}...")
        # Usamos UPSERT para no duplicar productos si corres el script 2 veces
        supabase.table("maestro_productos").upsert(batch).execute()

    for i in range(0, len(precios_batch), chunk_size):
        batch = precios_batch[i:i + chunk_size]
        print(f"Subiendo Precios Diarios: {i} a {i + len(batch)}...")
        # Usamos INSERT porque cada día es un registro de precio nuevo
        supabase.table("precios_diarios").insert(batch).execute()

if __name__ == "__main__":
    path = r"ArchivosTemp\itemwalmart.json"
    cargar_walmart_a_supabase(path)