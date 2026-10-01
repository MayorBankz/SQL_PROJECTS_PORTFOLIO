-- ============================================================
-- WORLD LAYOFFS
-- EXPLORATORY DATA ANALYSIS
-- Tool: MySQL
-- ============================================================
--
-- Dataset:
-- Cleaned World Layoffs dataset
--
-- Table:
-- layoffs_staging2
--
-- Purpose:
-- Explore the cleaned dataset and identify patterns
-- trends, and key information about layoffs.
-- ============================================================


-- ============================================================
-- 1. REVIEW THE CLEANED DATA
-- ============================================================

select *
from layoffs_staging2;

-- ============================================================
-- 2. OVERALL LAYOFF FIGURES
-- ============================================================
-- Check the maximum number of employees laid off and
-- the maximum percentage of employees laid off. 

select 
	max(total_laid_off), 
    max(percentage_laid_off)
from layoffs_staging2;

-- ============================================================
-- 3. COMPANIES WITH 100% LAYOFFS
-- ============================================================
-- Identify companies where 100% of employees were laid off.

select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- View the same companies based on funds raised.

select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

-- ============================================================
-- 4. TOTAL LAYOFFS BY COMPANY
-- ============================================================
-- Calculate the total number of layoffs recorded for
-- each company.

select 
	company, 
    sum(total_laid_off) 
from layoffs_staging2
group by company
order by 2 desc;

-- ============================================================
-- 5. DATASET DATE RANGE
-- ============================================================
-- Find the earliest and latest layoff dates.

-- date range of event

select 
	min(`date`), 
    max(`date`)
from layoffs_staging2;

-- =============================================================
-- 6. TOTAL LAYOFFS BY INDUSTRY
-- ============================================================
-- Identify industries with the highest number of
-- recorded layoffs.


select 
	industry, 
    sum(total_laid_off) as total_laid_off
from layoffs_staging2
group by industry
order by 2 desc;

-- ============================================================
-- 7. TOTAL LAYOFFS BY COUNTRY
-- ============================================================
-- Identify countries with the highest number of
-- recorded layoffs.

select 
	country, 
    sum(total_laid_off) as total_laid_off
from layoffs_staging2
group by country
order by 2 desc;

-- ============================================================
-- 8. TOTAL LAYOFFS BY YEAR
-- ============================================================
-- Examine how layoffs changed from year to year.

select 
	year(`date`),
    sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 1 desc;

-- ============================================================
-- 9. TOTAL LAYOFFS BY COMPANY STAGE
-- ============================================================
-- Examine layoffs based on the company's stage.



select 
	stage,
    sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

-- ============================================================
-- 10. MONTHLY LAYOFFS
-- ============================================================
-- Extract the year and month from the date and calculate
-- the total layoffs for each month.

select 
	substr(`date`, 1, 7) as `Month`,
    sum(total_laid_off)
from layoffs_staging2
where substr(`date`, 1, 7) is not null
group by `Month`
order by 1 asc;

-- ============================================================
-- 11. ROLLING TOTAL OF LAYOFFS
-- ============================================================
-- First calculate monthly layoffs.
-- Then calculate the cumulative total over time.

with rolling_total as (
select 
	substr(`date`, 1, 7) as `Month`,
    sum(total_laid_off) as total_laidoff
from layoffs_staging2
where substr(`date`, 1, 7) is not null
group by `Month`
order by 1
)
select
	`Month`,
    total_laidoff,
    sum(total_laidoff) over(order by `Month`) as rolling_total
from rolling_total;

-- ============================================================
-- 12. TOTAL LAYOFFS BY COMPANY AND YEAR
-- ============================================================
-- Calculate how many employees each company laid off
-- in each year.

select
	company,
    year(`date`) as `Year`, 
    sum(total_laid_off) as total_laidoff
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;

-- ============================================================
-- 13. RANK COMPANIES BY LAYOFFS WITHIN EACH YEAR
-- ============================================================
-- DENSE_RANK() ranks companies separately within each year.


with company_year as (
select
	company,
    year(`date`) as `Year`, 
    sum(total_laid_off) as total_laidoff
from layoffs_staging2
group by company, year(`date`)
order by 3 desc
)
select *,
	dense_rank() over(
    partition by `year` order by total_laidoff desc
    ) as rank_laidoff
from company_year
where `year` is not null
order by rank_laidoff;

-- ============================================================
-- 14. TOP 5 COMPANIES BY LAYOFFS FOR EACH YEAR
-- ============================================================
-- First calculate total layoffs by company and year.
-- Then rank the companies.
-- Finally, return the top 5 ranks for each year.


with company_year as (
select
	company,
    year(`date`) as `Year`, 
    sum(total_laid_off) as total_laidoff
from layoffs_staging2
group by company, year(`date`)
order by 3 desc
),
company_year_rank as (
select *,
	dense_rank() over(
		partition by `year` order by total_laidoff desc
    ) as rank_laidoff
from company_year
where `year` is not null
)
select *
from company_year_rank
where rank_laidoff <= 5;

-- ============================================================
-- END OF EXPLORATORY DATA ANALYSIS
-- ============================================================

