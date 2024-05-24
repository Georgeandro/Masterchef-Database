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

    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', NEW.chef_id, NEW.chef_password);
  
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

-- Check triggers on the ingredient_recipes table
SELECT * from recipes;


--3.1

SELECT 
    nc.name AS cuisine_type,
    c.chef_name,
    c.surname,
    AVG(s.score) AS average_score
FROM 
    score s
JOIN 
    chefs_episodes ce ON s.chef_id = ce.chef_id AND s.chef_no_ep = ce.chef_no_ep
JOIN 
    national_cuisine nc ON ce.id_national = nc.id_national
JOIN 
    chefs c ON s.chef_id = c.chef_id
GROUP BY 
    nc.name, c.chef_name, c.surname
ORDER BY 
    c.chef_name, c.surname;


--3.2
WITH EpisodeRanges AS (
    SELECT 1 AS year, 1 AS start_ep, 10 AS end_ep UNION ALL
    SELECT 2 AS year, 11 AS start_ep, 20 AS end_ep UNION ALL
    SELECT 3 AS year, 21 AS start_ep, 30 AS end_ep UNION ALL
    SELECT 4 AS year, 31 AS start_ep, 40 AS end_ep UNION ALL
    SELECT 5 AS year, 41 AS start_ep, 50 AS end_ep
)
SELECT 
    chefs.chef_name, 
    chefs.surname, 
    national_cuisine.name AS national_cuisine, 
    er.year,
    CASE 
        WHEN ce.chef_id IS NOT NULL THEN 'Participated'
        ELSE 'Not Participated'
    END AS participation_status
FROM 
    chefs
JOIN 
    chef_national ON chefs.chef_id = chef_national.id_chef
JOIN 
    national_cuisine ON chef_national.id_national = national_cuisine.id_national
LEFT JOIN 
    chefs_episodes ce ON chefs.chef_id = ce.chef_id
LEFT JOIN 
    episodes e ON ce.chef_no_ep = e.no_ep
JOIN 
    EpisodeRanges er ON e.no_ep BETWEEN er.start_ep AND er.end_ep
WHERE 
    national_cuisine.name LIKE '%United States%'
    AND er.year = 2
   ORDER BY   chefs.surname;



--3.3
SELECT 
    chef_name, 
    surname, 
    chef_age,
    recipe_count
FROM (
    SELECT 
	c.chef_name,
        c.surname,
        c.chef_age,
        (SELECT COUNT(*) 
         FROM chefs_episodes ce
         WHERE ce.chef_id = c.chef_id AND ce.rec_id IN (
             SELECT r.id_rec 
             FROM recipes r 
             WHERE r.id_rec = ce.rec_id)) AS recipe_count
    FROM 
	chefs c
    WHERE 
	c.chef_age < 30
) AS chef_recipes
ORDER BY 
    recipe_count DESC;



--3.4)
SELECT 
    chef_name, 
    surname
FROM 
    chefs
WHERE 
    chef_id NOT IN (
        SELECT judge_id 
        FROM judge_episodes
    );


--3.5   
WITH JudgeAppearances AS (
    SELECT 
        je.judge_id,
        c.chef_name, 
        c.surname,
        CASE
            WHEN je.judge_no_ep BETWEEN 1 AND 10 THEN 1
            WHEN je.judge_no_ep BETWEEN 11 AND 20 THEN 2
            WHEN je.judge_no_ep BETWEEN 21 AND 30 THEN 3
            WHEN je.judge_no_ep BETWEEN 31 AND 40 THEN 4
            WHEN je.judge_no_ep BETWEEN 41 AND 50 THEN 5
        END AS year,
        COUNT(je.judge_no_ep) AS appearances
    FROM 
	judge_episodes je
    JOIN 
	chefs c ON je.judge_id = c.chef_id
    WHERE 
	je.judge_no_ep BETWEEN 1 AND 50
    GROUP BY 
	je.judge_id, c.chef_name, c.surname, year
    HAVING 
        COUNT(je.judge_no_ep) > 3
)
SELECT 
    chef_name, 
    surname, 
    appearances, 
    year
FROM 
    JudgeAppearances
GROUP BY 
    appearances, year, chef_name, surname
order by
    appearances DESC, year;

  --for checking 3.5
