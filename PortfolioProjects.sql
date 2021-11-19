--select * from Covideaths$
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
order  by 1,2

---looking at Total cases vs Total Deaths
-- shows likelihood of dying if you contract Covid in Nigeria
SELECT location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%Nigeria%'
order  by 1,2


----looking at Total Cases vs Population
--- shows what percentage of people got Covid

SELECT location, date, population, total_cases, 
(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
order  by 1,2

---looking at Countries with Highest infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, 
MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
group by location, population
order  by PercentPopulationInfected desc


--WE WILL BREAK THINGS DOWN BY CONTINENT

--Showing the countries with highest deathcount per population
-- cast is used to change a data type
SELECT continent, MAX(cast(total_cases as int)) as TotalDeathCount
FROM CovidDeaths
where continent is not null
group by continent
order  by TotalDeathCount desc

--showing the continent with highest death count per population

SELECT continent, MAX(cast(total_cases as int)) as TotalDeathCount
FROM CovidDeaths
where continent is not null
group by continent
order  by TotalDeathCount desc

--- GLOBAL NUMBERS
--to group by, we need to use aggregate function
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
--total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
---WHERE location like '%Nigeria%'
where continent is not null
--group by date
order  by 1,2


---Lets join the two tables together
--looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from coviddeaths as DEA
join CovidVaccinations as VAC
on DEA.location = VAC.location
and DEA.date = VAC.date
where dea.continent is not null
order by 2,3

---over and partition by
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as DEA
join CovidVaccinations as VAC
on DEA.location = VAC.location
and DEA.date = VAC.date
where dea.continent is not null
order by 2,3


--USING CTE 
with POPvsVAC (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths as DEA
join CovidVaccinations as VAC
on DEA.location = VAC.location
and DEA.date = VAC.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 from POPvsVAC

--creating TEMP TABLE
drop table if exists #PercentPopulationVaccinated

create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from coviddeaths as DEA
join CovidVaccinations as VAC
on DEA.location = VAC.location
and DEA.date = VAC.date
where dea.continent is not null


Select *, (RollingPeopleVaccinated/population)*100 from #PercentPopulationVaccinated

--CREATING VIEW AS IN VIZUALIZATION. I DID NOT KNOW THIS
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from coviddeaths as DEA
join CovidVaccinations as VAC
on DEA.location = VAC.location
and DEA.date = VAC.date
where dea.continent is not null

---A view is not a temp table, its permanent
select * from PercentPopulationVaccinated 
