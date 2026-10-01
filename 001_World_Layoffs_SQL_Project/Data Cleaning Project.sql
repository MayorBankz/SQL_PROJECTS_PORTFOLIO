-- ============================================================
-- WORLD LAYOFFS DATA CLEANING PROJECT
-- Tool: MySQL
-- Purpose: Clean and prepare the raw layoffs dataset for analysis
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

drop database if exists world_layoffs;

create database world_layoffs;

use world_layoffs;

-- Check the original raw data

select *
from layoffs;

-- ============================================================
-- DATA CLEANING STEPS
-- ============================================================
-- 1. Create a staging table
-- 2. Remove duplicate records
-- 3. Standardize the data
-- 4. Handle NULL and blank values
-- 5. Remove records with no useful layoff information
-- 6. Remove temporary columns
-- ============================================================

-- ============================================================
-- 2. CREATE STAGING TABLE
-- ============================================================
-- A staging table allows us to clean a copy of the original
-- data without changing the raw dataset.

create table layoffs_staging
like layoffs;


-- insert into the table you created
insert layoffs_staging
select *
from layoffs;

-- Check the staging table
SELECT *
FROM layoffs_staging;

-- ============================================================
-- 3. REMOVE DUPLICATES
-- ============================================================
-- ROW_NUMBER() is used to identify duplicate records.
-- row_num = 1  -> first record
-- row_num > 1  -> duplicate record

select *,
row_number() over(
	partition by company, 
				location, 
				industry, 
				total_laid_off, 
                percentage_laid_off, 
                `date`, 
				stage, 
                country, 
                funds_raised_millions
		) as row_num
from layoffs_staging;

-- ------------------------------------------------------------
-- Check which records are duplicates
-- ------------------------------------------------------------

with duplicate_cte as (
	select *,
	row_number() over(
			partition by company, 
            industry, 
            total_laid_off, 
            percentage_laid_off, 
            `date`
		) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

-- verify duplicates before deleting 
select *
from layoffs_staging
where company = 'Casper';

-- ------------------------------------------------------------
-- Create a second staging table with row_num
-- ------------------------------------------------------------
-- To delete create a copy of the table and include the row_num 
-- column so as to be able to delete duplicates easily
-- To delete, right click on the table (layoffs_staging), click on copy to clipboard, and select create statement
-- add maybe a '2' to the table name "layoffs_staging2"
-- Then run


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



-- After running, check to verify if the row_num column is added at the end of the table 

select *
from layoffs_staging2;

-- -- Insert the data and generate row numbers

insert into layoffs_staging2
select *,
row_number() over(
partition by company, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) as row_num
from layoffs_staging;

-- ------------------------------------------------------------
-- Delete duplicate records
-- ------------------------------------------------------------
-- To delete, filter where row_num > 1
-- To delete the duplicates, change 'Select *' to 'delete' 

delete
from layoffs_staging2
where row_num > 1;

-- Verify that duplicates were removed
-- This should return no records.

select *
from layoffs_staging2
where row_num > 1;

-- ============================================================
-- 4. STANDARDIZE THE DATA 
-- ============================================================
-- means finding issues in your data and fixing it
-- Trim unnecessary spaces from your data

select 
	company, 
	trim(company)
from layoffs_staging2;

-- Update the company column

update layoffs_staging2
set company = trim(company);

-- ------------------------------------------------------------
--  Standardize industry names
-- ------------------------------------------------------------
-- Check the different industry values

select 
	distinct industry
from layoffs_staging2
order by 1;

-- Check cryptocurrency-related values

select *
from layoffs_staging2
where industry like 'crypto%';

-- Standardize all Crypto variations to "Crypto"

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';
-- ------------------------------------------------------------
--  Standardize country names
-- ------------------------------------------------------------
-- Check country values and remove unnecessary periods

select 
	distinct country, 
	trim(trailing '.' from country)
from layoffs_staging2
order by 1;

-- Remove the unnecessary period from United States

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

-- ------------------------------------------------------------
--  Convert the date column from text to DATE
-- ------------------------------------------------------------
-- Check the original date and converted date

select
	`date`,
	str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

-- Convert the values

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

-- Verify the date column

select `date`
from layoffs_staging2;

-- after updating, check to see if the column format 
-- has changed from text to date
-- if not alter layoffs_staging2 table and modify the column. 
-- Follow the process below and 
-- reconfirm after running the query below

alter table layoffs_staging2
modify column `date` date;


-- ============================================================
-- 5. HANDLE NULL AND BLANK VALUES
-- ============================================================

-- Check records where layoff information is missing


select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- ------------------------------------------------------------
-- Convert blank industry values to NULL
-- ------------------------------------------------------------

update layoffs_staging2
set industry = null
where industry = ''; 

-- ------------------------------------------------------------
-- Populate missing industry values where possible
-- ------------------------------------------------------------

select *
from layoffs_staging2
where industry is null or industry = '';

-- before removing or deleting, make sure to verify

select *
from layoffs_staging2
where company like 'bally%';

-- If the same company and location has another record
-- with a known industry, use that information to fill
-- the missing value.


select 
	t1.industry, 
    t2.industry
from layoffs_staging2 as t1
join layoffs_staging2 as t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '') 
and t2.industry is not null;


-- Update the missing industry values

update layoffs_staging2 t1
join layoffs_staging2 as t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;

-- ============================================================
-- 6. REMOVE RECORDS WITH NO LAYOFF INFORMATION
-- ============================================================
-- Records where both total_laid_off and percentage_laid_off
-- are NULL do not provide useful layoff information.

-- Check the records before deleting

select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- Remove the records

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;


-- ============================================================
-- 7.  REMOVE TEMPORARY COLUMN
-- ============================================================

alter table layoffs_staging2
drop column row_num;

-- ============================================================
-- 8. FINAL DATA CHECK
-- ============================================================
-- Review the cleaned dataset.


select *
from layoffs_staging2;

-- Check the number of records

select count(*) as total_records
from layoffs_staging2;

-- Check the final columns

describe layoffs_staging2;

-- ============================================================
-- END OF DATA CLEANING PROJECT
-- ============================================================

