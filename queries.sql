3.1)

test=# SELECT 
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


3.2)

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
    chefs.surname;

3.3)

test=# SELECT 
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


3.4)

test=# SELECT 
    chef_name, 
    surname
FROM 
    chefs
WHERE 
    chef_id NOT IN (
        SELECT judge_id 
        FROM judge_episodes
    );



3.5)
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
    appearances DESC, year;


--that gives us zero and we can check that by running the
--following querie which shows that no judge  has more than
--3 appearances in a season


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
    season, appearances DESC;


--gia opoiodipote span 10 episodiwn 

WITH JudgeAppearances AS (
    SELECT 
        je.judge_id,
        c.chef_name, 
        c.surname,
        CEILING(je.judge_no_ep / 10.0) AS year,
        COUNT(je.judge_no_ep) AS appearances
    FROM 
        judge_episodes je
    JOIN 
        chefs c ON je.judge_id = c.chef_id
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
HAVING 
    COUNT(judge_id) > 1
ORDER BY 
    appearances DESC, year;
--pali pernoume 0



3.6)
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

--before indexing
Limit  (cost=88.57..88.58 rows=3 width=244) (actual time=2.375..2.380 rows=3 loops=1)
  ->  Sort  (cost=88.57..89.79 rows=487 width=244) (actual time=2.373..2.377 rows=3 loops=1)
        Sort Key: (count(*)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        ->  HashAggregate  (cost=72.54..77.41 rows=487 width=244) (actual time=2.117..2.230 rows=313 loops=1)
              Group Key: t1.name, t2.name
              Batches: 1  Memory Usage: 105kB
              ->  Hash Join  (cost=25.65..68.88 rows=487 width=236) (actual time=0.696..1.659 rows=595 loops=1)
                    Hash Cond: (tr1.id_rec = tr2.id_rec)
                    Join Filter: (t1.id_tags < t2.id_tags)
                    Rows Removed by Join Filter: 865
                    ->  Nested Loop  (cost=0.16..22.11 rows=270 width=126) (actual time=0.041..0.511 rows=270 loops=1)
                          ->  Seq Scan on tags_rec tr1  (cost=0.00..4.70 rows=270 width=8) (actual time=0.017..0.065 rows=270 loops=1)
                          ->  Memoize  (cost=0.16..0.36 rows=1 width=122) (actual time=0.001..0.001 rows=1 loops=270)
                                Cache Key: tr1.id_tags
                                Cache Mode: logical
                                Hits: 240  Misses: 30  Evictions: 0  Overflows: 0  Memory Usage: 4kB
                                ->  Index Scan using tags_pkey on tags t1  (cost=0.15..0.35 rows=1 width=122) (actual time=0.003..0.003 rows=1 loops=30)
                                      Index Cond: (id_tags = tr1.id_tags)
                    ->  Hash  (cost=22.11..22.11 rows=270 width=126) (actual time=0.633..0.634 rows=270 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 22kB
                          ->  Nested Loop  (cost=0.16..22.11 rows=270 width=126) (actual time=0.022..0.501 rows=270 loops=1)
                                ->  Seq Scan on tags_rec tr2  (cost=0.00..4.70 rows=270 width=8) (actual time=0.012..0.064 rows=270 loops=1)
                                ->  Memoize  (cost=0.16..0.36 rows=1 width=122) (actual time=0.001..0.001 rows=1 loops=270)
                                      Cache Key: tr2.id_tags
                                      Cache Mode: logical
                                      Hits: 240  Misses: 30  Evictions: 0  Overflows: 0  Memory Usage: 4kB
                                      ->  Index Scan using tags_pkey on tags t2  (cost=0.15..0.35 rows=1 width=122) (actual time=0.003..0.003 rows=1 loops=30)
                                            Index Cond: (id_tags = tr2.id_tags)
Planning Time: 1.287 ms
Execution Time: 2.475 ms



--after indexing

Limit  (cost=88.57..88.58 rows=3 width=244) (actual time=1.030..1.034 rows=3 loops=1)
  ->  Sort  (cost=88.57..89.79 rows=487 width=244) (actual time=1.029..1.032 rows=3 loops=1)
        Sort Key: (count(*)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        ->  HashAggregate  (cost=72.54..77.41 rows=487 width=244) (actual time=0.897..0.956 rows=313 loops=1)
              Group Key: t1.name, t2.name
              Batches: 1  Memory Usage: 105kB
              ->  Hash Join  (cost=25.65..68.88 rows=487 width=236) (actual time=0.266..0.671 rows=595 loops=1)
                    Hash Cond: (tr1.id_rec = tr2.id_rec)
                    Join Filter: (t1.id_tags < t2.id_tags)
                    Rows Removed by Join Filter: 865
                    ->  Nested Loop  (cost=0.16..22.11 rows=270 width=126) (actual time=0.020..0.208 rows=270 loops=1)
                          ->  Seq Scan on tags_rec tr1  (cost=0.00..4.70 rows=270 width=8) (actual time=0.008..0.030 rows=270 loops=1)
                          ->  Memoize  (cost=0.16..0.36 rows=1 width=122) (actual time=0.000..0.000 rows=1 loops=270)
                                Cache Key: tr1.id_tags
                                Cache Mode: logical
                                Hits: 240  Misses: 30  Evictions: 0  Overflows: 0  Memory Usage: 4kB
                                ->  Index Scan using tags_pkey on tags t1  (cost=0.15..0.35 rows=1 width=122) (actual time=0.001..0.001 rows=1 loops=30)
                                      Index Cond: (id_tags = tr1.id_tags)
                    ->  Hash  (cost=22.11..22.11 rows=270 width=126) (actual time=0.237..0.238 rows=270 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 22kB
                          ->  Nested Loop  (cost=0.16..22.11 rows=270 width=126) (actual time=0.008..0.185 rows=270 loops=1)
                                ->  Seq Scan on tags_rec tr2  (cost=0.00..4.70 rows=270 width=8) (actual time=0.004..0.025 rows=270 loops=1)
                                ->  Memoize  (cost=0.16..0.36 rows=1 width=122) (actual time=0.000..0.000 rows=1 loops=270)
                                      Cache Key: tr2.id_tags
                                      Cache Mode: logical
                                      Hits: 240  Misses: 30  Evictions: 0  Overflows: 0  Memory Usage: 4kB
                                      ->  Index Scan using tags_pkey on tags t2  (cost=0.15..0.35 rows=1 width=122) (actual time=0.001..0.001 rows=1 loops=30)
                                            Index Cond: (id_tags = tr2.id_tags)
Planning Time: 0.723 ms
Execution Time: 1.091 ms


3.7)
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


3.8)
--non indexed results
Limit  (cost=142.87..142.87 rows=1 width=12) (actual time=2.909..2.912 rows=1 loops=1)
  ->  Sort  (cost=142.87..149.24 rows=2550 width=12) (actual time=2.907..2.909 rows=1 loops=1)
        Sort Key: (count(re.equipment_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        ->  HashAggregate  (cost=104.62..130.12 rows=2550 width=12) (actual time=2.873..2.893 rows=50 loops=1)
              Group Key: e.no_ep
              Batches: 1  Memory Usage: 121kB
              ->  Hash Join  (cost=25.62..91.08 rows=2708 width=8) (actual time=0.563..2.039 rows=2669 loops=1)
                    Hash Cond: (ce.rec_id = r.id_rec)
                    ->  Nested Loop  (cost=0.17..34.16 rows=500 width=8) (actual time=0.051..0.776 rows=500 loops=1)
                          ->  Seq Scan on chefs_episodes ce  (cost=0.00..8.00 rows=500 width=8) (actual time=0.021..0.122 rows=500 loops=1)
                          ->  Memoize  (cost=0.17..0.28 rows=1 width=4) (actual time=0.001..0.001 rows=1 loops=500)
                                Cache Key: ce.chef_no_ep
                                Cache Mode: logical
                                Hits: 450  Misses: 50  Evictions: 0  Overflows: 0  Memory Usage: 6kB
                                ->  Index Only Scan using episodes_pkey on episodes e  (cost=0.15..0.27 rows=1 width=4) (actual time=0.002..0.002 rows=1 loops=50)
                                      Index Cond: (no_ep = ce.chef_no_ep)
                                      Heap Fetches: 50
                    ->  Hash  (cost=21.87..21.87 rows=287 width=12) (actual time=0.501..0.502 rows=287 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 21kB
                          ->  Hash Join  (cost=16.19..21.87 rows=287 width=12) (actual time=0.105..0.370 rows=287 loops=1)
                                Hash Cond: (re.recipes_id = r.id_rec)
                                ->  Seq Scan on recipes_has_equipment re  (cost=0.00..4.87 rows=287 width=8) (actual time=0.014..0.074 rows=287 loops=1)
                                ->  Hash  (cost=15.53..15.53 rows=53 width=4) (actual time=0.081..0.082 rows=53 loops=1)
                                      Buckets: 1024  Batches: 1  Memory Usage: 10kB
                                      ->  Seq Scan on recipes r  (cost=0.00..15.53 rows=53 width=4) (actual time=0.009..0.057 rows=53 loops=1)
Planning Time: 1.721 ms
Execution Time: 3.035 ms

--indexed results
Limit  (cost=142.87..142.87 rows=1 width=12) (actual time=2.009..2.013 rows=1 loops=1)
  ->  Sort  (cost=142.87..149.24 rows=2550 width=12) (actual time=2.007..2.011 rows=1 loops=1)
        Sort Key: (count(re.equipment_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        ->  HashAggregate  (cost=104.62..130.12 rows=2550 width=12) (actual time=1.962..1.994 rows=50 loops=1)
              Group Key: e.no_ep
              Batches: 1  Memory Usage: 121kB
              ->  Hash Join  (cost=25.62..91.08 rows=2708 width=8) (actual time=0.284..1.354 rows=2669 loops=1)
                    Hash Cond: (ce.rec_id = r.id_rec)
                    ->  Nested Loop  (cost=0.17..34.16 rows=500 width=8) (actual time=0.027..0.534 rows=500 loops=1)
                          ->  Seq Scan on chefs_episodes ce  (cost=0.00..8.00 rows=500 width=8) (actual time=0.010..0.072 rows=500 loops=1)
                          ->  Memoize  (cost=0.17..0.28 rows=1 width=4) (actual time=0.000..0.000 rows=1 loops=500)
                                Cache Key: ce.chef_no_ep
                                Cache Mode: logical
                                Hits: 450  Misses: 50  Evictions: 0  Overflows: 0  Memory Usage: 6kB
                                ->  Index Only Scan using episodes_pkey on episodes e  (cost=0.15..0.27 rows=1 width=4) (actual time=0.001..0.001 rows=1 loops=50)
                                      Index Cond: (no_ep = ce.chef_no_ep)
                                      Heap Fetches: 50
                    ->  Hash  (cost=21.87..21.87 rows=287 width=12) (actual time=0.252..0.253 rows=287 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 21kB
                          ->  Hash Join  (cost=16.19..21.87 rows=287 width=12) (actual time=0.063..0.188 rows=287 loops=1)
                                Hash Cond: (re.recipes_id = r.id_rec)
                                ->  Seq Scan on recipes_has_equipment re  (cost=0.00..4.87 rows=287 width=8) (actual time=0.007..0.039 rows=287 loops=1)
                                ->  Hash  (cost=15.53..15.53 rows=53 width=4) (actual time=0.050..0.051 rows=53 loops=1)
                                      Buckets: 1024  Batches: 1  Memory Usage: 10kB
                                      ->  Seq Scan on recipes r  (cost=0.00..15.53 rows=53 width=4) (actual time=0.004..0.038 rows=53 loops=1)
Planning Time: 1.625 ms
Execution Time: 2.082 ms

--query

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


--3.9)
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

--3.14) afou valw to food groups


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