SELECT 
    c.chef_name, 
    c.surname,
    CASE
        WHEN je.judge_no_ep BETWEEN 1 AND 10 THEN 1
        WHEN je.judge_no_ep BETWEEN 11 AND 20 THEN 2
        WHEN je.judge_no_ep BETWEEN 21 AND 30 THEN 3
        WHEN je.judge_no_ep BETWEEN 31 AND 40 THEN 4
        WHEN je.judge_no_ep BETWEEN 41 AND 50 THEN 5
    END AS season,
    COUNT(je.judge_no_ep) AS appearances
FROM 
    judge_episodes je
JOIN 
    chefs c ON je.judge_id = c.chef_id
WHERE 
    je.judge_no_ep BETWEEN 1 AND 50
GROUP BY 
    c.chef_name, c.surname, season
ORDER BY 
    appearances DESC;

   
--create the index for 3.6)
CREATE INDEX idx_tags_rec_id_rec ON tags_rec (id_rec);
CREATE INDEX idx_tags_rec_id_tags ON tags_rec (id_tags);

--drop indexes for 3.6)
DROP INDEX IF EXISTS idx_tags_rec_id_rec;
DROP INDEX IF EXISTS idx_tags_rec_id_tags;


-- query for 3.6)
EXPLAIN ANALYZE
WITH RecipeTags AS (
    SELECT 
        tr1.id_rec,
        t1.name AS tag1,
        t2.name AS tag2
    FROM 
        tags_rec tr1
    JOIN 
        tags t1 ON tr1.id_tags = t1.id_tags
    JOIN 
        tags_rec tr2 ON tr1.id_rec = tr2.id_rec
    JOIN 
        tags t2 ON tr2.id_tags = t2.id_tags
    WHERE 
        t1.id_tags < t2.id_tags
),
TagPairsCount AS (
    SELECT 
        rt.tag1,
        rt.tag2,
        COUNT(*) AS pair_count
    FROM 
        RecipeTags rt
    GROUP BY 
        rt.tag1, rt.tag2
)
SELECT 
    tpc.tag1,
    tpc.tag2,
    tpc.pair_count
FROM 
    TagPairsCount tpc
ORDER BY 
    tpc.pair_count DESC
LIMIT 3;

--3.7 show all chefs and appearances
WITH ChefAppearances AS (
    SELECT 
        c.chef_id,
        c.chef_name,
        c.surname,
        COUNT(DISTINCT ce.chef_no_ep) AS chef_appearances,
        COUNT(DISTINCT je.judge_no_ep) AS judge_appearances
    FROM 
        chefs c
    LEFT JOIN 
        chefs_episodes ce ON c.chef_id = ce.chef_id
    LEFT JOIN 
        judge_episodes je ON c.chef_id = je.judge_id
    GROUP BY 
        c.chef_id, c.chef_name, c.surname
),
TotalAppearances AS (
    SELECT 
        ca.chef_id,
        ca.chef_name,
        ca.surname,
        ca.chef_appearances,
        ca.judge_appearances,
        ca.chef_appearances + ca.judge_appearances AS total_appearances
    FROM 
        ChefAppearances ca
)
SELECT 
    ta.chef_name, 
    ta.surname, 
    ta.chef_appearances,
    ta.judge_appearances,
    ta.total_appearances
FROM 
    TotalAppearances ta
ORDER BY 
    ta.total_appearances DESC;

--3.7)toulaxiston 5 ligoteres
WITH ChefAppearances AS (
    SELECT 
        c.chef_id,
        c.chef_name,
        c.surname,
        COUNT(DISTINCT ce.chef_no_ep) AS chef_appearances,
        COUNT(DISTINCT je.judge_no_ep) AS judge_appearances
    FROM 
        chefs c
    LEFT JOIN 
        chefs_episodes ce ON c.chef_id = ce.chef_id
    LEFT JOIN 
        judge_episodes je ON c.chef_id = je.judge_id
    GROUP BY 
        c.chef_id, c.chef_name, c.surname
),
TotalAppearances AS (
    SELECT 
        ca.chef_id,
        ca.chef_name,
        ca.surname,
        ca.chef_appearances,
        ca.judge_appearances,
        ca.chef_appearances + ca.judge_appearances AS total_appearances
    FROM 
        ChefAppearances ca
),
MaxAppearances AS (
    SELECT 
        MAX(total_appearances) AS max_appearances
    FROM 
        TotalAppearances
)
SELECT 
    ta.chef_name, 
    ta.surname, 
    ta.chef_appearances,
    ta.judge_appearances,
    ta.total_appearances
