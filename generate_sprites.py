import os
from PIL import Image, ImageDraw

os.makedirs('assets/sprites', exist_ok=True)

def c_bat(): return (200, 150, 50, 255)
def c_body(team="blue"): return (50, 50, 200, 255) if team == "blue" else (200, 50, 50, 255)
def c_head(): return (255, 200, 150, 255)
def c_ball(): return (255, 0, 0, 255)
def c_ump(): return (20, 20, 20, 255)
def c_wood(): return (210, 180, 140, 255)

# --- BATSMAN (15 frames) ---
img_bat = Image.new('RGBA', (480, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_bat)
for i in range(15):
    x = i * 32
    if i != 13: # Not diving
        d.rectangle([10+x, 10, 22+x, 30], fill=c_body("blue"))
        d.ellipse([12+x, 2, 20+x, 10], fill=c_head())

# 0: Idle
d.rectangle([6, 16, 10, 32], fill=c_bat())
# 1: Front defend
d.polygon([(10+32, 16), (4+32, 8), (8+32, 6), (14+32, 14)], fill=c_bat())
d.rectangle([6+32, 16, 10+32, 32], fill=c_bat())
# 2: Back defend
d.polygon([(12+64, 14), (6+64, 6), (10+64, 4), (16+64, 12)], fill=c_bat())
d.rectangle([10+64, 14, 14+64, 30], fill=c_bat())
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
# 8: Loft swing
d.polygon([(10+256, 12), (0+256, 2), (2+256, 0), (12+256, 10)], fill=c_bat())
# 9: Cut prep
d.polygon([(16+288, 12), (26+288, 6), (28+288, 10), (18+288, 16)], fill=c_bat())
# 10: Cut swing
d.polygon([(10+320, 16), (28+320, 16), (28+320, 20), (10+320, 20)], fill=c_bat())
# 11: Sweep prep (kneeling)
d.rectangle([10+352, 10, 22+352, 30], fill=(0,0,0,0)) # erase body
d.rectangle([10+352, 16, 26+352, 30], fill=c_body("blue")) # kneel
d.polygon([(16+352, 16), (26+352, 8), (28+352, 12), (18+352, 20)], fill=c_bat())
# 12: Sweep swing
d.rectangle([10+384, 10, 22+384, 30], fill=(0,0,0,0))
d.rectangle([10+384, 16, 26+384, 30], fill=c_body("blue"))
d.polygon([(10+384, 22), (28+384, 22), (28+384, 26), (10+384, 26)], fill=c_bat())
# 13: Dive
d.rectangle([2+416, 22, 26+416, 30], fill=c_body("blue"))
d.ellipse([20+416, 20, 28+416, 28], fill=c_head())
d.rectangle([0+416, 24, 10+416, 28], fill=c_bat())
# 14: Out (bat dropped)
d.rectangle([16+448, 30, 28+448, 32], fill=c_bat())
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

# --- FIELDER (5 frames) ---
img_f = Image.new('RGBA', (160, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_f)
for i in range(5):
    x = i * 32
    if i != 1 and i != 4:
        d.rectangle([10+x, 10, 22+x, 30], fill=c_body("red"))
        d.ellipse([12+x, 2, 20+x, 10], fill=c_head())
# 0: Idle
# 1: Catch
d.rectangle([4+32, 20, 28+32, 28], fill=c_body("red"))
d.ellipse([20+32, 18, 28+32, 26], fill=c_head())
# 2: Throw
d.ellipse([24+64, 6, 28+64, 10], fill=c_ball())
# 3: Appeal Howzat
d.rectangle([6+96, 0, 10+96, 10], fill=c_body("red"))
d.rectangle([22+96, 0, 26+96, 10], fill=c_body("red"))
# 4: Direct hit dive
d.rectangle([4+128, 20, 28+128, 28], fill=c_body("red"))
d.ellipse([20+128, 18, 28+128, 26], fill=c_head())
d.ellipse([30+128, 18, 34+128, 22], fill=c_ball())
img_f.save('assets/sprites/fielder_atlas.png')

# --- UMPIRE (9 frames) ---
img_u = Image.new('RGBA', (288, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_u)
for i in range(9):
    x = i * 32
    d.rectangle([10+x, 10, 22+x, 30], fill=c_ump())
    d.ellipse([12+x, 2, 20+x, 10], fill=c_head())
# 0: Idle
# 1: Six
d.rectangle([10+32, 0, 12+32, 10], fill=c_ump())
d.rectangle([20+32, 0, 22+32, 10], fill=c_ump())
# 2: Four
d.rectangle([22+64, 14, 30+64, 16], fill=c_ump())
# 3: Out
d.rectangle([14+96, 0, 16+96, 10], fill=c_ump())
# 4: Wide
d.rectangle([2+128, 14, 10+128, 16], fill=c_ump())
d.rectangle([22+128, 14, 30+128, 16], fill=c_ump())
# 5: No ball
d.rectangle([22+160, 14, 30+160, 16], fill=c_ump())
# 6: Leg Bye
d.rectangle([6+192, 20, 10+192, 26], fill=c_ump())
# 7: Dead ball
d.rectangle([8+224, 12, 24+224, 18], fill=c_ump())
# 8: TV Umpire (drawing square)
d.rectangle([8+256, 0, 24+256, 12], outline=c_head(), width=1)
img_u.save('assets/sprites/umpire_atlas.png')

# --- CROWD (2 frames) ---
img_c = Image.new('RGBA', (64, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_c)
for i in range(2):
    x = i * 32
    y = 20 if i == 0 else 16
    d.ellipse([4+x, y, 12+x, y+8], fill=(100,200,100,255))
    d.ellipse([14+x, y-2, 22+x, y+6], fill=(200,100,200,255))
    d.ellipse([24+x, y+2, 32+x, y+10], fill=(200,200,100,255))
img_c.save('assets/sprites/crowd_atlas.png')

# --- WICKETKEEPER (4 frames) ---
img_wk = Image.new('RGBA', (128, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_wk)
for i in range(4):
    x = i * 32
    if i != 2:
        d.rectangle([10+x, 16, 22+x, 30], fill=c_body("red")) # crouched
        d.ellipse([12+x, 8, 20+x, 16], fill=c_head())
# 0: Stance
d.ellipse([6, 14, 10, 18], fill=(200, 200, 200, 255)) # gloves
# 1: Take
d.ellipse([8+32, 14, 12+32, 18], fill=(200, 200, 200, 255))
d.ellipse([12+32, 14, 16+32, 18], fill=c_ball())
# 2: Dive
d.rectangle([4+64, 20, 28+64, 28], fill=c_body("red"))
d.ellipse([20+64, 18, 28+64, 26], fill=c_head())
# 3: Stump
d.ellipse([4+96, 20, 8+96, 24], fill=(200, 200, 200, 255))
img_wk.save('assets/sprites/keeper_atlas.png')

# --- STUMPS (2 frames) ---
img_s = Image.new('RGBA', (64, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img_s)
for i in range(2):
    x = i * 32
    d.rectangle([12+x, 16, 14+x, 32], fill=c_wood())
    d.rectangle([16+x, 16, 18+x, 32], fill=c_wood())
    d.rectangle([20+x, 16, 22+x, 32], fill=c_wood())
# 0: Idle (bails on)
d.rectangle([11, 14, 23, 16], fill=(150, 100, 50, 255))
# 1: Bails flying
d.rectangle([6+32, 8, 12+32, 10], fill=(150, 100, 50, 255))
d.rectangle([24+32, 6, 30+32, 8], fill=(150, 100, 50, 255))
img_s.save('assets/sprites/stumps_atlas.png')

print("All sprites generated.")
