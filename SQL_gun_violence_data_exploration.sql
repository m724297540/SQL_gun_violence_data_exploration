/*
Gun Violence Data Exploration
Skills used: Join, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Coverting Data Types
*/

SELECT *
FROM sql_portfolio..mass_shooting

-- Drop duplicates incidents
WITH CTE ([Incident ID], [Incident Date], State, [City Or County], Address, [# Killed], [# Injured], row_number)
AS (
	SELECT [Incident ID], [Incident Date], State, [City Or County], Address, [# Killed], [# Injured],
		   ROW_NUMBER() OVER (PARTITION BY [Incident ID], [Incident Date], State, [City Or County], Address, [# Killed], [# Injured] ORDER BY [Incident ID]) AS row_number
	FROM sql_portfolio..mass_shooting)
DELETE FROM CTE
WHERE row_number > 1;


-- Select data that we are going to be starting with
SELECT [Incident ID], CONVERT(DATE, [Incident Date]) as Date, State, [City Or County], [# Killed], [# Injured]
FROM sql_portfolio..mass_shooting
ORDER BY 2,3;


-- Time range in the dataset:  The dataset recoreds gun violence from 2019-02-17 to 2022-07-05
SELECT MIN(CONVERT(DATE, [Incident Date])) AS starting_time, MAX(CONVERT(DATE, [Incident Date])) AS ending_time
FROM sql_portfolio..mass_shooting;


-- Total gun violence incidents by year
-- In the dataset: 
-- 2019: 378 incidents, 2020: 610 incidents, 2021: 692 incidents(highest), 2022: 320 incidents(lowest);

SELECT COUNT(*) AS number_incidents, YEAR([Incident Date]) AS year
FROM sql_portfolio..mass_shooting
GROUP BY YEAR([Incident Date])
ORDER BY COUNT(*);


-- Total gun violence incidents by state
-- Illinois has the highest incident number (217), New Hampshire, Maine, and Wyoming have the lowest incident number 1).
SELECT COUNT(*) AS number_incidents, State
FROM sql_portfolio..mass_shooting
GROUP BY State
ORDER BY COUNT(*) DESC;

-- Look into gun violence in Illinois
-- Over 75% gun violence incidents happened in Chicago
SELECT [City Or County], 
		COUNT(*) AS number_incidents,
		CAST(COUNT(*)*100.0/ SUM(COUNT(*)) OVER() AS DECIMAL(4,2)) AS state_incident_percentage,
		SUM(COUNT(*)) OVER() AS Illinois_total_incidents
FROM sql_portfolio..mass_shooting
WHERE State = 'Illinois'
GROUP BY [City Or County]
ORDER BY COUNT(*) DESC;

-- Using Temp Table to perform calculation in previous query. This approach is less efficient.
DROP TABLE IF EXISTS state_data;
CREATE TABLE state_data(
	state VARCHAR(255),
	number_incidents INT
);

INSERT INTO state_data
SELECT State, COUNT(*) AS number_incidents
FROM sql_portfolio..mass_shooting
GROUP BY State

SELECT [City Or County], 
		COUNT(*) AS number_incidents,
		CAST(COUNT(*)*100.0/ (SELECT SUM(number_incidents) FROM state_data WHERE State = 'Illinois') AS DECIMAL(4,2)) AS state_incident_percentage,
		(SELECT SUM(number_incidents) FROM state_data WHERE State = 'Illinois')  AS Illinois_total_incidents
FROM sql_portfolio..mass_shooting
WHERE State = 'Illinois'
GROUP BY [City Or County]
ORDER BY COUNT(*) DESC;


-- Total gun violence incidents by month to check where the gun violence presents any seasonal trend
-- hot months (June to August) have more gun violence incidents, while cold months (December to Feburary) have lower incident number
SELECT COUNT(*) AS number_incidents, MONTH([Incident Date]) AS month
FROM sql_portfolio..mass_shooting
GROUP BY MONTH([Incident Date])
ORDER BY COUNT(*) DESC;


-- Average individual killed, average individual injured by state, year
SELECT YEAR([Incident Date]) as Date, State,
	   CONVERT(DECIMAL(3,2), AVG([# Killed])) AS avg_killed,
	   CONVERT(DECIMAL(3,2), AVG([# Injured])) AS avg_injured
FROM sql_portfolio..mass_shooting
GROUP BY State, YEAR([Incident Date])
ORDER BY CONVERT(DECIMAL(3,2), AVG([# Killed]))DESC;

-- Creating View to store data for later visualizations
-- Columns: state, year, total_incidents, total_killed, total_injured, total_killed_child, total_injured_child, total_killed_teens, total_injured_teens
CREATE VIEW gun_data_viz AS
SELECT main.State AS state, YEAR(main.[Incident Date]) AS year, 
	   COUNT(*) AS total_incidents,
	   SUM(main.[# Killed]) AS total_killed, 
	   SUM(main.[# Injured]) AS total_injured,
	   SUM(isnull(ck.[# Killed],0)) AS total_ck, 
	   SUM(isnull(ci.[# Injured],0)) AS total_ci, 
	   SUM(isnull(tk.[# Killed],0)) AS total_tk, 
	   SUM(isnull(ti.[# Injured],0)) AS total_ti
FROM sql_portfolio..mass_shooting main
LEFT JOIN sql_portfolio..children_killed ck
ON main.[Incident ID] = ck.[Incident ID]
LEFT JOIN sql_portfolio..children_injured ci
ON main.[Incident ID] = ci.[Incident ID]
LEFT JOIN sql_portfolio..teens_killed tk
ON main.[Incident ID] = tk.[Incident ID]
LEFT JOIN sql_portfolio..teens_injured ti
ON main.[Incident ID] = ti.[Incident ID]
GROUP BY main.State, YEAR(main.[Incident Date]);
