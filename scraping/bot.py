import json
from playwright.sync_api import sync_playwright


def scrape_farmavalue(url):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        page = browser.new_page()

        # Ir a la página
        page.goto(url, timeout=60000)

        # 🔥 Esperar a que cargue contenido dinámico
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(5000)  # extra seguridad

        producto_data = None

        # Obtener todos los scripts JSON-LD
        scripts = page.locator("script[type='application/ld+json']").all()

        for script in scripts:
            try:
                contenido = script.inner_text().strip()

                if not contenido:
                    continue

                data = json.loads(contenido)

                # Buscar el producto real
                if data.get("@type") == "Product":

                    nombre = data.get("name", "")
                    precio = data.get("offers", {}).get("price", 0)

                    # ❌ Ignorar datos falsos
                    if "Cargando" in nombre or precio == 0:
                        continue

                    producto_data = data
                    break

            except Exception as e:
                continue

        browser.close()

        if not producto_data:
            return {
                "error": "No se encontró producto válido"
            }

        return {
            "nombre": producto_data.get("name"),
            "precio": float(producto_data.get("offers", {}).get("price", 0)),
            "moneda": producto_data.get("offers", {}).get("priceCurrency"),
            "imagen": producto_data.get("image"),
            "disponible": "InStock" in producto_data.get("offers", {}).get("availability", ""),
            "url": url,
            "sitio": "farmavalue"
        }


# 🔥 PRUEBA
if __name__ == "__main__":
    url = "https://www.farmavalue.com/sv/products/13741-vitamina-e-400ui-adiuvo-30-capsulas-de-gelatina-blandas"
    
    data = scrape_farmavalue(url)
    print(data)