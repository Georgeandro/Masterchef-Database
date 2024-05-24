import os
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# Database connection parameters
DB_HOST = 'localhost'
DB_NAME = 'masterchef'
DB_USER = 'postgres'
DB_PASSWORD = 'postgres'

# Base directory for CSV files
BASE_DIR = '/home/georgeandro/george_home/semfe/8o/database/ergasia/git_repo_masterchef'

# Define the CSV file paths
CSV_PATHS = {
    'food_groups': os.path.join(BASE_DIR, 'foodgroups.csv'),
    'difficulty': os.path.join(BASE_DIR, 'difficulty.csv'),
    'national_cuisine': os.path.join(BASE_DIR, 'national_cusine.csv'),
    'recipes': os.path.join(BASE_DIR, 'Recipes_final.csv'),
    'meal_type': os.path.join(BASE_DIR, 'meal_type.csv'),
    'meal_type_rec': os.path.join(BASE_DIR, 'Recipe_Meal_Type_Relationships.csv'),
    'tags': os.path.join(BASE_DIR, 'Tags.csv'),
    'tags_rec': os.path.join(BASE_DIR, 'Recipe_Tags_Relationships.csv'),
    'ingredients': os.path.join(BASE_DIR, 'Ingredients_final.csv'),
    'ingredient_recipes': os.path.join(BASE_DIR, 'Relation_Ing_Rec.csv'),
    'equipment': os.path.join(BASE_DIR, 'equipment.csv'),
    'recipes_has_equipment': os.path.join(BASE_DIR, 'equipment_recipe_relation.csv'),
    'steps': os.path.join(BASE_DIR, 'steps.csv'),
    'theme_chapters': os.path.join(BASE_DIR, 'theme_chapters.csv'),
    'recipes_theme': os.path.join(BASE_DIR, 'recipes_theme.csv'),
    'episodes': os.path.join(BASE_DIR, 'episodes.csv'),
    'chefs': os.path.join(BASE_DIR, 'chef.csv'),
    'chef_national': os.path.join(BASE_DIR, 'chefs_has_national.csv')
}

# Function to populate a table from a CSV file
def populate_table(cursor, table_name, csv_file):
    data = pd.read_csv(csv_file)
    columns = ', '.join(data.columns)
    # Convert data to a list of tuples with native Python types
    values = data.to_numpy().tolist()
    insert_query = f'INSERT INTO {table_name} ({columns}) VALUES %s'
    execute_values(cursor, insert_query, values)

def main():
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = conn.cursor()

        # Import data in the specified order
        tables_in_order = [
            ('food_groups', CSV_PATHS['food_groups']),
            ('difficulty', CSV_PATHS['difficulty']),
            ('national_cuisine', CSV_PATHS['national_cuisine']),
            ('recipes', CSV_PATHS['recipes']),
            ('meal_type', CSV_PATHS['meal_type']),
            ('meal_type_rec', CSV_PATHS['meal_type_rec']),
            ('tags', CSV_PATHS['tags']),
            ('tags_rec', CSV_PATHS['tags_rec']),
            ('ingredients', CSV_PATHS['ingredients']),
            ('ingredient_recipes', CSV_PATHS['ingredient_recipes']),
            ('equipment', CSV_PATHS['equipment']),
            ('recipes_has_equipment', CSV_PATHS['recipes_has_equipment']),
            ('steps', CSV_PATHS['steps']),
            ('theme_chapters', CSV_PATHS['theme_chapters']),
            ('recipes_theme', CSV_PATHS['recipes_theme']),
            ('episodes', CSV_PATHS['episodes']),
            ('chefs', CSV_PATHS['chefs']),
            ('chef_national', CSV_PATHS['chef_national'])
        ]

        for table, csv_file in tables_in_order:
            print(f'Populating {table} from {csv_file}...')
            populate_table(cursor, table, csv_file)

        # Commit the transaction
        conn.commit()

    except Exception as e:
        print(f"An error occurred: {e}")
        if conn:
            conn.rollback()

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == '__main__':
    main()
