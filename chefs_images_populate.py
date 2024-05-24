import os
import psycopg2
from PIL import Image

# Database connection parameters
db_params = {
    'dbname': 'masterchef',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}

# Directory containing the images
image_dir = '/home/georgeandro/george_home/semfe/8o/database/ergasia/git_repo_masterchef/chef_images'

def get_image_binary(image_path):
    with open(image_path, 'rb') as file:
        return file.read()

def update_chef_images():
    try:
        # Connect to the PostgreSQL database
        conn = psycopg2.connect(**db_params)
        cursor = conn.cursor()

        # Loop through each image in the directory
        for filename in os.listdir(image_dir):
            if filename.endswith('.png'):
                chef_id = int(os.path.splitext(filename)[0])
                image_path = os.path.join(image_dir, filename)
                image_data = get_image_binary(image_path)
                
                # Update the image column for the corresponding chef_id
                cursor.execute("""
                    UPDATE chefs
                    SET image = %s
                    WHERE chef_id = %s
                """, (psycopg2.Binary(image_data), chef_id))
                print(f"Updated image for chef_id {chef_id}")

        # Commit the transaction
        conn.commit()

        # Close the connection
        cursor.close()
        conn.close()

        print("All images updated successfully.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    update_chef_images()
