from PIL import Image
import os

img_path = 'wavy/assets/wavy_logo_clean.png'
if os.path.exists(img_path):
    img = Image.open(img_path)
    # Resize to something reasonable for a mobile app header height (e.g. 100px height)
    aspect_ratio = img.width / img.height
    new_height = 100
    new_width = int(new_height * aspect_ratio)
    img = img.resize((new_width, new_height), Image.LANCZOS)
    img.save('wavy/assets/wavy_logo_clean.png', 'PNG', optimize=True)
    print(f"Logo compressed. New size: {os.path.getsize(img_path)} bytes")
