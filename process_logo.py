from PIL import Image
import os

img_path = 'wavy/assets/wavy_logo.png'
if os.path.exists(img_path):
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    
    # Simple crop to bottom half since user said "only use the text" and the text is WAVY at the bottom
    # We will crop from mid-y to bottom.
    cropped = img.crop((0, int(height * 0.55), width, height))
    
    # Check if the background is pseudo-transparent (checkerboard pattern) or pure white/black
    # For now, let's just save it. Wait, the user said "remove the background".
    # Since I can't easily do complex background removal without an AI service locally,
    # I'll try to make white or nearly-white/grey pixels transparent if it's a solid bg.
    data = cropped.getdata()
    new_data = []
    for item in data:
        # if pixel is close to black or white or checkered, make transparent?
        # A checkered bg is typically #CCCCCC and #FFFFFF
        # Let's remove #cccccc and #ffffff?
        r, g, b, a = item
        if a > 0:
            if (r > 240 and g > 240 and b > 240) or (abs(r-204)<10 and abs(g-204)<10 and abs(b-204)<10): 
                # White or very light grey -> transparent
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        else:
            new_data.append(item)
            
    cropped.putdata(new_data)
    cropped.save('wavy/assets/wavy_logo_clean.png', 'PNG', optimize=True)
    print("Logo processed and saved.")
else:
    print("Logo not found.")
