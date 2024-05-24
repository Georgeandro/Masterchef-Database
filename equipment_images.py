import os
import psycopg2

# Database connection parameters
DB_HOST = 'localhost'
DB_NAME = 'masterchef'
DB_USER = 'postgres'
DB_PASSWORD = 'postgres'

# Directory containing the image files
IMAGE_DIR = '/home/georgeandro/george_home/semfe/8o/database/ergasia/git_repo_masterchef/equipment_images'

def upload_images():
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = conn.cursor()

        # Iterate through the files in the directory
        for filename in os.listdir(IMAGE_DIR):
            if filename.endswith('.png'):
                # Extract equipment ID from the filename (assuming filename is eq_id.png)
                eq_id = int(filename.split('.')[0])

                # Read the image file
                with open(os.path.join(IMAGE_DIR, filename), 'rb') as file:
                    image_data = file.read()

                # Update the database
                cursor.execute(
                    """
                    UPDATE equipment
                    SET image = %s
                    WHERE eq_id = %s
                    """,
                    (psycopg2.Binary(image_data), eq_id)
                )

        # Commit the transaction
        conn.commit()

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == '__main__':
    upload_images()
