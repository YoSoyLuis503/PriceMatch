import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Usamos el modelo que ya viste en tus métricas
model = genai.GenerativeModel('gemma-3-27b-it')

def procesar_lote_productos(lista_cruda):
    prompt = f"""
    Eres un experto en retail de El Salvador. 
    Recibirás una lista de productos extraídos de webs de supermercados.
    Tu tarea es devolver un JSON purificado con:
    1. nombre_estandar: Nombre limpio (ej: 'Leche Salud Entera 1L')
    2. marca: La marca identificada.
    3. cantidad: Solo el número y unidad (ej: '1L', '75ml', '500g').
    4. categoria: Una categoría lógica (Lácteos, Higiene, Granos, etc.)

    LISTA DE PRODUCTOS:
    {lista_cruda}

    Devuelve ÚNICAMENTE un array de objetos JSON.
    """

    response = model.generate_content(prompt)
    return response.text

# Prueba con datos reales de El Salvador
productos_super = [
    "Leche entera Salud 1000ml bolsa",
    "Pasta dental Colgate triple acc 75ml x3 pack",
    "Arroz blanco San Francisco 1lb"
]

resultado = procesar_lote_productos(productos_super)
print(resultado)