FROM 
    TotalAppearances ta,
    MaxAppearances ma
WHERE 
    ta.total_appearances <= ma.max_appearances - 5
ORDER BY 
    ta.total_appearances DESC;

   
   
--3.8)s
--dimiourgoume indexes
CREATE INDEX idx_chefs_episodes_no_ep ON chefs_episodes (chef_no_ep);
CREATE INDEX idx_recipes_id_rec ON recipes (id_rec);
CREATE INDEX idx_recipes_has_equipment_recipes_id ON recipes_has_equipment (recipes_id);
--drop indexes
DROP INDEX IF EXISTS idx_chefs_episodes_no_ep;
DROP INDEX IF EXISTS idx_recipes_id_rec;
DROP INDEX IF EXISTS idx_recipes_has_equipment_recipes_id;

--3.8 query
EXPLAIN ANALYZE
SELECT 
    e.no_ep,
    COUNT(re.equipment_id) AS equipment_count
FROM 
    episodes e
JOIN 
    chefs_episodes ce ON e.no_ep = ce.chef_no_ep
JOIN 
    recipes r ON ce.rec_id = r.id_rec
JOIN 
    recipes_has_equipment re ON r.id_rec = re.recipes_id
GROUP BY 
    e.no_ep
ORDER BY 
    equipment_count DESC
LIMIT 1;

--all episodes and all equipment used
SELECT 
    e.no_ep,
    COUNT(re.equipment_id) AS equipment_count
FROM 
    episodes e
JOIN 
    chefs_episodes ce ON e.no_ep = ce.chef_no_ep
JOIN 
    recipes r ON ce.rec_id = r.id_rec
JOIN 
    recipes_has_equipment re ON r.id_rec = re.recipes_id
GROUP BY 
    e.no_ep
ORDER BY 
    equipment_count DESC;

--3.9
WITH EpisodeYears AS (
    SELECT 
        no_ep,
        CASE
            WHEN no_ep BETWEEN 1 AND 10 THEN 1
            WHEN no_ep BETWEEN 11 AND 20 THEN 2
            WHEN no_ep BETWEEN 21 AND 30 THEN 3
            WHEN no_ep BETWEEN 31 AND 40 THEN 4
            WHEN no_ep BETWEEN 41 AND 50 THEN 5
            ELSE NULL
        END AS year
    FROM 
        episodes
),
CarbsPerEpisode AS (
    SELECT 
        e.year,
        r.id_rec,
        r.carbs
    FROM 
        EpisodeYears e
    JOIN 
        chefs_episodes ce ON e.no_ep = ce.chef_no_ep
    JOIN 
        recipes r ON ce.rec_id = r.id_rec
)
SELECT 
    year,
    AVG(carbs) AS avg_carbs
FROM 
    CarbsPerEpisode
GROUP BY 
    year
ORDER BY 
    year;
   
--3.10)
   --same cusine 2 year span
WITH EpisodeYears AS (
    SELECT 
        no_ep,
        CASE
            WHEN no_ep BETWEEN 1 AND 10 THEN 1
            WHEN no_ep BETWEEN 11 AND 20 THEN 2
            WHEN no_ep BETWEEN 21 AND 30 THEN 3
            WHEN no_ep BETWEEN 31 AND 40 THEN 4
            WHEN no_ep BETWEEN 41 AND 50 THEN 5
            ELSE NULL
        END AS year
    FROM 
        episodes
),
CuisineAppearances AS (
    SELECT 
        nc.name AS cuisine,
        ey.year,
        COUNT(*) AS appearances
    FROM 
        national_cuisine nc
    JOIN 
        chefs_episodes ce ON nc.id_national = ce.id_national
    JOIN 
        EpisodeYears ey ON ce.chef_no_ep = ey.no_ep
    GROUP BY 
        nc.name, ey.year
    HAVING 
        COUNT(*) >= 3
),
CuisineAppearancesConsecutiveYears AS (
    SELECT 
        c1.cuisine,
        c1.year AS year1,
        c2.year AS year2,
        c1.appearances AS appearances1,
        c2.appearances AS appearances2
    FROM 
        CuisineAppearances c1
    JOIN 
        CuisineAppearances c2 ON c1.cuisine = c2.cuisine AND c1.year = c2.year - 1
    WHERE 
        c1.appearances = c2.appearances
)
SELECT 
    cuisine,
    year1,
    year2,
    appearances1 AS appearances
