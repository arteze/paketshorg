#!/bin/python

import base64
import re
import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageTk, UnidentifiedImageError, ImageDraw
from io import BytesIO
import sys
import html

# Función para extraer y decodificar imágenes base64 de un HTML
def extract_base64_images(html_content):
    # Decodificar entidades HTML
    html_content = html.unescape(html_content)
    base64_images = re.findall(r'data:image/(png|jpeg|jpg|gif);base64,([A-Za-z0-9+/=]+)', html_content)
    return base64_images

# Función para crear una imagen superpuesta transparente celeste
def create_overlay_image(image):
    overlay = Image.new("RGBA", image.size, (0, 255, 255, 128))  # Celeste con transparencia
    combined = Image.alpha_composite(image.convert("RGBA"), overlay)
    return combined

# Función para mostrar las imágenes extraídas en la ventana
def show_images(base64_images, title):
    root = tk.Tk()
    root.title(title)

    # Tamaño de la ventana
    window_width = 400
    window_height = 425

    # Obtener el tamaño de la pantalla
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()

    # Calcular la posición de la ventana para centrarla
    position_x = (screen_width // 2) - (window_width // 2)
    position_y = (screen_height // 2) - (window_height // 2)

    # Establecer la geometría de la ventana
    root.geometry(f"{window_width}x{window_height}+{position_x}+{position_y}")

    # Crear un frame para el título
    title_frame = ttk.Frame(root)
    title_frame.pack(fill="x", pady=0)
    title_label = ttk.Label(title_frame, text=title, font=("Monospace", 16))
    title_label.pack()

    # Crear un frame para las imágenes
    image_frame = ttk.Frame(root)
    image_frame.pack(fill="both", expand=True)

    selected_images = []

    def on_image_click(label, original_image, overlay_image, index):
        if index in selected_images:
            selected_images.remove(index)
            label.config(image=original_image)
        else:
            selected_images.append(index)
            label.config(image=overlay_image)
        
        # Ordenar los números de las imágenes seleccionadas de menor a mayor
        sorted_images = sorted(selected_images)
        
        # String de elegidos
        selected_string = "".join(map(str, sorted_images))
        
        # Mostrar el número de las imágenes seleccionadas en el input
        selected_images_input.set(selected_string)

        # Terminar el programa si se seleccionan 3 imágenes
        if len(selected_images) == 3:
            print("Elegidos:",selected_string)
            root.quit()

    # Variable para mostrar las imágenes seleccionadas
    selected_images_input = tk.StringVar()

    # Configurar las columnas para que se expandan y centrar las imágenes
    columns = 3
    for col in range(columns):
        image_frame.columnconfigure(col, weight=1)

    # Crear y mostrar las imágenes en 3 columnas
    for i, (img_type, img_data) in enumerate(base64_images):
        try:
            image_data = base64.b64decode(img_data)
            image = Image.open(BytesIO(image_data))
            photo = ImageTk.PhotoImage(image)

            # Crear la imagen superpuesta
            overlay_image = create_overlay_image(image)
            overlay_photo = ImageTk.PhotoImage(overlay_image)

            label = ttk.Label(image_frame, image=photo)
            label.image = photo
            label.grid(row=i // columns, column=i % columns, padx=0, pady=0, sticky="nsew")
            label.bind("<Button-1>", lambda e, lbl=label, orig=photo, over=overlay_photo, idx=i: on_image_click(lbl, orig, over, idx))
        except (base64.binascii.Error, UnidentifiedImageError) as e:
            print(f"Error al decodificar o abrir la imagen {i + 1}: {e}")

    # Input para mostrar números de imágenes seleccionadas
    input_frame = ttk.Frame(root)
    input_frame.pack(fill="x", pady=0)
    selected_images_label = ttk.Label(input_frame, text="Imágenes seleccionadas:")
    selected_images_label.pack(side="left", padx=0)
    selected_images_entry = ttk.Entry(input_frame, textvariable=selected_images_input)
    selected_images_entry.pack(side="left", padx=0)

    root.mainloop()

def main():
    if len(sys.argv) != 3:
        print("Uso: python script.py archivo.html 'Título del Programa'")
        return

    html_path = sys.argv[1]
    title = sys.argv[2]

    try:
        with open(html_path, "r", encoding="utf-8") as file:
            html_content = file.read()
    except Exception as e:
        print(f"Error al leer el archivo HTML: {e}")
        return

    # Extraer imágenes base64 del contenido HTML
    base64_images = extract_base64_images(html_content)

    # Mostrar las imágenes en la ventana
    show_images(base64_images, title)

if __name__ == "__main__":
    main()
