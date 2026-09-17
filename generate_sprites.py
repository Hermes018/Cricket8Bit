import os
from PIL import Image, ImageDraw

os.makedirs('assets/sprites', exist_ok=True)

def c_bat(): return (200, 150, 50, 255)
def c_body(team="blue"): return (50, 50, 200, 255) if team == "blue" else (200, 50, 50, 255)
def c_head(): return (255, 200, 150, 255)
def c_ball(): return (255, 0, 0, 255)
def c_ump(): return (20, 20, 20, 255)

# --- BATSMAN (10 frames) ---
img_bat = Image.new('RGBA', (320, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_bat)
for i in range(10):
    x = i * 32
    d.rectangle([10+x, 10, 22+x, 30], fill=c_body("blue"))
    d.ellipse([12+x, 2, 20+x, 10], fill=c_head())

# 0: Idle
d.rectangle([6, 16, 10, 32], fill=c_bat())
# 1: Def prep
d.polygon([(10+32, 16), (4+32, 8), (8+32, 6), (14+32, 14)], fill=c_bat())
# 2: Def block
d.rectangle([6+64, 16, 10+64, 32], fill=c_bat())
# 3: Drive prep
d.polygon([(10+96, 16), (4+96, 8), (8+96, 6), (14+96, 14)], fill=c_bat())
# 4: Drive swing
d.polygon([(10+128, 20), (22+128, 18), (24+128, 22), (12+128, 24)], fill=c_bat())
# 5: Pull prep
d.polygon([(16+160, 10), (26+160, 2), (30+160, 6), (20+160, 14)], fill=c_bat())
# 6: Pull swing
d.polygon([(10+192, 14), (28+192, 14), (28+192, 18), (10+192, 18)], fill=c_bat())
# 7: Loft prep
d.polygon([(10+224, 16), (4+224, 8), (8+224, 6), (14+224, 14)], fill=c_bat())
# 8: Loft swing (high follow through)
d.polygon([(10+256, 12), (0+256, 2), (2+256, 0), (12+256, 10)], fill=c_bat())
# 9: Out (bat dropped)
d.rectangle([16+288, 30, 28+288, 32], fill=c_bat())
img_bat.save('assets/sprites/batsman_atlas.png')


# --- BOWLER (8 frames) ---
img_bowl = Image.new('RGBA', (256, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_bowl)
for i in range(8):
    x = i * 32
    d.rectangle([10+x, 10, 22+x, 30], fill=c_body("red"))
    d.ellipse([12+x, 2, 20+x, 10], fill=c_head())

# 0-3: Pace Run-up
d.ellipse([8, 14, 12, 18], fill=c_ball())
d.ellipse([8+32, 14, 12+32, 18], fill=c_ball())
d.ellipse([12+64, 2, 16+64, 6], fill=c_ball())
d.ellipse([12+96, 2, 16+96, 6], fill=c_ball())
# 4: Pace release
d.ellipse([26+128, 16, 30+128, 20], fill=c_ball())
# 5-6: Spin Walk
d.ellipse([12+160, 14, 16+160, 18], fill=c_ball())
d.ellipse([12+192, 6, 16+192, 10], fill=c_ball())
# 7: Spin release
d.ellipse([26+224, 16, 30+224, 20], fill=c_ball())
img_bowl.save('assets/sprites/bowler_atlas.png')


# --- FIELDER (3 frames) ---
img_f = Image.new('RGBA', (96, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_f)
for i in range(3):
    x = i * 32
    d.rectangle([10+x, 10, 22+x, 30], fill=c_body("red"))
    d.ellipse([12+x, 2, 20+x, 10], fill=c_head())

# 0: Idle
# 1: Catch (horizontal dive)
d.rectangle([10+32, 10, 22+32, 30], fill=(0,0,0,0)) # erase body
d.rectangle([4+32, 20, 28+32, 28], fill=c_body("red")) # dive body
# 2: Throw
d.ellipse([24+64, 6, 28+64, 10], fill=c_ball())
img_f.save('assets/sprites/fielder_atlas.png')


# --- UMPIRE (5 frames) ---
img_u = Image.new('RGBA', (160, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_u)
for i in range(5):
    x = i * 32
    d.rectangle([10+x, 10, 22+x, 30], fill=c_ump())
    d.ellipse([12+x, 2, 20+x, 10], fill=c_head())
    
# 0: Idle
# 1: Six (hands up)
d.rectangle([10+32, 0, 12+32, 10], fill=c_ump())
d.rectangle([20+32, 0, 22+32, 10], fill=c_ump())
# 2: Four (arm sweeping)
d.rectangle([22+64, 14, 30+64, 16], fill=c_ump())
# 3: Out (one finger up)
d.rectangle([14+96, 0, 16+96, 10], fill=c_ump())
# 4: Wide (arms out)
d.rectangle([2+128, 14, 10+128, 16], fill=c_ump())
d.rectangle([22+128, 14, 30+128, 16], fill=c_ump())
img_u.save('assets/sprites/umpire_atlas.png')


# --- CROWD (2 frames) ---
img_c = Image.new('RGBA', (64, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_c)
for i in range(2):
    x = i * 32
    d.ellipse([4+x, 20, 12+x, 28], fill=(100,200,100,255))
    d.ellipse([14+x, 18, 22+x, 26], fill=(200,100,200,255))
    d.ellipse([24+x, 22, 32+x, 30], fill=(200,200,100,255))
# 1: Cheer (shifted up)
d.rectangle([0+32, 0, 32+32, 32], fill=(0,0,0,0))
x = 32
d.ellipse([4+x, 16, 12+x, 24], fill=(100,200,100,255))
d.ellipse([14+x, 14, 22+x, 22], fill=(200,100,200,255))
d.ellipse([24+x, 18, 32+x, 26], fill=(200,200,100,255))
img_c.save('assets/sprites/crowd_atlas.png')

print("All sprites generated.")
