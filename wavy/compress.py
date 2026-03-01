import os
from PIL import Image
import glob

dummy_dir = "/home/bemnet/Documents/Wavy App/wavy/assets/images/dummy/"

files = []
for ext in ('*.png', '*.jpg', '*.jpeg'):
    files.extend(glob.glob(os.path.join(dummy_dir, '**', ext), recursive=True))

# Sort to maintain a consistent order
files.sort()

output_idx = 1
for f in files:
    if os.path.basename(f).startswith('item_'): continue
    try:
        img = Image.open(f)
        img.thumbnail((800, 800))
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        out_path = os.path.join(dummy_dir, f'item_{output_idx}.jpg')
        img.save(out_path, 'JPEG', quality=80)
        print(f"Saved {out_path}")
        
        # delete original file 
        if os.path.abspath(f) != os.path.abspath(out_path):
            os.remove(f)
            
        output_idx += 1
    except Exception as e:
        print(f"Error processing {f}: {e}")

# remove empty dirs
for root, dirs, files in os.walk(dummy_dir, topdown=False):
    for d in dirs:
        try:
            os.rmdir(os.path.join(root, d))
        except OSError:
            pass
