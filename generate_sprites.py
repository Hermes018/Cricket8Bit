import os
from PIL import Image, ImageDraw

os.makedirs('assets/sprites', exist_ok=True)

# 1. Bowler Atlas (4 frames, 32x32 each)
img_bowler = Image.new('RGBA', (128, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(img_bowler)

# Frame 0: Idle
draw.rectangle([10, 10, 22, 30], fill=(200, 50, 50, 255)) # body
draw.ellipse([12, 2, 20, 10], fill=(255, 200, 150, 255)) # head
draw.ellipse([8, 14, 12, 18], fill=(255, 0, 0, 255)) # ball in hand

# Frame 1: Run-up 1
draw.rectangle([10+32, 10, 22+32, 30], fill=(200, 50, 50, 255))
draw.ellipse([12+32, 2, 20+32, 10], fill=(255, 200, 150, 255))
draw.ellipse([8+32, 14, 12+32, 18], fill=(255, 0, 0, 255))

# Frame 2: Run-up 2
draw.rectangle([10+64, 10, 22+64, 30], fill=(200, 50, 50, 255))
draw.ellipse([12+64, 2, 20+64, 10], fill=(255, 200, 150, 255))
draw.ellipse([12+64, 2, 16+64, 6], fill=(255, 0, 0, 255)) # ball up

# Frame 3: Release
draw.rectangle([10+96, 10, 22+96, 30], fill=(200, 50, 50, 255))
draw.ellipse([12+96, 2, 20+96, 10], fill=(255, 200, 150, 255))
draw.ellipse([26+96, 16, 30+96, 20], fill=(255, 0, 0, 255)) # ball released

img_bowler.save('assets/sprites/bowler_atlas.png')

# 2. Batsman Atlas (3 frames, 32x32 each)
img_bat = Image.new('RGBA', (96, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(img_bat)

# Frame 0: Stance
draw.rectangle([10, 10, 22, 30], fill=(50, 50, 200, 255)) # body
draw.ellipse([12, 2, 20, 10], fill=(255, 200, 150, 255)) # head
draw.rectangle([6, 16, 10, 32], fill=(200, 150, 50, 255)) # bat resting

# Frame 1: Backlift
draw.rectangle([10+32, 10, 22+32, 30], fill=(50, 50, 200, 255))
draw.ellipse([12+32, 2, 20+32, 10], fill=(255, 200, 150, 255))
draw.polygon([(10+32, 16), (4+32, 8), (8+32, 6), (14+32, 14)], fill=(200, 150, 50, 255)) # bat lifted

# Frame 2: Swing
draw.rectangle([10+64, 10, 22+64, 30], fill=(50, 50, 200, 255))
draw.ellipse([12+64, 2, 20+64, 10], fill=(255, 200, 150, 255))
draw.polygon([(10+64, 20), (22+64, 18), (24+64, 22), (12+64, 24)], fill=(200, 150, 50, 255)) # bat forward

img_bat.save('assets/sprites/batsman_atlas.png')

print("Sprites generated successfully.")
