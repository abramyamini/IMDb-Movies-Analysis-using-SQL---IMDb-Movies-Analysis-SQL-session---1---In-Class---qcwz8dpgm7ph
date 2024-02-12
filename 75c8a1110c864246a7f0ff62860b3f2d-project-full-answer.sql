CREATE database imdb_pr;

-- -	Find the total number of rows in each table of the schema.

SELECT table_name, table_rows
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'imdb_pr';

-- -	Identify which columns in the movie table have null values

SELECT 
SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ID_nulls, 
SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS title_nulls, 
SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS year_nulls,
SUM(CASE WHEN date_published IS NULL THEN 1 ELSE 0 END) AS date_published_nulls,
SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS duration_nulls,
SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
SUM(CASE WHEN worlwide_gross_income IS NULL THEN 1 ELSE 0 END) AS worlwide_gross_income_nulls,
SUM(CASE WHEN languages IS NULL THEN 1 ELSE 0 END) AS languages_nulls,
SUM(CASE WHEN production_company IS NULL THEN 1 ELSE 0 END) AS production_company_nulls
FROM movies;


-- Segment 2: Movie Release Trends
-- -	Determine the total number of movies released each year and analyse the month-wise trend.

SELECT  COUNT(*) AS movies_released
FROM (SELECT YEAR(year) AS release_year, MONTH(date_published) AS release_month
FROM movies) AS subquery
GROUP BY release_year, release_month
ORDER BY release_year, release_month;

-- -	Calculate the number of movies produced in the USA or India in the year 2019.
SELECT COUNT(*) AS movie_count 
FROM movies
WHERE (country='USA' OR country= 'India') AND YEAR(year)=2019;

-- Segment 3: Production Statistics and Genre Analysis
-- 	Retrieve the unique list of genres present in the dataset

SELECT distinct genre
FROM genre;

-- -	Identify the genre with the highest number of movies produced overall.
SELECT COUNT(movie_id),genre
FROM genre
GROUP BY genre
ORDER BY COUNT(movie_id) DESC;

-- -	Determine the count of movies that belong to only one genre.

SELECT distinct(genre),COUNT(movie_id) AS single_genre_movies_count
FROM genre
GROUP BY genre;

---	Calculate the average duration of movies in each genre
SELECT AVG(duration),genre 
FROM movies
JOIN genre ON movies.id=genre.movie_id
group by genre;

-- Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
SELECT count(title),genre,rank() OVER (ORDER BY genre DESC) AS rank_genre FROM genre
JOIN movies ON genre.movie_id=movies.id 
WHERE genre='thriller'
GROUP BY genre
Order by rank_genre;

-- Segment 4: Ratings Analysis and Crew Members
-	-- Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
SELECT  MAX(avg_rating),MAX(total_votes),MAX(median_rating),
 min(avg_rating),Min(total_votes),Min(median_rating)
 FROM ratings;


-- Identify the top 10 movies based on average rating.
SELECT a.title,b.avg_rating from movies a
join ratings b ON a.id=b.movie_id
ORDER BY b.avg_rating DESC
LIMIT 10;
-- Summarise the ratings table based on movie counts by median ratings.
SELECT Count(movie_id),median_rating FROM ratings
group by median_rating;

-- Identify the production house that has produced the most number of hit movies (average rating > 8).
SELECT a.avg_rating,b.production_company
FROM movies b
LEFT JOIN ratings a ON b.id = a.movie_id
GROUP BY a.avg_rating,b.production_company
HAVING a.avg_rating>8 AND b.production_company ;
commit;

-- Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.

SELECT * FROM genre a
JOIN movies b ON a.movie_id=b.id
JOIN ratings c ON b.id=c.movie_id
GROUP BY a.movie_id,date_published,a.genre,total_votes,country
HAVING monthname(b.date_published)='MARCH' AND  year(b.date_published)=2017 AND country='USA' AND  c.total_votes>1000;


-- Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
SELECT a.title,b.genre FROM movies a
JOIN genre b ON a.id=b.movie_id
JOIN ratings c ON b.movie_id=c.movie_id
GROUP BY title,genre,avg_rating
HAVING a.title LIKE 'The%' AND avg_rating>8;

-- Segment 5: Crew Analysis
-- Identify the columns in the names table that have null values.
SELECT * FROM names 
WHERE id is null;

SELECT * FROM names 
WHERE name is null;

SELECT height FROM names 
WHERE height is null;

SELECT date_of_birth FROM names 
WHERE date_of_birth is null;

SELECT known_for_movies FROM names 
WHERE known_for_movies is null;


-- Determine the top three directors in the top three genres with movies having an average rating > 8.
SELECT name_id,genre
FROM director_mapping a
JOIN genre b ON a.movie_id=b.movie_id
JOIN ratings c ON b.movie_id=c.movie_id
GROUP BY name_id,genre,avg_rating,b.movie_id
HAVING avg_rating>8
LIMIT 3;

-- Find the top two actors whose movies have a median rating >= 8.
SELECT a.name FROM names a
JOIN ratings b ON a.known_for_movies=b.movie_id
GROUP BY name,b.movie_id,median_rating
HAVING median_rating>8
LIMIT 2;

-- Identify the top three production houses based on the number of votes received by their movies.
SELECT production_company FROM movies a
JOIN ratings b ON a.id=b.movie_id
group by production_company,movie_id,total_votes
HAVING max(total_votes)
Limit 3;

