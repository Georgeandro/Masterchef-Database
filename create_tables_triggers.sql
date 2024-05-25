-- Create food_groups table
CREATE TABLE food_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL
);

-- Create difficulty table
CREATE TABLE difficulty (
    id_diff SERIAL PRIMARY KEY,
    description TEXT NOT NULL
);

-- Create national_cuisine table
CREATE TABLE national_cuisine (
    id_national SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Create recipes table
CREATE TABLE recipes (
    id_rec SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    tips TEXT NOT NULL,
    preparation_time INT NOT NULL CHECK(preparation_time > 0),
    execution_time INT NOT NULL CHECK(execution_time > 0),
    portions INT NOT NULL CHECK(portions > 0),
    fat FLOAT NOT NULL CHECK(fat >= 0),
    kcal FLOAT NOT NULL CHECK(kcal >= 0),
    protein FLOAT NOT NULL CHECK(protein >= 0),
    carbs FLOAT NOT NULL CHECK(carbs >= 0),
    id_food_group INTEGER REFERENCES food_groups(id),
    id_diff INTEGER REFERENCES difficulty(id_diff),
    id_national INTEGER REFERENCES national_cuisine(id_national)
);

-- Create meal_type table
CREATE TABLE meal_type (
        id_meal_type INTEGER primary KEY,
    type_name VARCHAR(50) NOT NULL
);

-- Create meal_type_rec table
CREATE TABLE meal_type_rec (
    id_rec INTEGER REFERENCES recipes(id_rec) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_type INTEGER REFERENCES meal_type(id_meal_type) ON DELETE RESTRICT,
    PRIMARY KEY (id_rec, id_type)
);

-- Create tags table
CREATE TABLE tags (
    id_tags SERIAL PRIMARY key,
    name VARCHAR(50)
);

-- Create tags_rec table
CREATE TABLE tags_rec (
    id_tags INTEGER REFERENCES tags(id_tags),
    id_rec INTEGER REFERENCES recipes(id_rec),
    PRIMARY KEY (id_tags, id_rec)
);

-- Create ingredients table
CREATE TABLE ingredients (
    ing_id SERIAL PRIMARY KEY,
    ing_name VARCHAR(50) NOT NULL,
    kcal FLOAT NOT NULL CHECK(kcal >= 0),
    fat FLOAT NOT NULL CHECK(fat >= 0),
    protein FLOAT NOT NULL CHECK(protein >= 0),
    carbs FLOAT NOT NULL CHECK(carbs >= 0),
    food_groups_id INTEGER REFERENCES food_groups(id)
);

-- Create ingredient_recipes table
CREATE TABLE ingredient_recipes (
    id_ing INTEGER REFERENCES ingredients(ing_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_rec INTEGER REFERENCES recipes(id_rec) ON DELETE RESTRICT ON UPDATE CASCADE,
    quantity TEXT NOT NULL,
    basic VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_ing, id_rec)
);

-- Create equipment table
CREATE TABLE equipment (
    eq_id SERIAL PRIMARY KEY,
    eq_name VARCHAR(50) NOT NULL,
    instructions TEXT NOT NULL
);

CREATE TABLE recipes_has_equipment (
    recipes_id INTEGER REFERENCES recipes(id_rec),
    equipment_id INTEGER REFERENCES equipment(eq_id),
    PRIMARY KEY (recipes_id, equipment_id)
);


-- Create steps table
CREATE TABLE steps (
    steps_id SERIAL PRIMARY KEY,
    description TEXT NOT null,
    recipe_id INTEGER references recipes(id_rec),
    order_no INTEGER
);




-- Create theme_chapters table
CREATE TABLE theme_chapters (
    theme_chapters_id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    description TEXT
);

-- Create recipes_theme table
CREATE TABLE recipes_theme ( 
    id_rec INTEGER REFERENCES recipes(id_rec) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_theme INTEGER REFERENCES theme_chapters(theme_chapters_id) ON DELETE RESTRICT,
    PRIMARY KEY (id_rec, id_theme)
);

-- Create episodes table
CREATE TABLE episodes (
    no_ep SERIAL PRIMARY KEY
);

-- Create chefs table
CREATE TABLE chefs (
    chef_id SERIAL PRIMARY KEY,
    chef_name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    phone VARCHAR(10) NOT NULL CHECK(LENGTH(phone) = 10),
    birth DATE NOT NULL,
    chef_age INT NOT NULL CHECK(chef_age > 0),
    experience INT NOT NULL CHECK(experience > 0),
    characterize TEXT NOT NULL,
    pas VARCHAR(50) not null 
    CHECK(chef_age = (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birth)) 
        OR chef_age = (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birth)) - 1)
);


