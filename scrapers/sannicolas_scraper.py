# scrapers/sannicolas_scraper.py

import asyncio
import json
import os
import re
from datetime import datetime
from playwright.async_api import async_playwright

BASE_URL = "https://www.farmaciasannicolas.com"

CATEGORIAS = [
    # Medicamentos
    {"id": "01001", "nombre": "Alergias",                          "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01002", "nombre": "Antibioticos y cicatrizantes",      "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01003", "nombre": "Corazon y presion arterial",        "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01004", "nombre": "Diabetes",                          "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01005", "nombre": "Dolor y fiebre",                    "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01006", "nombre": "Gastrointestinales",                "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01007", "nombre": "Gripe, tos y asma",                 "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01008", "nombre": "Hemorroides y varices",             "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01009", "nombre": "Higado",                            "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01010", "nombre": "Huesos, musculos y articulaciones", "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01011", "nombre": "Leches, formulas y suplementos",    "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01012", "nombre": "Medicamentos homeopaticos",         "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01013", "nombre": "Menopausia y tratamientos hormonales", "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01014", "nombre": "Nutricion y dieta",                 "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01015", "nombre": "Salud visual",                      "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01016", "nombre": "Primeros auxilios",                 "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01017", "nombre": "Sistema nervioso",                  "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01018", "nombre": "Tiroides",                          "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01019", "nombre": "Vitaminas y sistema inmunologico",  "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01020", "nombre": "Piel",                              "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01021", "nombre": "Oncologicos",                       "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01022", "nombre": "Salud bucal",                       "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01023", "nombre": "Sueros",                            "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01024", "nombre": "Esteroides",                        "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01025", "nombre": "Vias urinarias y prostata",         "nivel1": "Medicamentos", "tipo": "category"},
    {"id": "01026", "nombre": "Afecciones vaginales",              "nivel1": "Medicamentos", "tipo": "category"},
    # Conveniencia
    {"id": "02100", "nombre": "Snacks y alimentos",                "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02101", "nombre": "Bebidas",                           "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02102", "nombre": "Cuidado del cabello",               "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02103", "nombre": "Cuidado facial",                    "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02105", "nombre": "Fitness y ortopedia",               "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02106", "nombre": "Higiene bucal",                     "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02107", "nombre": "Higiene y cuidado corporal",        "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02108", "nombre": "Hogar",                             "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02110", "nombre": "Libros revistas y periodicos",      "nivel1": "Conveniencia", "tipo": "category"},
    {"id": "02111", "nombre": "Mamas y bebes",                     "nivel1": "Conveniencia", "tipo": "category"},
    # Dermocosmética
    {"id": "1999005", "nombre": "Rostro",  "nivel1": "Dermocosmetica", "tipo": "dermocosmetica"},
    {"id": "1999002", "nombre": "Cuerpo",  "nivel1": "Dermocosmetica", "tipo": "dermocosmetica"},
    {"id": "1999006", "nombre": "Solar",   "nivel1": "Dermocosmetica", "tipo": "dermocosmetica"},
    {"id": "1999001", "nombre": "Capilar", "nivel1": "Dermocosmetica", "tipo": "dermocosmetica"},
    {"id": "1999004", "nombre": "Niños",   "nivel1": "Dermocosmetica", "tipo": "dermocosmetica"},
]


# ── Parseo de producto ─────────────────────────────────────────────────────

async def parsear_producto(card, categoria: dict) -> dict | None:
    """Extrae los campos de una tarjeta de producto del HTML."""
    try:
        # Nombre
        nombre_el = await card.query_selector("h3.prod-name a, .prod-name a")
        nombre = (await nombre_el.inner_text()).strip() if nombre_el else None
        if not nombre:
            return None

        # URL del producto
        href = await nombre_el.get_attribute("href") if nombre_el else None
        url_producto = f"{BASE_URL}{href}" if href else None

        # Extraer product_id de la URL
        # Formato: /producto/Nombre-Producto/A7616UNIDADX1
        product_id = None
        if href:
            partes = href.rstrip("/").split("/")
            if partes:
                product_id = partes[-1]  # ej: "A7616UNIDADX1"

        # Imagen
        img_el = await card.query_selector("figure img")
        imagen_url = await img_el.get_attribute("src") if img_el else None

        # Precio actual
        precio_el = await card.query_selector(".pp-price")
        precio_texto = await precio_el.inner_text() if precio_el else None
        precio = parsear_precio(precio_texto)

        # Precio original (antes del descuento)
        precio_original_el = await card.query_selector(".prices-top .before")
        precio_original_texto = await precio_original_el.inner_text() if precio_original_el else None
        precio_original = parsear_precio(precio_original_texto)

        # Si no hay precio original, es igual al actual
        if precio_original is None:
            precio_original = precio

        # Descuento % — etiqueta visible en la tarjeta
        descuento_el = await card.query_selector(".prod-label")
        descuento_texto = await descuento_el.inner_text() if descuento_el else None
        descuento_pct = descuento_texto.strip() if descuento_texto else None

        tiene_descuento = (
            precio is not None and
            precio_original is not None and
            precio < precio_original
        )

        return {
            "product_id":       product_id,
            "gtin":             None,          # San Nicolás no expone GTIN
            "nombre":           nombre,
            "marca":            None,          # se extrae de página de detalle (ver nota)
            "categoria_nivel1": categoria["nivel1"],
            "categoria_nivel2": categoria["nombre"],
            "categoria_nivel3": None,
            "precio":           precio,
            "precio_original":  precio_original,
            "descuento_pct":    descuento_pct,
            "tiene_descuento":  tiene_descuento,
            "disponible":       True,          # si aparece en el listado, está disponible
            "unidad":           None,          # no disponible en listado
            "url_producto":     url_producto,
            "imagen_url":       imagen_url,
            "cobertura":        "nacional",
            "sitio":            "sannicolas",
            "timestamp":        datetime.now().isoformat(),
        }

    except Exception as e:
        print(f"   Error parseando producto: {e}")
        return None


