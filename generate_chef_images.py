import os
import requests
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO

# Ensure the directory exists
output_dir = '/home/georgeandro/george_home/semfe/8o/database/ergasia/git_repo_masterchef/chef_images'
os.makedirs(output_dir, exist_ok=True)

face_url = "https://randomuser.me/api/portraits/"

def download_image(url, save_path):
    response = requests.get(url)
    response.raise_for_status()
    img = Image.open(BytesIO(response.content))
    img = img.convert("RGB")  # Ensure the image is in RGB mode
    img.save(save_path, 'PNG')

# Data for chefs with their sex and age
chefs = [
    (1, 'Kylie', 'female', 49), (2, 'Milty', 'male', 54), (3, 'Drucy', 'female', 49),
    (4, 'Mandel', 'male', 30), (5, 'Ginelle', 'female', 45), (6, 'Rosalind', 'female', 60),
    (7, 'Hailee', 'female', 58), (8, 'Gannon', 'male', 44), (9, 'Jerrome', 'male', 23),
    (10, 'Zandra', 'female', 54), (11, 'Godard', 'male', 44), (12, 'Gerty', 'female', 60),
    (13, 'Willy', 'male', 29), (14, 'Wren', 'female', 51), (15, 'Zulema', 'female', 25),
    (16, 'Lem', 'male', 31), (17, 'Marjie', 'female', 59), (18, 'Dela', 'female', 48),
    (19, 'Kassandra', 'female', 26), (20, 'Ferdinande', 'female', 53), (21, 'Nickolaus', 'male', 39),
    (22, 'Donica', 'female', 46), (23, 'Joyann', 'female', 41), (24, 'Fidela', 'female', 29),
    (25, 'Irene', 'female', 58), (26, 'Guido', 'male', 37), (27, 'Roch', 'male', 40),
    (28, 'Kinnie', 'female', 39), (29, 'Dulcia', 'female', 56), (30, 'Quinton', 'male', 35),
    (31, 'Aubrette', 'female', 38), (32, 'Rodger', 'male', 49), (33, 'Tansy', 'female', 26),
    (34, 'Mae', 'female', 37), (35, 'Andris', 'male', 23), (36, 'Jarib', 'male', 23),
    (37, 'Albertina', 'female', 55), (38, 'Colline', 'female', 38), (39, 'Benny', 'male', 20),
    (40, 'Balduin', 'male', 28), (41, 'Paule', 'female', 32), (42, 'Rozalin', 'female', 28),
    (43, 'Lindi', 'female', 34), (44, 'Angelico', 'male', 37), (45, 'Howard', 'male', 26),
    (46, 'Igor', 'male', 34), (47, 'Benni', 'male', 38), (48, 'Mervin', 'male', 49),
    (49, 'Haleigh', 'female', 57), (50, 'Samuele', 'male', 23)
]

def add_text_to_image(image, text, position):
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()
    draw.text(position, text, fill="white", font=font)

for chef in chefs:
    chef_id, name, sex, age = chef
    gender = 'men' if sex == 'male' else 'women'
    image_id = chef_id % 100  # RandomUser API has 100 images for each gender
    image_url = f"{face_url}/{gender}/{image_id}.jpg"
    save_path = os.path.join(output_dir, f"{chef_id}.png")
    try:
        download_image(image_url, save_path)
        img = Image.open(save_path)
        add_text_to_image(img, f"Name: {name}", (10, 10))
        add_text_to_image(img, f"Sex: {sex}", (10, 30))
        add_text_to_image(img, f"Age: {age}", (10, 50))
        img.save(save_path, 'PNG')
        print(f"Saved image {chef_id}.png with details")
    except Exception as e:
        print(f"Error downloading {image_url}: {e}")

print("Downloaded 50 random faces with details.")
