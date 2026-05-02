import json
import time
import random
import os
from datetime import datetime
from playwright.sync_api import sync_playwright

CATEGORIAS_SELECTOS = {
    "01": "Productos Frescos",
    "03": "Abarrotes",
    "05": "Bebidas",
    "02": "Productos Congelados",
    "08": "Cuidado Personal",
    "07": "Cuidado del Hogar",
    "09": "Cuidado del Bebé",
    "06": "Cuidado Mascotas",
    "10": "Mercancías Generales",
    "04": "Cervezas Vinos y Licores",
    "11": "Tecnología",
    "12": "Giftcards"
}

def extract_products_from_page(page, cat_nombre):
    productos_pagina = []
    # Selector de las tarjetas según el HTML que enviaste
    items = page.locator("li.item-producto").all()
    
    for item in items:
        try:
            # 1. Nombre y URLs
            anchor_nombre = item.locator("h5.prod-nombre a")
            nombre = anchor_nombre.inner_text().strip()
            
            url_relativa = anchor_nombre.get_attribute("href") or ""
            # Limpiar URL para evitar el duplicado https://www.superselectos.comhttps://...
            if url_relativa.startswith("http"):
                url_completa = url_relativa
            else:
                url_completa = f"https://www.superselectos.com{url_relativa}"
            
            # 2. Imagen (Buscamos dentro de la figura)
            imagen_tag = item.locator(".prod-images img")
            imagen_url = imagen_tag.get_attribute("src") if imagen_tag.count() > 0 else None

            # 3. ID de Producto
            product_id = "N/A"
            if "productId=" in url_completa:
                product_id = url_completa.split("productId=")[1].split("&")[0]

            # 4. Precios
            precio_raw = item.locator("strong.precio").inner_text().strip()
            precio_limpio = float(precio_raw.replace('$', '').replace(',', '').strip())

            # Súper Selectos no siempre muestra el precio original si no hay oferta activa
            # En la plantilla, si no hay descuento, el precio_original es igual al precio.
            precio_original = precio_limpio
            tiene_descuento = False
            
            # 5. Construcción del JSON siguiendo tu plantilla EXACTA
            producto = {
                "product_id": product_id,
                "gtin": None,
                "nombre": nombre,
                "marca": None,
                "categoria_nivel1": "Supermercado",
                "categoria_nivel2": cat_nombre,
                "categoria_nivel3": None,
                "precio": precio_limpio,
                "precio_original": precio_original,
                "descuento_pct": None,
                "tiene_descuento": tiene_descuento,
                "disponible": True,
                "unidad": None,
                "url_producto": url_completa,
                "imagen_url": imagen_url,
                "cobertura": "nacional",
                "sitio": "superselectos",
                "timestamp": datetime.now().isoformat()
            }
            productos_pagina.append(producto)
        except Exception as e:
            # Si un producto falla, saltamos al siguiente para no detener el scraping masivo
            continue
            
    return productos_pagina

def scrape_category(browser_context, cat_id, cat_nombre):
    url_inicial = f"https://www.superselectos.com/products?category={cat_id}"
    page = browser_context.new_page()
    productos_categoria = []
    
    try:
        print(f"\n[PROCESANDO] {cat_nombre}...")
        page.goto(url_inicial, wait_until="networkidle", timeout=60000)
        
        while True:
            # Esperar a que los items estén presentes
            page.wait_for_selector("li.item-producto", timeout=15000)
            
            # Capturar estado de página para validar cambio
            label_pag = page.locator("label:has-text('Página')")
            texto_antes = label_pag.inner_text() if label_pag.count() > 0 else "Página 1"
            
            # Extraer con el nuevo formato
            nuevos = extract_products_from_page(page, cat_nombre)
            productos_categoria.extend(nuevos)
            print(f"   {texto_antes}: {len(nuevos)} productos capturados.")

            # Navegación
            btn_sig = page.locator("li.page-item:not(.disabled) a.page-link:has-text('Siguiente')")
            
            if btn_sig.count() == 0:
                break
                
            btn_sig.click()
            
            # Esperar a que el label cambie (o sleep de 5s si no hay label)
            if label_pag.count() > 0:
                try:
                    page.wait_for_function(
                        f"document.querySelector(\"label:contains('Página')\").innerText !== '{texto_antes}'",
                        timeout=12000
                    )
                except:
                    time.sleep(4)
            else:
                break # Solo una página disponible
                
            time.sleep(random.uniform(1, 3))
                
    except Exception as e:
        print(f"   Aviso: Final de categoría o estructura sin paginación.")
    finally:
        page.close()
        return productos_categoria

def main():
    with sync_playwright() as p:
        # headless=False para que puedas ver que las imágenes cargan bien
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(viewport={'width': 1280, 'height': 800})
        
        output_dir = "resultados_selectos"
        if not os.path.exists(output_dir): os.makedirs(output_dir)

        for cat_id, cat_nombre in CATEGORIAS_SELECTOS.items():
            data = scrape_category(context, cat_id, cat_nombre)
            
            # Guardado consistente
            filename = f"{output_dir}/selectos_{cat_id}.json"
            with open(filename, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4, ensure_ascii=False)
            
            print(f"--- Guardado {filename} con {len(data)} items ---")
            time.sleep(3)

        browser.close()

if __name__ == "__main__":
    main()