def parsear_precio(texto: str) -> float | None:
    """Convierte '$1.83' o '$2.15' a float."""
    if not texto:
        return None
    try:
        limpio = re.sub(r"[^\d.]", "", texto.strip())
        return float(limpio) if limpio else None
    except ValueError:
        return None


# ── Scraping de una página ─────────────────────────────────────────────────

async def scrape_pagina(page, categoria: dict, num_pagina: int) -> list[dict]:
    """Extrae todos los productos de una página ya cargada."""
    cards = await page.query_selector_all(".product-item-box")

    productos = []
    for card in cards:
        p = await parsear_producto(card, categoria)
        if p:
            productos.append(p)

    return productos


# ── Scraping de una categoría completa ────────────────────────────────────

async def scrape_categoria(page, categoria: dict, pausa: float = 2.0) -> list[dict]:
    """Scrapea todas las páginas de una categoría."""
    productos = {}
    num_pagina = 1

    while True:
        # Construir URL según tipo
        if categoria["tipo"] == "category":
            url = f"{BASE_URL}/category/{categoria['id']}?page={num_pagina}"
        else:
            url = (f"{BASE_URL}/dermocosmetica/{categoria['id']}"
                   f"/productos?page={num_pagina}")

        print(f"    Página {num_pagina}: {url}")

        await page.goto(url, wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)

        # Verificar si hay productos
        cards = await page.query_selector_all(".product-item-box")
        if not cards:
            print(f"  Sin productos en página {num_pagina} — fin de categoría")
            break

        batch = await scrape_pagina(page, categoria, num_pagina)
        nuevos = 0
        for p in batch:
            if p["product_id"] not in productos:
                nuevos += 1
            productos[p["product_id"]] = p

        print(f"    {len(batch)} productos ({nuevos} nuevos)")

        # Verificar si hay más páginas
        siguiente = await page.query_selector(".pg-link-next:not([data-disabled])")
        if not siguiente:
            print(f"    ✅ Última página alcanzada")
            break

        # También verificar por el total de páginas
        paginacion = await page.query_selector(".btw-pagination-pages")
        if paginacion:
            total_paginas = await paginacion.get_attribute("data-pg-total")
            if total_paginas and num_pagina >= int(total_paginas):
                break

        num_pagina += 1
        await asyncio.sleep(pausa)

    return list(productos.values())


# ── Guardar ────────────────────────────────────────────────────────────────

def guardar_raw(productos: list[dict], nombre: str) -> str:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = f"data/raw/sannicolas_{nombre}_{timestamp}.json"
    os.makedirs("data/raw", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(productos, f, ensure_ascii=False, indent=2)
    print(f" Guardado en {path}")
    return path


# ── Orquestador ────────────────────────────────────────────────────────────

async def scrape_sannicolas(pausa: float = 2.0):
    todos = {}
    resumen = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            viewport={"width": 1280, "height": 800}
        )
        page = await context.new_page()

        for i, cat in enumerate(CATEGORIAS, 1):
            print(f"\n[{i}/{len(CATEGORIAS)}] {cat['nivel1']} > {cat['nombre']}")

            try:
                productos = await scrape_categoria(page, cat, pausa=pausa)

                nuevos = 0
                for prod in productos:
                    pid = prod["product_id"]
                    if pid and pid not in todos:
                        nuevos += 1
                    if pid:
                        todos[pid] = prod

                print(f"   {len(productos)} productos ({nuevos} nuevos al total)")
                resumen.append({
                    "categoria": f"{cat['nivel1']} > {cat['nombre']}",
                    "total": len(productos),
                    "nuevos": nuevos,
                })

            except Exception as e:
                print(f"   Error en {cat['nombre']}: {e}")
                resumen.append({
                    "categoria": f"{cat['nivel1']} > {cat['nombre']}",
                    "total": 0,
                    "nuevos": 0,
                })

            # Checkpoint cada 10 categorías
            if i % 10 == 0:
                checkpoint = list(todos.values())
                guardar_raw(checkpoint, f"checkpoint_{i}cats")
                print(f"   Checkpoint: {len(checkpoint)} productos únicos")

        await browser.close()

    resultado = list(todos.values())

    print(f"\n{'=' * 55}")
    print(" Resumen:")
    for r in resumen:
        print(f"  {r['categoria']:<45} {r['total']:>5}")
    print(f"{'─' * 55}")
    print(f"  TOTAL ÚNICOS: {len(resultado)}")

    return resultado


# ── Punto de entrada ───────────────────────────────────────────────────────

if __name__ == "__main__":
    productos = asyncio.run(scrape_sannicolas(pausa=2.0))
    guardar_raw(productos, "completo")

    print("\n── Muestra de 2 productos ──")
    for p in productos[:2]:
        print(json.dumps(p, indent=2, ensure_ascii=False))
