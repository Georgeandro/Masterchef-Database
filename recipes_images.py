import os
import psycopg2

# Database connection parameters
db_params = {
    'dbname': 'masterchef',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}

# Directory containing images
image_directory = '/home/georgeandro/george_home/semfe/8o/database/ergasia/git_repo_masterchef/recipes_png'

# Establishing the connection
conn = psycopg2.connect(**db_params)
cursor = conn.cursor()

# Function to read image file and return binary data
def read_image(file_path):
    with open(file_path, 'rb') as file:
        return file.read()

# Inserting images into the database
try:
    for filename in os.listdir(image_directory):
        if filename.endswith('.png'):  # Adjust file extension as needed
            file_path = os.path.join(image_directory, filename)
            binary_data = read_image(file_path)
            
            # Extract recipe ID from filename (assuming filename is like '1.png')
            recipe_id = int(os.path.splitext(filename)[0])
            
            # Update query for recipes table
            cursor.execute("""
                UPDATE recipes
                SET image = %s
                WHERE id_rec = %s
            """, (binary_data, recipe_id))
    
    # Commit the transaction
    conn.commit()
except Exception as e:
    print(f"Error: {e}")
    conn.rollback()
finally:
    cursor.close()
    conn.close()
