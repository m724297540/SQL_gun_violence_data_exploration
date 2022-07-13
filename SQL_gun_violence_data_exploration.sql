/*
Gun Violence Data Exploration
Skills used: Join, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Coverting Data Types, Variables, While loops
*/
USE sql_portfolio
GO

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

-- This dataset only includes states that has gun violence accidents
-- The following query find states with zero gun violence accidents from 2019-02-17 to 2022-07-05
-- Create a state look up table and then look up which state does not appear in the gun violence dataset
-- Hawaii, North Dakota, Vermont have zero accident during the time range in the dataset

DROP TABLE IF EXISTS sql_portfolio..StateLookup;
CREATE TABLE sql_portfolio..StateLookup
(
   StateID       INT IDENTITY (1, 1),
   StateName     VARCHAR (32),
   StateAbbrev   CHAR (2),
);

INSERT INTO sql_portfolio..StateLookup
VALUES ('Alabama', 'AL'),
       ('Alaska', 'AK'),
       ('Arizona', 'AZ'),
       ('Arkansas', 'AR'),
       ('California', 'CA'),
       ('Colorado', 'CO'),
       ('Connecticut', 'CT'),
       ('Delaware', 'DE'),
       ('District of Columbia', 'DC'),
       ('Florida', 'FL'),
       ('Georgia', 'GA'),
       ('Hawaii', 'HI'),
       ('Idaho', 'ID'),
       ('Illinois', 'IL'),
       ('Indiana', 'IN'),
       ('Iowa', 'IA'),
       ('Kansas', 'KS'),
       ('Kentucky', 'KY'),
       ('Louisiana', 'LA'),
       ('Maine', 'ME'),
       ('Maryland', 'MD'),
       ('Massachusetts', 'MA'),
       ('Michigan', 'MI'),
       ('Minnesota', 'MN'),
       ('Mississippi', 'MS'),
       ('Missouri', 'MO'),
       ('Montana', 'MT'),
       ('Nebraska', 'NE'),
       ('Nevada', 'NV'),
       ('New Hampshire', 'NH'),
       ('New Jersey', 'NJ'),
       ('New Mexico', 'NM'),
       ('New York', 'NY'),
       ('North Carolina', 'NC'),
       ('North Dakota', 'ND'),
       ('Ohio', 'OH'),
       ('Oklahoma', 'OK'),
       ('Oregon', 'OR'),
       ('Pennsylvania', 'PA'),
       ('Rhode Island', 'RI'),
       ('South Carolina', 'SC'),
       ('South Dakota', 'SD'),
       ('Tennessee', 'TN'),
       ('Texas', 'TX'),
       ('Utah', 'UT'),
       ('Vermont', 'VT'),
       ('Virginia', 'VA'),
       ('Washington', 'WA'),
       ('West Virginia', 'WV'),
       ('Wisconsin', 'WI'),
       ('Wyoming', 'WY')

SELECT DISTINCT StateName
FROM sql_portfolio..StateLookup
WHERE StateName NOT IN (
	SELECT State
	FROM sql_portfolio..mass_shooting
);

-- Creating View to store data for later visualizations
-- Columns: state, year, total_incidents, total_killed, total_injured, total_killed_child, total_injured_child, total_killed_teens, total_injured_teens

DROP TABLE IF EXISTS sql_portfolio..gun_data_viz_table;
CREATE TABLE sql_portfolio..gun_data_viz_table(
	state VARCHAR(225),
	year INT,
	total_incidents INT,
	total_killed INT,
	total_injured INT, 
	total_ck INT,
	total_ci INT,
	total_tk INT,
	total_ti INT
)

INSERT INTO sql_portfolio..gun_data_viz_table
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

DROP VIEW IF EXISTS sql_portfolio..gun_data_viz;
CREATE VIEW gun_data_viz AS
SELECT * 
FROM sql_portfolio..gun_data_viz_table;

---------------------------------------
-- Modify the view by adding new rows--
---------------------------------------


-- States have 0 incidents in 2019
SELECT DISTINCT StateName,
	ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
FROM sql_portfolio..StateLookup
WHERE StateName NOT IN (
	SELECT State
	FROM sql_portfolio..mass_shooting
	WHERE YEAR([Incident Date]) = 2019
);