-- Rank actors based on their average ratings in Indian movies released in India.
SELECT name_id,category, rank()OVER(ORDER BY category DESC)  FROM role_mapping a
JOIN ratings b ON a.movie_id=b.movie_id
JOIN movies c ON b.movie_id=c.id
GROUP BY name_id,category,a.movie_id,avg_rating,c.country
HAVING category IN ('actor') AND country IN ('India');


-- Identify the top five actresses in Hindi movies released in India based on their average ratings.
SELECT name_id,category FROM role_mapping a
JOIN ratings b ON a.movie_id=b.movie_id
JOIN movies c ON b.movie_id=c.id
GROUP BY a.name_id,a.category,c.country,b.movie_id,b.avg_rating,c.languages
HAVING category IN ('actress') AND country IN ('India') AND languages In('Hindi')
LIMIT 5;

-- Segment 6: Broader Understanding of Data
	-- Classify thriller movies based on average ratings into different categories.
SELECT a.movie_id,genre, c.category  FROM genre a
JOIN ratings b ON a.movie_id=b.movie_id
JOIN role_mapping c ON b.movie_id=c.movie_id
GROUP BY category,a.movie_id,avg_rating,genre
HAVING category AND avg_rating AND genre IN ('Thriller');

-- analyse the genre-wise running total and moving average of the average movie duration.
SELECT genre,
		ROUND(AVG(duration),2) AS avg_duration,
        SUM(ROUND(AVG(duration),2)) OVER(ORDER BY genre ROWS UNBOUNDED PRECEDING) AS running_total_duration,
        AVG(ROUND(AVG(duration),2)) OVER(ORDER BY genre ROWS 10 PRECEDING) AS moving_avg_duration
FROM movies AS m 
INNER JOIN genre AS g 
ON m.id= g.movie_id
GROUP BY genre
ORDER BY genre;

-- Identify the five highest-grossing movies of each year that belong to the top three genres.

SELECT genre,count(movie_id)  FROM genre
group by genre
ORDER BY count(movie_id) DESC
LIMIT 3;

SELECT x.title,x.year,x.worlwide_gross_income,x.genre FROM 
(SELECT a.title,a.year,a.worlwide_gross_income,b.genre,RANK()
OVER(partition by a.year ORDER BY a.worlwide_gross_income DESC )
 AS RANK_NUMBER
FROM movies a
INNER JOIN genre b ON a.id=b.movie_id
WHERE b.genre IN (SELECT abc.genre FROM
 (SELECT genre,count(movie_id)  FROM genre
group by genre
ORDER BY count(movie_id) DESC
LIMIT 3) abc ) ) x
WHERE x.RANK_NUMBER <=5;



-- Determine the top two production houses that have produced the highest number of hits among multilingual movies.	
SELECT production_company,
COUNT(m.id) AS movie_count,
ROW_NUMBER() OVER(ORDER BY count(id) DESC) AS prod_comp_rank
FROM movies AS m 
INNER JOIN ratings AS r 
ON m.id=r.movie_id
WHERE median_rating>=8 AND production_company IS NOT NULL AND POSITION(',' IN languages)>0
GROUP BY production_company
LIMIT 2;

-- identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.

SELECT name,name_id, SUM(total_votes) AS total_votes,
COUNT(rm.movie_id) AS movie_count,
avg_rating,
DENSE_RANK() OVER(ORDER BY avg_rating DESC) AS actress_rank
FROM names AS n
INNER JOIN role_mapping AS rm
ON n.id = rm.name_id
INNER JOIN ratings AS r
ON r.movie_id = rm.movie_id
INNER JOIN genre AS g
ON r.movie_id = g.movie_id
WHERE rm.category = 'actress' AND r.avg_rating > 8 AND g.genre = 'drama'
GROUP BY name,name_id
LIMIT 3;

-- Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.

WITH movie_date_info AS
(SELECT d.name_id, name, d.movie_id, m.date_published, 
LEAD(date_published, 1) OVER(PARTITION BY d.name_id ORDER BY date_published, d.movie_id) AS next_movie_date
FROM director_mapping d 
JOIN names AS n ON d.name_id=n.id 
JOIN movies AS m ON d.movie_id=m.id),
date_difference AS
(SELECT *, DATEDIFF(next_movie_date, date_published) AS diff
FROM movie_date_info),
 avg_inter_days AS
 (SELECT name_id, AVG(diff) AS avg_inter_movie_days
FROM date_difference
GROUP BY name_id),
final_result AS
 (SELECT d.name_id AS director_id,
		 name AS director_name,
		 COUNT(d.movie_id) AS number_of_movies,
		 ROUND(avg_inter_movie_days) AS inter_movie_days,
		 ROUND(AVG(avg_rating),2) AS avg_rating,
		 SUM(total_votes) AS total_votes,
		 MIN(avg_rating) AS min_rating,
		 MAX(avg_rating) AS max_rating,
		 SUM(duration) AS total_duration,
		 ROW_NUMBER() OVER(ORDER BY COUNT(d.movie_id) DESC) AS director_row_rank
	     FROM
		 names AS n 
         JOIN director_mapping AS d 
         ON n.id=d.name_id
		 JOIN ratings AS r 
         ON d.movie_id=r.movie_id
		 JOIN movies AS m 
         ON m.id=r.movie_id
		 JOIN avg_inter_days AS a 
         ON a.name_id=d.name_id
	 GROUP BY d.name_id)
     
 SELECT *	
 FROM final_result
 LIMIT 9;

