import random
import re

file_path = "lib/src/data/dummy_data.dart"

with open(file_path, "r") as f:
    content = f.read()

# Generate 40 items
items_str = "static final List<WavyItem> feedItems = [\n"
titles = [
    "Vintage Jacket", "Y2K Top", "Retro Sneakers", "Graphic Tee", "Crossbody Bag",
    "Midi Skirt", "Track Pants", "Maxi Dress", "Bucket Hat", "Cargo Pants",
    "Cropped Hoodie", "Vintage Sunglasses", "Wool Coat", "Platform Shoes", "Silk Scarf"
]

for i in range(1, 41):
    title = random.choice(titles)
    price = random.randint(3, 15) * 100  # 300 to 1500
    seller_id = f"seller_0{random.randint(1, 5)}"
    
    item_str = f"""    WavyItem(
      id: 'item_{i:02d}',
      title: '{title}',
      price: {price},
      size: 'M',
      condition: 'Good',
      images: ['assets/images/dummy/item_{i}.jpg'],
      sellerId: '{seller_id}',
      tagId: 'tag_{i:03d}',
      category: 'Clothing',
      createdAt: '2024-12-01',
      swipeCount: {random.randint(10, 100)},
      interestCount: {random.randint(1, 20)},
    ),
"""
    items_str += item_str

items_str += "  ];"

# Replace the block
new_content = re.sub(
    r"static final List<WavyItem> feedItems = \[.*?  \];",
    items_str,
    content,
    flags=re.DOTALL
)

with open(file_path, "w") as f:
    f.write(new_content)

print("Replaced feedItems globally.")