-- States have 0 incidents in 2020
SELECT DISTINCT StateName,
	ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
FROM sql_portfolio..StateLookup
WHERE StateName NOT IN (
	SELECT State
	FROM sql_portfolio..mass_shooting
	WHERE YEAR([Incident Date]) = 2020
);

-- States have 0 incidents in 2021
SELECT DISTINCT StateName,
	ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
FROM sql_portfolio..StateLookup
WHERE StateName NOT IN (
	SELECT State
	FROM sql_portfolio..mass_shooting
	WHERE YEAR([Incident Date]) = 2021
);

-- States have 0 incidents in 2022
SELECT DISTINCT StateName,
	ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
FROM sql_portfolio..StateLookup
WHERE StateName NOT IN (
	SELECT State
	FROM sql_portfolio..mass_shooting
	WHERE YEAR([Incident Date]) = 2022
);

-- Create table variable to hold new written observations: states with 0 incidents
DECLARE @table_addon TABLE (
	state VARCHAR(225), 
	year INT, 
	total_incidents INT, 
	total_killed INT, 
	total_injured INT, 
	total_ck INT, 
	total_ci INT, 
	total_tk INT,
	total_ti INT
)

DECLARE @num2019 INT
DECLARE @num2020 INT
DECLARE @num2021 INT
DECLARE @num2022 INT

DECLARE @index INT
DECLARE @name VARCHAR(225)

SELECT @num2019 = COUNT(*)
	FROM 
		(SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2019
			)) t

SELECT @num2020 = COUNT(*)
	FROM 
		(SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2020
			)) t

SELECT @num2021 = COUNT(*)
	FROM 
		(SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2021
			)) t

SELECT @num2022 = COUNT(*)
	FROM 
		(SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2022
			)) t
			
SET @index = 1
WHILE @index <= @num2019
BEGIN
	SELECT @name = StateName FROM (
		SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2019
			)) t
	WHERE rownum = @index
	PRINT @name
	INSERT INTO @table_addon (state, year, total_incidents, total_killed, total_injured, total_ck, total_ci, total_tk, total_ti)
	VALUES (@name, 2019, 0, 0, 0, 0, 0, 0, 0)
	SELECT @index = @index + 1
END

SET @index = 1
WHILE @index <= @num2020
BEGIN
	SELECT @name = StateName FROM (
		SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2020
			)) t
	WHERE rownum = @index

	INSERT INTO @table_addon (state, year, total_incidents, total_killed, total_injured, total_ck, total_ci, total_tk, total_ti)
	VALUES (@name, 2020, 0, 0, 0, 0, 0, 0, 0)
	SELECT @index = @index + 1
END

SET @index = 1
WHILE @index <= @num2021
BEGIN
	SELECT @name = StateName FROM (
		SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2021
			)) t
	WHERE rownum = @index

	INSERT INTO @table_addon (state, year, total_incidents, total_killed, total_injured, total_ck, total_ci, total_tk, total_ti)
	VALUES (@name, 2021, 0, 0, 0, 0, 0, 0, 0)
	SELECT @index = @index + 1
END

SET @index = 1
WHILE @index <= @num2022
BEGIN
	PRINT @index
	SELECT @name = StateName FROM (
		SELECT DISTINCT StateName, 
		ROW_NUMBER() OVER( ORDER BY StateName) AS rownum
		FROM sql_portfolio..StateLookup
		WHERE StateName NOT IN (
			SELECT State
			FROM sql_portfolio..mass_shooting
			WHERE YEAR([Incident Date]) = 2022
			)) t
	WHERE rownum = @index

	INSERT INTO @table_addon (state, year, total_incidents, total_killed, total_injured, total_ck, total_ci, total_tk, total_ti)
	VALUES (@name, 2022, 0, 0, 0, 0, 0, 0, 0)
	SELECT @index = @index + 1
END

-- Insert new rows into gun_data_viz_table
INSERT INTO sql_portfolio..gun_data_viz_table
SELECT * FROM @table_addon
-- Alter the view
ALTER VIEW gun_data_viz
AS 
SELECT * FROM sql_portfolio..gun_data_viz_table