-- Create chefs_episodes table
CREATE TABLE chefs_episodes (
    chef_id INTEGER REFERENCES chefs(chef_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    chef_no_ep INTEGER REFERENCES episodes(no_ep) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_national INTEGER REFERENCES national_cuisine(id_national) ON DELETE RESTRICT,
    rec_id INTEGER REFERENCES recipes(id_rec) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (chef_id, chef_no_ep)
);

-- Create judge_episodes table
CREATE TABLE judge_episodes (
    judge_id INTEGER REFERENCES chefs(chef_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    judge_no_ep INTEGER REFERENCES episodes(no_ep) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (judge_id, judge_no_ep)
);

-- Create score table
CREATE TABLE score (
    chef_id INTEGER,
    chef_no_ep INTEGER,
    judge_id INTEGER,
    judge_no_ep INTEGER,
    score INTEGER,
    PRIMARY KEY (chef_id, chef_no_ep, judge_id, judge_no_ep),
    FOREIGN KEY (chef_id, chef_no_ep) REFERENCES chefs_episodes(chef_id, chef_no_ep) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (judge_id, judge_no_ep) REFERENCES judge_episodes(judge_id, judge_no_ep) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Create chef_national table
CREATE TABLE chef_national (
    id_chef INTEGER REFERENCES chefs(chef_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_national INTEGER REFERENCES national_cuisine(id_national) ON DELETE RESTRICT,
    PRIMARY KEY (id_chef, id_national)
);




CREATE OR REPLACE FUNCTION convert_quantity_to_factor(quantity_text TEXT) RETURNS FLOAT AS $$
DECLARE
    numeric_part FLOAT;
    unit_part TEXT;
BEGIN
    -- Extract numeric part from the quantity text
    numeric_part := substring(quantity_text from '^[0-9]+')::FLOAT;

    -- Determine the unit (assuming only 'g' or 'ml' are used)
    unit_part := substring(quantity_text from '[a-zA-Z]+$');

    -- Convert based on unit
    IF unit_part = 'g' THEN
        RETURN numeric_part / 100.0;
    ELSIF unit_part = 'ml' THEN
        RETURN numeric_part / 100.0;
    ELSE
        -- Default case to handle unexpected unit
        RETURN NULL; 
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recipes_nutrition_insert_trigger() RETURNS TRIGGER AS $$
DECLARE
    total_kcal FLOAT := 0;
    total_fat FLOAT := 0;
    total_protein FLOAT := 0;
    total_carbs FLOAT := 0;
    quantity_factor FLOAT;
    rec RECORD;
BEGIN
    -- Calculate total nutritional values
    FOR rec IN (
        SELECT i.ing_id, i.kcal, i.fat, i.protein, i.carbs, ir.quantity
        FROM ingredients i
        JOIN ingredient_recipes ir ON i.ing_id = ir.id_ing
        WHERE ir.id_rec = NEW.id_rec
    ) LOOP
	quantity_factor := convert_quantity_to_factor(rec.quantity);

        -- Debugging output
        RAISE NOTICE 'Ingredient: %, Quantity: %, Factor: %', rec.ing_id, rec.quantity, quantity_factor;

        -- Ensure the quantity factor is not null
        IF quantity_factor IS NOT NULL THEN
            total_kcal := total_kcal + (rec.kcal * quantity_factor);
            total_fat := total_fat + (rec.fat * quantity_factor);
            total_protein := total_protein + (rec.protein * quantity_factor);
            total_carbs := total_carbs + (rec.carbs * quantity_factor);
        ELSE
            RAISE NOTICE 'Skipping ingredient % due to null quantity factor', rec.ing_id;
        END IF;
    END LOOP;

    -- Update the recipe row with calculated totals
    UPDATE recipes
    SET kcal = total_kcal,
        fat = total_fat,
        protein = total_protein,
        carbs = total_carbs
    WHERE id_rec = NEW.id_rec;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE role admin with password 'your_admin_password';  

GRANT ALL PRIVILEGES ON DATABASE test TO admin;



CREATE ROLE chef_user;


CREATE OR REPLACE FUNCTION create_chef_user()
RETURNS TRIGGER AS $$
BEGIN

    -- Create a new role with the chef_id as both the username and password

    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', NEW.chef_id, NEW.pas);
  
    -- Grant INSERT and UPDATE privileges on the recipes table to the new role

    EXECUTE format('GRANT INSERT, UPDATE ON TABLE recipes TO %I', NEW.chef_id);

    

    -- Grant INSERT and UPDATE privileges on the chefs table to the new role

    EXECUTE format('GRANT INSERT, UPDATE ON TABLE chefs TO %I', NEW.chef_id);

    

    RETURN NEW;

END;

$$ LANGUAGE plpgsql;



CREATE TRIGGER after_chef_insert
AFTER INSERT ON chefs
FOR EACH ROW
EXECUTE FUNCTION create_chef_user();

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_recipe_nutrition ON ingredient_recipes;

-- Create the trigger to call the function after insert or update
CREATE TRIGGER update_recipe_nutrition
AFTER INSERT OR UPDATE ON ingredient_recipes
FOR EACH ROW 
EXECUTE FUNCTION recipes_nutrition_insert_trigger();



--views
-- Create view for each recipe and its ingredients in a list
CREATE VIEW recipe_ingredients AS
SELECT 
    r.name AS recipe_name,
    array_agg(i.ing_name) AS ingredients
FROM 
    recipes r
JOIN 
    ingredient_recipes ir ON r.id_rec = ir.id_rec
JOIN 
    ingredients i ON ir.id_ing = i.ing_id
GROUP BY 
    r.name;
   
   
-- Create view for the total points per season per chef
CREATE VIEW chef_total_points_per_season AS
WITH season_episodes AS (
    SELECT 1 AS season, 1 AS start_ep, 10 AS end_ep UNION ALL
    SELECT 2 AS season, 11 AS start_ep, 20 AS end_ep UNION ALL
    SELECT 3 AS season, 21 AS start_ep, 30 AS end_ep UNION ALL
    SELECT 4 AS season, 31 AS start_ep, 40 AS end_ep UNION ALL
    SELECT 5 AS season, 41 AS start_ep, 50 AS end_ep
),
season_scores AS (
    SELECT 
        s.chef_id,
        se.season,
        SUM(s.score) AS total_score
    FROM 
        score s
    JOIN 
        chefs_episodes ce ON s.chef_id = ce.chef_id AND s.chef_no_ep = ce.chef_no_ep
    JOIN 
        season_episodes se ON s.chef_no_ep BETWEEN se.start_ep AND se.end_ep
    GROUP BY 
        s.chef_id, se.season
)
SELECT 
    c.chef_id,
    c.chef_name,
    c.surname,
    ss.season,
    ss.total_score
FROM 
    chefs c
JOIN 
    season_scores ss ON c.chef_id = ss.chef_id
order by season,total_score;

--Indexes
--tags_rec index
CREATE INDEX idx_tags_rec_id_rec ON tags_rec ( id_rec );
CREATE INDEX idx_tags_rec_id_tags ON tags_rec ( id_tags );
--chef_episode index
CREATE INDEX idx_chefs_episodes_no_ep ON chefs_episodes ( chef_no_ep );
--recipes_equipment index
CREATE INDEX idx_recipes_has_equipment_recipes_id ON recipes_has_equipment ( recipes_id );
--ingredient index to search fast by name
CREATE INDEX idx_ingredients_name ON ingredients (ing_name);
--index in score because there are 1500 tuples
CREATE INDEX idx_score_chef_id ON score (chef_id);
CREATE INDEX idx_score_chef_no_ep ON score (chef_no_ep);
CREATE INDEX idx_score_judge_id ON score (judge_id);
CREATE INDEX idx_score_judge_no_ep ON score (judge_no_ep);