FROM 
    CuisineAppearancesConsecutiveYears
ORDER BY 
    cuisine, year1;

--any cuisine 2 year span
   WITH EpisodeBlocks AS (
    SELECT 
        no_ep,
        CEIL(no_ep / 20.0) AS block
    FROM 
        episodes
),
CuisineAppearances AS (
    SELECT 
        nc.name AS cuisine,
        eb.block,
        COUNT(*) AS appearances
    FROM 
        national_cuisine nc
    JOIN 
        chefs_episodes ce ON nc.id_national = ce.id_national
    JOIN 
        EpisodeBlocks eb ON ce.chef_no_ep = eb.no_ep
    GROUP BY 
        nc.name, eb.block
    HAVING 
        COUNT(*) >= 3
),
CuisinePairAppearances AS (
    SELECT 
        ca1.cuisine AS cuisine1,
        ca2.cuisine AS cuisine2,
        ca1.block,
        ca1.appearances
    FROM 
        CuisineAppearances ca1
    JOIN 
        CuisineAppearances ca2 ON ca1.block = ca2.block AND ca1.appearances = ca2.appearances AND ca1.cuisine < ca2.cuisine
)
SELECT 
    cuisine1,
    cuisine2,
    block,
    appearances
FROM 
    CuisinePairAppearances
ORDER BY 
    block, appearances DESC;

--3.11)
WITH JudgeScores AS (
    SELECT 
        s.judge_id,
        s.chef_id,
        SUM(s.score) AS total_score
    FROM 
        score s
    GROUP BY 
        s.judge_id, s.chef_id
),
JudgeChefNames AS (
    SELECT 
        js.judge_id,
        js.chef_id,
        js.total_score,
        j.chef_name AS judge_name,
        c.chef_name AS chef_name
    FROM 
        JudgeScores js
    JOIN 
        chefs j ON js.judge_id = j.chef_id
    JOIN 
        chefs c ON js.chef_id = c.chef_id
)
SELECT 
    judge_name,
    chef_name,
    total_score
FROM 
    JudgeChefNames
ORDER BY 
    total_score DESC
LIMIT 5;

--3.12)

WITH EpisodeYears AS (
    SELECT 
        no_ep,
        CASE
            WHEN no_ep BETWEEN 1 AND 10 THEN 1
            WHEN no_ep BETWEEN 11 AND 20 THEN 2
            WHEN no_ep BETWEEN 21 AND 30 THEN 3
            WHEN no_ep BETWEEN 31 AND 40 THEN 4
            WHEN no_ep BETWEEN 41 AND 50 THEN 5
        END AS year
    FROM 
        episodes
),
EpisodeDifficulty AS (
    SELECT 
        ey.year,
        e.no_ep,
        AVG(d.id_diff) AS avg_difficulty
    FROM 
        EpisodeYears ey
    JOIN 
        chefs_episodes ce ON ey.no_ep = ce.chef_no_ep
    JOIN 
        recipes r ON ce.rec_id = r.id_rec
    JOIN 
        difficulty d ON r.id_diff = d.id_diff
    JOIN 
        episodes e ON ey.no_ep = e.no_ep
    GROUP BY 
        ey.year, e.no_ep
),
MaxDifficultyPerYear AS (
    SELECT 
        year,
        MAX(avg_difficulty) AS max_difficulty
    FROM 
        EpisodeDifficulty
    GROUP BY 
        year
)
SELECT 
    ed.year,
    ed.no_ep,
    ed.avg_difficulty
FROM 
    EpisodeDifficulty ed
JOIN 
    MaxDifficultyPerYear md ON ed.year = md.year AND ed.avg_difficulty = md.max_difficulty
ORDER BY 
    ed.year;

