SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4 

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--SELECT date AS original_date, date_clean
--FROM PortfolioProject..CovidDeaths
--WHERE date_clean IS NULL OR date_clean <> TRY_PARSE(date AS DATE USING 'en-GB');

--ALTER TABLE PortfolioProject..CovidDeaths
--DROP COLUMN date;

--EXEC sp_rename 'PortfolioProject..CovidDeaths.date_clean', 'date', 'COLUMN';

-- Select Data that we are going to be using

SELECT location,date, total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths:

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
from PortfolioProject..CovidDeaths
Where location like '%bulgaria%'
order by 1,2


-- Looking at Total Cases vs Population:
-- Shows what percentage got Covid:

Select location, date, total_cases, population, 
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
Where location like '%bulgaria%'
order by 1,2

-- Looking at Countries with highest infection rate vs Population

Select location,MAX(CAST(population as float)) as population, MAX(CAST(total_cases as float)) as HighestInfectionCount,
(MAX(CAST(total_cases as float)) / NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
group by location,population
order by PercentPopulationInfected desc


-- This is showing Countries with the highest death count per Population

Select continent,MAX(CAST(total_deaths as float)) as TotalDeathCount
from PortfolioProject..CovidDeaths
group by continent
order by TotalDeathCount desc


-- Global numbers 
	Select date, SUM(CAST(new_cases AS int)) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths,
	COALESCE(
        SUM(CAST(new_deaths AS int)) * 100.0 / NULLIF(SUM(CAST(new_cases AS int)), 0), 0) AS DeathPercentage
	from PortfolioProject..CovidDeaths
	--Where location like '%bulgaria%'
	where continent is not null 
	group by date
	order by 1,2

-- Global Numbers 
	Select SUM(CAST(new_cases AS int)) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths,
	COALESCE(
        SUM(CAST(new_deaths AS int)) * 100.0 / NULLIF(SUM(CAST(new_cases AS int)), 0), 0) AS DeathPercentage
	from PortfolioProject..CovidDeaths
	--Where location like '%bulgaria%'
	where continent is not null 
	order by 1,2

-- Looking at Total Population vs Vaccinations

Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(NULLIF(CONVERT(float, vac.new_vaccinations), 0)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vac
 On deaths.location = vac.location
 and deaths.date = TRY_CAST(vac.date AS DATE)
 where deaths.continent is not null
 order by 2,3
 

 -- Use CTE

 With PopulationVSVaccination (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
 as
(
 Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
,SUM(NULLIF(CONVERT(float, vac.new_vaccinations), 0)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vac
 On deaths.location = vac.location
 and deaths.date = TRY_CAST(vac.date AS DATE)
 where deaths.continent is not null
 --order by 2,3
 )
 Select *, (RollingPeopleVaccinated/population)*100 
 From PopulationVSVaccination

 -- TEMP TABLE

  DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations FLOAT,
    RollingPeopleVaccinated FLOAT
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    deaths.continent, 
    deaths.location, 
    deaths.date,
    TRY_CONVERT(FLOAT, deaths.population) AS Population,
	TRY_CONVERT(FLOAT, vac.new_vaccinations) AS New_vaccinations,
	SUM(TRY_CONVERT(FLOAT, vac.new_vaccinations))
        OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vac
    ON deaths.location = vac.location
    AND deaths.date = TRY_CAST(vac.date AS DATE)
WHERE deaths.continent IS NOT NULL;

SELECT *,
    (RollingPeopleVaccinated * 1.0 / NULLIF(population, 0)) * 100 AS VaccinationRate
FROM #PercentPopulationVaccinated;

--Showing all the data types in the table:
--USE PortfolioProject
--GO
--EXEC sp_help 'PortfolioProject.dbo.CovidDeaths';

--USE PortfolioProject
--GO
--EXEC sp_help 'PortfolioProject.dbo.CovidVaccinations';


--Creating View to store data fot later visualizations

Create View PercentPopulationVaccinated as
SELECT 
    deaths.continent, 
    deaths.location, 
    deaths.date,
    TRY_CONVERT(FLOAT, deaths.population) AS Population,
	TRY_CONVERT(FLOAT, vac.new_vaccinations) AS New_vaccinations,
	SUM(TRY_CONVERT(FLOAT, vac.new_vaccinations))
        OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vac
    ON deaths.location = vac.location
    AND deaths.date = TRY_CAST(vac.date AS DATE)
WHERE deaths.continent IS NOT NULL;

Select *
From PercentPopulationVaccinated