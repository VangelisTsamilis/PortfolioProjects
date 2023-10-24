/*

Crime Data Database Creation and Exploration in SQL Queries

Skills used: Create tables, Insert into, Aggregate Functions, Index, View, Trigger

Dataset used: https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2

*/

--Create the tables tables

--Create table Type
CREATE TABLE "Type" (typeID INTEGER PRIMARY KEY AUTOINCREMENT,iucr TEXT NOT NULL, primary_description TEXT NOT NULL, secondary_description TEXT NOT NULL);

--Create table Location
CREATE TABLE "Location" (locationID INTEGER PRIMARY KEY AUTOINCREMENT, location_description TEXT NOT NULL, beat INT NOT NULL, district INT NOT NULL);

--Create table Crime
CREATE TABLE "Crime" (crimeID INTEGER PRIMARY KEY NOT NULL, date TEXT NOT NULL, arrest INT NOT NULL, typeID INTEGER , locationID INTEGER, 
FOREIGN KEY (typeID)REFERENCES Type(typeID), FOREIGN KEY (locationID)REFERENCES Location(locationID));

--Fill in the tables

--Fill in table Type
INSERT INTO Type(iucr, primary_description, secondary_description) SELECT DISTINCT iucr, primary_description, secondary_description FROM clean_crimes;

--Fill in table Location
INSERT INTO Location(location_description, beat, district) SELECT DISTINCT location_description, beat, district FROM clean_crimes;

--Fill in table Crime
INSERT INTO Crime(crimeID,date,arrest,typeID,locationID)
SELECT clean_crimes.crimeID, clean_crimes.date, clean_crimes.arrest, Type.typeID, Location.locationID
FROM clean_crimes 
JOIN Type
ON Type.iucr = clean_crimes.iucr AND Type.primary_description=clean_crimes.primary_description AND Type.secondary_description=clean_crimes.secondary_description
JOIN Location
ON Location.beat=clean_crimes.beat AND Location.district=clean_crimes.district AND Location.location_description=clean_crimes.location_description;


--How does the most frequent type of crime vary by month throughout the year?

--Creating the index
CREATE INDEX "idx_year" ON "Crime"(strftime('%Y', date));

--Running the query
SELECT max(Frequency) as Crimes_Recorded, Month, Year, iucr, primary_description, secondary_description FROM(
SELECT strftime('%m', Crime.date) as Month,strftime('%Y', Crime.date) as Year, Type.iucr, Type.primary_description, Type.secondary_description, COUNT(*) as Frequency
FROM Crime
JOIN Type
ON Type.typeID=Crime.typeID
WHERE strftime('%Y', Crime.date) IS '2017'
GROUP BY Type.typeID, strftime('%m', Crime.date)
ORDER BY COUNT(*) DESC, strftime('%m', Crime.date) 
) GROUP BY Month;

--Evidence of the query using the index created earlier
EXPLAIN QUERY PLAN SELECT max(Frequency),Month, Year, iucr, primary_description, secondary_description FROM(
SELECT strftime('%m', Crime.date) as Month,strftime('%Y', Crime.date) as Year, Type.iucr, Type.primary_description, Type.secondary_description, COUNT(*) as Frequency
FROM Crime
JOIN Type
ON Type.typeID=Crime.typeID
WHERE strftime('%Y', Crime.date) IS '2017'
GROUP BY Type.typeID, strftime('%m', Crime.date)
ORDER BY COUNT(*) DESC, strftime('%m', Crime.date) 
) GROUP BY Month;

--How does the total number of crimes change by district and beat?

--Running the query for district
SELECT DISTINCT RANK() 
OVER (ORDER BY COUNT(*) DESC) as district_rank, Location.district, COUNT(*) as Crimes_Recorded
FROM Crime
JOIN Location
ON Crime.locationID=Location.locationID
GROUP BY Location.district

--Running the query for top 10 beats
SELECT DISTINCT RANK() 
OVER (ORDER BY COUNT(*) DESC) as district_rank, Location.beat, Location.district, COUNT(*) as Crimes_Recorded
FROM Crime
JOIN Location
ON Crime.locationID=Location.locationID
GROUP BY Location.beat
LIMIT 10

--Running the query for bottom 10 beats
SELECT DISTINCT RANK() 
OVER (ORDER BY COUNT(*) DESC) as district_rank, Location.district, Location.beat, COUNT(*) as Crimes_Recorded
FROM Crime
JOIN Location
ON Crime.locationID=Location.locationID
GROUP BY Location.beat
LIMIT 264,10

--What percentage of crimes led to an arrest depending on the location description?

--Creating the view
CREATE VIEW arrest_percentage AS
SELECT Location.location_description, ROUND(AVG(Crime.arrest),3)*100 as Percentage_Arrested, count(*) as Total_Crimes
FROM Crime
JOIN Location
ON Crime.locationID=Location.locationID
GROUP BY Location.location_description

--Running the query for top 10
SELECT location_description, Percentage_Arrested
FROM arrest_percentage
WHERE Total_Crimes>50
ORDER BY Percentage_Arrested DESC
LIMIT 10

--Running the query for bottom 10
SELECT location_description, Percentage_Arrested
FROM arrest_percentage
WHERE Total_Crimes>50
ORDER BY Percentage_Arrested DESC
LIMIT 117,10


--Trigger

--This is a trigger created to deny the insertion of new row to this table. The codes are standard and cannot be changed.
CREATE TRIGGER InsertIntoTypeTrigger 
       BEFORE INSERT ON Type
BEGIN
  SELECT RAISE(ABORT, "The table cannot be changed!The contents of this table are standard according to the Illinois Uniform Crime Reporting Code!");
END;	

--Try to insert into the table to receive the message
INSERT INTO Type(iucr,primary_description,secondary_description) VALUES(10000, "THEFT", "OVER 10000")