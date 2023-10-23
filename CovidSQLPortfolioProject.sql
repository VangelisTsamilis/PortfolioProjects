/*
Covid 19 Data Exploration
from 01-01-2020 to 30-04-2021

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4;

--Select the data that will be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

--Looking at total cases vs total deaths
--Shows the likelihood of dying if you contract covid in you country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Greece%'
ORDER BY 1,2;

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasesPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%Greece%'
ORDER BY 1,2;

--Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, max((total_cases/population))*100 as InfectedPopulationPercentage 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectedPopulationPercentage DESC;

--Showing the countries with the Highest Death Count per Population
--Need to cast the total_deaths as interger because nvarchar data type leads to an error while using order by
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--At this point, it was realized that locations include continents or groups of countries. This was eliminated using only the data in where continent is not null

--LETS BREAK THINGS DOWN BY CONTINENT

--Showing the continents with the HighestDeathCount
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

--So far only the CovidDeaths table was used. Now also the CovidVaccinations table will be used

-- Looking at Total Population vs Vaccinations

--Looking at Rolling Count of Vaccinations per day (which is the same as the total count of the dataset)
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

--Use CTE (Common Table Expression) to calculate the population percentage vaccinated each day

WITH PopVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
);

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePopulationVaccinated
FROM PopVac;

-- Use TEMP TABLE to calculate the population percentage vaccinated each day

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePopulationVaccinated
FROM #PercentPopulationVaccinated;

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT * FROM PercentPopulationVaccinated;
 