--3.13)
--for years of experience
WITH EpisodeYears AS (
    SELECT 
        no_ep,
        CASE
            WHEN no_ep BETWEEN 1 AND 10 THEN 1
            WHEN no_ep BETWEEN 11 AND 20 THEN 2
            WHEN no_ep BETWEEN 21 AND 30 THEN 3
            WHEN no_ep BETWEEN 31 AND 40 THEN 4
            WHEN no_ep BETWEEN 41 AND 50 THEN 5
        END AS year
    FROM 
        episodes
),
ChefExperience AS (
    SELECT 
        ce.chef_no_ep AS no_ep,
        AVG(c.experience) AS avg_chef_experience
    FROM 
        chefs_episodes ce
    JOIN 
        chefs c ON ce.chef_id = c.chef_id
    GROUP BY 
        ce.chef_no_ep
),
JudgeExperience AS (
    SELECT 
        je.judge_no_ep AS no_ep,
        AVG(c.experience) AS avg_judge_experience
    FROM 
        judge_episodes je
    JOIN 
        chefs c ON je.judge_id = c.chef_id
    GROUP BY 
        je.judge_no_ep
),
EpisodeExperience AS (
    SELECT 
        e.no_ep,
        COALESCE(ce.avg_chef_experience, 0) AS avg_chef_experience,
        COALESCE(je.avg_judge_experience, 0) AS avg_judge_experience,
        (COALESCE(ce.avg_chef_experience, 0) + COALESCE(je.avg_judge_experience, 0)) / 2 AS avg_total_experience
    FROM 
        episodes e
    LEFT JOIN 
        ChefExperience ce ON e.no_ep = ce.no_ep
    LEFT JOIN 
        JudgeExperience je ON e.no_ep = je.no_ep
)
SELECT 
    ee.no_ep,
    ee.avg_total_experience
FROM 
    EpisodeExperience ee
ORDER BY 
    ee.avg_total_experience ASC
LIMIT 1;

--for expertize characterization
WITH CharacterizeLevels AS (
    SELECT 
        chef_id,
        CASE characterize
            WHEN 'C chef' THEN 1
            WHEN 'B chef' THEN 2
            WHEN 'A chef' THEN 3
            WHEN 'sous chef' THEN 4
            WHEN 'head chef' THEN 5
            ELSE 0
        END AS experience_level
    FROM 
        chefs
),
ChefExperience AS (
    SELECT 
        ce.chef_no_ep AS no_ep,
        AVG(cl.experience_level) AS avg_chef_experience
    FROM 
        chefs_episodes ce
    JOIN 
        CharacterizeLevels cl ON ce.chef_id = cl.chef_id
    GROUP BY 
        ce.chef_no_ep
),
JudgeExperience AS (
    SELECT 
        je.judge_no_ep AS no_ep,
        AVG(cl.experience_level) AS avg_judge_experience
    FROM 
        judge_episodes je
    JOIN 
        CharacterizeLevels cl ON je.judge_id = cl.chef_id
    GROUP BY 
        je.judge_no_ep
),
EpisodeExperience AS (
    SELECT 
        e.no_ep,
        COALESCE(ce.avg_chef_experience, 0) AS avg_chef_experience,
        COALESCE(je.avg_judge_experience, 0) AS avg_judge_experience,
        (COALESCE(ce.avg_chef_experience, 0) + COALESCE(je.avg_judge_experience, 0)) / 2 AS avg_total_experience
    FROM 
        episodes e
    LEFT JOIN 
        ChefExperience ce ON e.no_ep = ce.no_ep
    LEFT JOIN 
        JudgeExperience je ON e.no_ep = je.no_ep
)
SELECT 
    ee.no_ep,
    ee.avg_total_experience
FROM 
    EpisodeExperience ee
ORDER BY 
    ee.avg_total_experience ASC
LIMIT 1;

--3.14) theme chapter with most appearances in the competition
SELECT 
    tc.name AS theme_name,
    COUNT(rt.id_theme) AS appearance_count
FROM 
    recipes_theme rt
JOIN 
    theme_chapters tc ON rt.id_theme = tc.theme_chapters_id
GROUP BY 
    tc.name
ORDER BY 
    appearance_count DESC
LIMIT 1;


--3.15)
WITH FoodGroupsInCompetition AS (
    SELECT DISTINCT
        fg.id,
        fg.name
    FROM 
        food_groups fg
    JOIN 
        recipes r ON fg.id = r.id_food_group
    JOIN 
        chefs_episodes ce ON r.id_rec = ce.rec_id
)
SELECT 
    fg.id,
    fg.name
FROM 
    food_groups fg
LEFT JOIN 
    FoodGroupsInCompetition fgc ON fg.id = fgc.id
WHERE 
    fgc.id IS NULL;

ALTER TABLE recipes ADD COLUMN image BYTEA;

ALTER TABLE ingredients ADD COLUMN image BYTEA;

ALTER TABLE chefs ADD COLUMN image BYTEA;

ALTER TABLE equipment ADD COLUMN image BYTEA;
