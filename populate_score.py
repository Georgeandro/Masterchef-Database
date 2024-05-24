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

def get_random_score():
    # Define the scores with the desired probabilities
    scores = [1, 2, 3, 4, 5]
    probabilities = [0.125, 0.25, 0.25, 0.25, 0.125]
    return random.choices(scores, probabilities)[0]

def populate_scores(cursor):
    # Fetch all chefs episodes
    cursor.execute("SELECT chef_id, chef_no_ep FROM chefs_episodes")
    chefs_episodes = cursor.fetchall()

    for chef_id, chef_no_ep in chefs_episodes:
        # Fetch judges for the same episode
        cursor.execute("SELECT judge_id, judge_no_ep FROM judge_episodes WHERE judge_no_ep = %s", (chef_no_ep,))
        judges = cursor.fetchall()

        for judge_id, judge_no_ep in judges:
            score = get_random_score()
            cursor.execute(
                "INSERT INTO score (chef_id, chef_no_ep, judge_id, judge_no_ep, score) VALUES (%s, %s, %s, %s, %s)",
                (chef_id, chef_no_ep, judge_id, judge_no_ep, score)
            )

# Populate the score table
populate_scores(cursor)

# Commit the transaction
conn.commit()

# Close the connection
cursor.close()
conn.close()
