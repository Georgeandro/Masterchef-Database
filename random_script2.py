import psycopg2
import random

# Establish a connection to the database
conn = psycopg2.connect(
    dbname="masterchef",
    user="postgres",
    password="postgres",
    host="localhost",
    port="5432"
)
cursor = conn.cursor()

def get_random_recipes(cursor, num_recipes, excluded_recipes):
    national_cuisine_ids = []
    while len(national_cuisine_ids) < num_recipes:
        if excluded_recipes:
            cursor.execute("SELECT id_national FROM recipes WHERE id_rec NOT IN %s ORDER BY RANDOM() LIMIT 1", (tuple(excluded_recipes),))
        else:
            cursor.execute("SELECT id_national FROM recipes ORDER BY RANDOM() LIMIT 1")
        id_national = cursor.fetchone()[0]
        if id_national not in national_cuisine_ids:
            national_cuisine_ids.append(id_national)
    return national_cuisine_ids

def get_chef_for_national(cursor, id_national, excluded_chefs, selected_chefs):
    excluded = tuple(excluded_chefs + selected_chefs)
    if excluded:
        cursor.execute("SELECT id_chef FROM chef_national WHERE id_national = %s AND id_chef NOT IN %s ORDER BY RANDOM() LIMIT 1", (id_national, excluded))
    else:
        cursor.execute("SELECT id_chef FROM chef_national WHERE id_national = %s ORDER BY RANDOM() LIMIT 1", (id_national,))
    return cursor.fetchone()[0]

def get_judges(cursor, num_judges, excluded_chefs):
    cursor.execute("SELECT chef_id FROM chefs WHERE chef_id NOT IN %s ORDER BY RANDOM() LIMIT %s", (tuple(excluded_chefs), num_judges))
    return [row[0] for row in cursor.fetchall()]

def update_appearance_counts(appearance_counts, selected_ids, max_appearances):
    for key in selected_ids:
        if key in appearance_counts:
            appearance_counts[key] += 1
        else:
            appearance_counts[key] = 1
    
    # Remove any items that exceed max_appearances
    return {key: count for key, count in appearance_counts.items() if count < max_appearances}

def populate_episodes(cursor):
    cursor.execute("SELECT no_ep FROM episodes")
    episodes = cursor.fetchall()

    national_appearance_counts = {}
    chef_appearance_counts = {}
    judge_appearance_counts = {}
    recipe_appearance_counts = {}

    for episode in episodes:
        episode_id = episode[0]

        # Step 1: Get 10 distinct national cuisine IDs
        excluded_recipes = [rec_id for rec_id, count in recipe_appearance_counts.items() if count >= 3]
        national_cuisine_ids = get_random_recipes(cursor, 10, excluded_recipes)

        # Step 2: Select one chef for each national cuisine ID, ensuring no duplicates within the episode
        chefs = []
        selected_chefs = []
        for id_national in national_cuisine_ids:
            excluded_chefs = [chef_id for chef_id, count in chef_appearance_counts.items() if count >= 3]
            chef_id = get_chef_for_national(cursor, id_national, excluded_chefs, selected_chefs)
            if chef_id in selected_chefs:
                continue
            chefs.append((chef_id, episode_id, id_national))
            selected_chefs.append(chef_id)

        # Step 3: Select 3 judges (chefs not in the previous list)
        excluded_judges = [chef_id for chef_id, count in judge_appearance_counts.items() if count >= 3] + selected_chefs
        judges = get_judges(cursor, 3, excluded_judges)

        # Update appearance counts
        national_appearance_counts = update_appearance_counts(national_appearance_counts, [id_national for _, _, id_national in chefs], 3)
        chef_appearance_counts = update_appearance_counts(chef_appearance_counts, selected_chefs, 3)
        judge_appearance_counts = update_appearance_counts(judge_appearance_counts, judges, 3)
        recipe_ids = [rec_id for rec_id in excluded_recipes if rec_id in [id_national for _, _, id_national in chefs]]
        recipe_appearance_counts = update_appearance_counts(recipe_appearance_counts, recipe_ids, 3)

        # Insert into chefs_episodes
        for chef_id, episode_id, id_national in chefs:
            cursor.execute(
                "INSERT INTO chefs_episodes (chef_id, chef_no_ep, id_national, rec_id) VALUES (%s, %s, %s, (SELECT id_rec FROM recipes WHERE id_national = %s ORDER BY RANDOM() LIMIT 1))",
                (chef_id, episode_id, id_national, id_national)
            )

        # Insert into judge_episodes
        for judge_id in judges:
            cursor.execute(
                "INSERT INTO judge_episodes (judge_id, judge_no_ep) VALUES (%s, %s)",
                (judge_id, episode_id)
            )

# Populate the tables
populate_episodes(cursor)

# Commit the transaction
conn.commit()

# Close the connection
cursor.close()
conn.close()
