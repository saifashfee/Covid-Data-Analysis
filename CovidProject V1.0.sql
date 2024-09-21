SELECT *
FROM CovidDeaths
ORDER BY 3, 4

SELECT *
FROM CovidVaccinations
ORDER BY 3, 4


--GLOBAL NUMBERS 
SELECT SUM(new_cases) AS [Total Cases], SUM(CAST(new_deaths AS int )) AS [Total Deaths], CAST(SUM(new_deaths)/SUM(new_cases)*100 AS decimal(10,4)) AS [Death Percent]
FROM CovidDeaths
WHERE continent IS NOT NULL


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
Where location = 'India'
ORDER BY 1,2

--Total cases vs total deaths
--Showing likelihood of death by COVID
WITH CovidSummary AS (
    SELECT location,
           MAX(total_cases) AS max_cases,
           MAX(total_deaths) AS max_deaths,
           MAX(population) AS population
    FROM CovidDeaths
    GROUP BY location
)
SELECT location,
       max_cases AS [Total Cases],
       max_deaths AS [Total Deaths],
       population AS [Population],
       (max_deaths/max_cases)* 100 AS [Death Percent]
FROM CovidSummary
ORDER BY [Death Percent] DESC;


--Total Cases vs population
--Percent of population got covid
SELECT TOP 10 location, MAX(total_cases) AS [Total Cases], MAX(population) AS [Population], MAX((total_cases/population)*100) AS [Affected Percentage]
FROM CovidDeaths
GROUP BY location
ORDER BY [Affected Percentage] DESC


--looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS [Highest Infection Count], MAX(total_cases/population)*100 AS [Affected Percentage]
FROM CovidDeaths
GROUP BY location, population
ORDER BY [Affected Percentage] DESC


--showing countries with highest deathcount per population
SELECT TOP 10 location, MAX(population) AS [Population], MAX(total_deaths) AS [Total Death Count], CAST(MAX((total_deaths/population)*100) AS decimal(10,4)) AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY [Death Percentage] DESC


--COMPARE THE CONTINENTS 
SELECT location, MAX(CAST(total_deaths AS int )) AS [Total Death Count]
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY [Total Death Count] DESC


--Inter Table Relation
--Cumulatie Vaccinations
SELECT Death.continent, Death.location, Death.date, Death.population, Vaxx.new_vaccinations,
SUM(CONVERT(bigint, Vaxx.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS [Cumulative Vaccinations]
FROM CovidDeaths Death
JOIN CovidVaccinations Vaxx
    ON Death.location = Vaxx.location
	AND Death.date = Vaxx.date
	WHERE Death.continent IS NOT NULL



--Using CTE

WITH [Population vs Vaccination](continent, location, Date, Population, new_vaccinations, RollingVacPeople)
AS 
(
SELECT Death.continent, Death.location, Death.date, Death.population, Vaxx.new_vaccinations,
SUM(CONVERT(bigint, Vaxx.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS RollingVacPeople
FROM CovidDeaths Death
JOIN CovidVaccinations Vaxx
    ON Death.location = Vaxx.location
	AND Death.date = Vaxx.date
	WHERE Death.continent is not null
	--order by 2,3 
)
SELECT*, (RollingVacPeople/Population)*100
FROM [Population vs Vaccination]


--Using TempTable

DROP TABLE IF EXISTS #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric, 
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
    on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select*, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated
Where Location = 'India'


--Creating view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT Death.continent, Death.location, Death.date, Death.population, Vaxx.new_vaccinations,
SUM(CONVERT(bigint, Vaxx.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location,
Death.date) AS RollingPeopleVaccinated
FROM CovidDeaths Death
JOIN CovidVaccinations Vaxx
    ON Death.location = Vaxx.location
	and Death.date = Vaxx.date
WHERE Death.continent is not null

SELECT *
FROM PercentPopulationVaccinated;


--Highest death count country
SELECT TOP 10 location, MAX(population), MAX(total_deaths) AS [Death Count]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY [Death Count] DESC
