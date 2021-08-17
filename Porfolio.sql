SELECT *
FROM Portfolio..CovidsDeaths
ORDER BY 3,4;

SELECT *
FROM Portfolio..CovidVaccinated
ORDER BY 3,4;

SELECT *
FROM Portfolio..Populations
ORDER BY 3,4;

--Clean up data
--Delete rows in population table that contain NULL continent
SELECT continent, location, population
FROM Portfolio..Populations
where continent LIKE '(blank)';

DELETE FROM Portfolio..Populations
WHERE continent LIKE '(blank)';

-- How many and which countries are included

SELECT DISTINCT location
FROM Portfolio..CovidsDeaths;

--Looking at total cases vs total death aka death rate 
--death rate = (total_death/total_cases)*100

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM Portfolio..CovidsDeaths
order by 5 DESC ;
-- Note: max death_rate 100

--Looking at Total case Vs Population
-- infected rate = (total cases/population)*100

SELECT cd.location, cd.date, cd.total_cases, p.population, (cd.total_cases/p.population)*100 as infected_rate
FROM Portfolio..CovidsDeaths AS cd
INNER JOIN Portfolio..Populations AS p
ON cd.location = p.location
order by 5 ;
-- Note: max infected_rate 19, min 0

--Looking at countries with highest infected rate

SELECT cd.location, MAX(cd.total_cases) AS max_cases, p.population, MAX((cd.total_cases/p.population)*100) as infected_rate
FROM Portfolio..CovidsDeaths AS cd
INNER JOIN Portfolio..Populations AS p
ON cd.location = p.location
GROUP BY cd.location, p.population
Order by 4 DESC;
-- Andorra with 19.32, China is surprisingly low

-- Looking at countries with highest death count per population

SELECT cd.location, MAX(CAST(cd.total_deaths AS INT)) AS max_deathcount, p.population, MAX((CAST(cd.total_deaths AS INT) / p.population)*100) as death_per_population
FROM Portfolio..CovidsDeaths AS cd
INNER JOIN Portfolio..Populations AS p
ON cd.location = p.location
--WHERE p.continent LIKE 'Asia'
GROUP BY cd.location, p.population
Order by 4 DESC;

-- Showing 20 countries with highest death count

SELECT cd.location, p.population, MAX(CAST(cd.total_deaths AS INT)) As death_counts
FROM Portfolio..CovidsDeaths as cd
INNER JOIN Portfolio..Populations AS p
ON cd.location = p.location
GROUP BY cd.location, p.population
Order by death_counts DESC
OFFSET 0 ROWS
FETCH NEXT 20 ROWS ONLY;

-- Looking at highest death count per continent

SELECT p.continent, SUM(cd1.death_counts) As Max_deathcounts
FROM (SELECT location, MAX(cast(total_deaths as int)) As death_counts
				FROM Portfolio..CovidsDeaths
				GROUP BY location) AS cd1

INNER JOIN Portfolio..Populations AS p
ON cd1.location = p.location
GROUP BY p.continent
Order by 2 DESC;

--test if above querry is correct by comparing with below
--SELECT p.continent, SUM(cast(new_deaths as int))
--FROM Portfolio..CovidsDeaths as cd
--INNER JOIN Portfolio..Populations AS p
--ON cd.location = p.location
--GROUP BY p.continent
--Order by 2 DESC;


--Global trend
SELECT  sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 AS death_percentage
FROM Portfolio..CovidsDeaths
ORDER BY 1,2;


-- Looking at Vccinations vs Total Population
-- CTE of rolling vaccinated count
WITH PopVax (Continent, Location, Population, date,new_vaccinations, rolling_vax )
AS (

SELECT  p.continent, p.location,  p.population, date, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as INT)) OVER (Partition by vax.location ORDER BY p.location, date) as rolling_vax
FROM Portfolio..CovidVaccinated vax
 JOIN Portfolio..Populations p
ON p.location = vax.location

)

select * , rolling_vax/Population*100 AS vacinations_percentage
from PopVax
--where location LIKE '%France'

-- Creating view to store data

Drop view if exists [PercentagePopulationVaccinated];

Create View [PercentagePopulationVaccinated]  as
	WITH PopVax (Continent, Location, Population, date,new_vaccinations, rolling_vax )
	AS (
		SELECT  p.continent, p.location,  p.population, date, vax.new_vaccinations,
		SUM(cast(vax.new_vaccinations as INT)) OVER (Partition by vax.location ORDER BY p.location, date) as rolling_vax
		FROM Portfolio..CovidVaccinated vax
		JOIN Portfolio..Populations p
		ON p.location = vax.location)
	select * , rolling_vax/Population*100 AS vacinations_percentage
	from PopVax

select * from [PercentagePopulationVaccinated];


