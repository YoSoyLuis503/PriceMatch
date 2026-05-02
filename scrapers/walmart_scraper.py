# scrapers/walmart_scraper.py

import requests
import json
import time
import os
from datetime import datetime

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "application/json",
}
BASE_URL = "https://www.walmart.com.sv/api/catalog_system/pub/products/search"
LIMITE_VTEX = 2500

# Ordenamientos distintos para maximizar cobertura
ORDENAMIENTOS = [
    "OrderByPriceASC",
    "OrderByPriceDESC",
    "OrderByNameASC",
    "OrderByNameDESC",
    "OrderByTopSaleDESC",
]


# ── Request con reintentos ─────────────────────────────────────────────────

def request_con_reintento(params: dict, max_intentos: int = 4) -> list | None:
    for intento in range(max_intentos):
        try:
            resp = requests.get(BASE_URL, headers=HEADERS,
                                params=params, timeout=15)
            if resp.status_code == 400:
                return None
            if resp.status_code == 429:
                espera = 45 * (intento + 1)
                print(f"  Rate limit — esperando {espera}s...")
                time.sleep(espera)
                continue
            resp.raise_for_status()
            data = resp.json()
            if isinstance(data, str):
                return None
            return data
        except requests.RequestException as e:
            if intento < max_intentos - 1:
                time.sleep(10)
            else:
                print(f"  Falló: {e}")
                return None
    return None


# ── Paginación con un ordenamiento ────────────────────────────────────────

def scrape_con_orden(cat_id: int, orden: str,
                     batch_size: int = 50,
                     pausa: float = 1.5) -> dict:
    """
    Scrapea hasta 2500 productos de una categoría con un ordenamiento dado.
    Retorna dict {product_id: producto_parseado}.
    """
    productos = {}
    desde = 0

    while True:
        if desde >= LIMITE_VTEX:
            break

        hasta = min(desde + batch_size - 1, LIMITE_VTEX - 1)
        params = {
            "fq":    f"C:{cat_id}",
            "O":     orden,
            "_from": desde,
            "_to":   hasta,
        }
        batch = request_con_reintento(params)

        if batch is None or not batch:
            break

        for raw in batch:
            p = parsear_producto(raw)
            if p:
                productos[p["product_id"]] = p

        if len(batch) < batch_size:
            break

        desde += batch_size
        time.sleep(pausa)

    return productos


# ── Scrape completo de una categoría nivel 1 ──────────────────────────────

def scrape_categoria(cat_id: int, cat_nombre: str,
                     pausa: float = 1.5) -> list[dict]:
    """
    Scrapea una categoría con múltiples ordenamientos para superar
    el límite de 2500 de VTEX. Deduplica por product_id.
    """
    todos = {}  # product_id → producto

    for orden in ORDENAMIENTOS:
        antes = len(todos)
        nuevos_orden = scrape_con_orden(cat_id, orden, pausa=pausa)
        todos.update(nuevos_orden)
        nuevos = len(todos) - antes
        print(f"  [{orden}]: {len(nuevos_orden)} productos "
              f"({nuevos} nuevos, total: {len(todos)})")

        # Si ya no aporta productos nuevos, parar
        if nuevos == 0:
            print(f"   Sin productos nuevos — parando ordenamientos")
            break

        time.sleep(pausa)

    return list(todos.values())


# ── Parseo ─────────────────────────────────────────────────────────────────

def parsear_producto(raw: dict) -> dict | None:
    try:
        precio = None
        precio_original = None
        disponible = False

        items = raw.get("items", [])
        if items:
            sellers = items[0].get("sellers", [])
            if sellers:
                oferta          = sellers[0].get("commertialOffer", {})
                precio          = oferta.get("Price")
                precio_original = oferta.get("ListPrice")
                disponible      = oferta.get("IsAvailable", False)

        if precio is None:
            return None

        imagen_url = None
        if items and items[0].get("images"):
            imagen_url = items[0]["images"][0].get("imageUrl")

        categorias = raw.get("categories", [])
        cat_completa = categorias[0].strip("/") if categorias else None
        niveles = cat_completa.split("/") if cat_completa else []

        tamanio = raw.get("Tamaño (Gramaje, Volumen)", [None])[0]
        medida  = raw.get("Medida de peso", [None])[0]

        return {
            "product_id":       raw.get("productId"),
            "gtin":             raw.get("productReference", "").replace("GTIN-", ""),
            "nombre":           raw.get("productName"),
            "marca":            raw.get("brand"),
            "categoria_nivel1": niveles[0] if len(niveles) > 0 else None,
            "categoria_nivel2": niveles[1] if len(niveles) > 1 else None,
            "categoria_nivel3": niveles[2] if len(niveles) > 2 else None,
            "precio":           precio,
            "precio_original":  precio_original,
            "tiene_descuento":  (precio < precio_original
                                 if precio_original else False),
            "disponible":       disponible,
            "unidad":           tamanio or medida,
            "url_producto":     raw.get("link"),
            "imagen_url":       imagen_url,
            "cobertura":        "nacional",
            "sitio":            "walmart",
            "timestamp":        datetime.now().isoformat(),
        }
    except Exception as e:
        print(f"  ⚠️  Error parseando {raw.get('productId')}: {e}")
        return None


# ── Guardar ────────────────────────────────────────────────────────────────

def guardar_raw(productos: list[dict], nombre: str) -> str:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = f"data/raw/walmart_{nombre}_{timestamp}.json"
    os.makedirs("data/raw", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(productos, f, ensure_ascii=False, indent=2)
    print(f"Guardado en {path}")
    return path


# ── Orquestador ────────────────────────────────────────────────────────────

def scrape_walmart(pausa: float = 1.5) -> list[dict]:
    # Obtener categorías nivel 1
    resp = requests.get(
        "https://www.walmart.com.sv/api/catalog_system/pub/category/tree/1",
        headers=HEADERS, timeout=15
    )
    cats_nivel1 = resp.json()
    print(f"🚀 Walmart — {len(cats_nivel1)} categorías de nivel 1")
    print("=" * 55)

    todos = {}
    resumen = []

    for i, cat in enumerate(cats_nivel1, 1):
        cat_id     = cat["id"]
        cat_nombre = cat["name"]

        print(f"\n[{i}/{len(cats_nivel1)}] {cat_nombre} (ID: {cat_id})")

        productos = scrape_categoria(cat_id, cat_nombre, pausa=pausa)

        # Deduplicar global
        nuevos = 0
        for p in productos:
            if p["product_id"] not in todos:
                nuevos += 1
            todos[p["product_id"]] = p

        print(f"   {cat_nombre}: {len(productos)} únicos "
              f"({nuevos} nuevos al total global)")

        resumen.append({
            "categoria": cat_nombre,
            "total":     len(productos),
            "nuevos":    nuevos,
        })

        # Checkpoint cada 5 categorías
        if i % 5 == 0:
            checkpoint = list(todos.values())
            guardar_raw(checkpoint, f"checkpoint_{i}cats")
            print(f"  Checkpoint: {len(checkpoint)} productos únicos")

        time.sleep(pausa)

    resultado = list(todos.values())

    print(f"\n{'=' * 55}")
    print("Resumen final:")
    for r in resumen:
        print(f"  {r['categoria']:<35} {r['total']:>6} productos")
    print(f"{'─' * 55}")
    print(f"  TOTAL ÚNICOS GLOBAL: {len(resultado)}")

    return resultado


if __name__ == "__main__":
    productos = scrape_walmart(pausa=1.5)
    guardar_raw(productos, "completo")