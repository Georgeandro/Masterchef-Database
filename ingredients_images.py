import os
import psycopg2

# Database connection parameters
conn_params = {
    'dbname': 'masterchef',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}

# Directory where images are stored
image_directory = '/home/georgeandro/george_home/semfe/8o/database/ergasia/git_repo_masterchef/ingredients_png'

def upload_images(conn, image_dir):
    cursor = conn.cursor()
    
    # Loop through all files in the image directory
    for filename in os.listdir(image_dir):
        # Assuming filenames are like '1.png', '2.png', etc., corresponding to ing_id
        ing_id, ext = os.path.splitext(filename)
        if ext.lower() == '.png' and ing_id.isdigit():
            ing_id = int(ing_id)
            image_path = os.path.join(image_dir, filename)
            
            # Read the image file
            with open(image_path, 'rb') as file:
                image_data = file.read()
            
            # Update the image column for the corresponding ing_id
            cursor.execute("""
                UPDATE ingredients
                SET image = %s
                WHERE ing_id = %s
            """, (psycopg2.Binary(image_data), ing_id))
    
    conn.commit()
    cursor.close()

if __name__ == '__main__':
    try:
        # Connect to the PostgreSQL database
        conn = psycopg2.connect(**conn_params)
        upload_images(conn, image_directory)
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()
