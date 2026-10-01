drop database if exists world_layoffs;

create database world_layoffs;

use world_layoffs;

select *
from layoffs;
-- ============================================================================================================
-- ============================================================================================================
-- 1. Remove duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove any unwanted columns 

-- ============================================================================================================
-- ============================================================================================================

-- create a copy of the table you are cleaning
create table layoffs_staging
like layoffs;


-- insert into the table you created
insert layoffs_staging
select *
from layoffs;

-- ============================================================================================================
-- ============================================================================================================

-- 1. Remove duplicates
-- use row_num() to get the duplicates, 1 means unique, numbers greater than 1 means duplicates
-- if possible partition by all columns so as to be sure

select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) as row_num
from layoffs_staging;

-- create a cte, so as to be able to filter out the duplicates
with duplicate_cte as (
select *,
row_number() over(
partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

-- verify duplicates before deleting 
select *
from layoffs_staging
where company = 'Casper';

-- To delete create a copy of the table and include the row_num column so as to be able to delete duplicates easily
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

-- Insert the rows into layoffs_staging2

insert into layoffs_staging2
select *,
row_number() over(
partition by company, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) as row_num
from layoffs_staging;

-- To delete, filter where row_num > 1
-- To delete the duplicates, change 'Select *' to 'delete' 

delete
from layoffs_staging2
where row_num > 1;

-- To veerify if what you deleted is actually deleted
-- This should return empty 

select *
from layoffs_staging2
where row_num > 1;

-- ============================================================================================================
-- ============================================================================================================

-- 2. Standardizing data - means finding issues in your data and fixing it

-- Trim unnecessary spaces from your data

select 
	company, 
	trim(company)
from layoffs_staging2;

-- Update the company column

update layoffs_staging2
set company = trim(company);

-- Take a look at another column and standardize

select 
	distinct industry
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where industry like 'crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- Take a look at other columns and standardize
-- Trailing -- removes unwanted string/int at the end of a data 
select 
	distinct country, 
	trim(trailing '.' from country)
from layoffs_staging2
order by 1;

-- then update 
update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

-- check date and standardize
-- date in this table is in text format, convert to date
select
	`date`,
	str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

-- update date column

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

-- verify to see if date updated 

select `date`
from layoffs_staging2;

-- after updating, check to see if the column format has changed from text to date
-- if not alter layoffs_staging2 table and modify the column. Follow the process below and 
-- reconfirm after running the query below

alter table layoffs_staging2
modify column `date` date;


-- ============================================================================================================
-- ============================================================================================================

-- 3.  Working with Nulls and Blank values

-- Total_laid_off from the layoffs_staging2 table


select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

update layoffs_staging2
set industry = null
where industry = ''; 

select *
from layoffs_staging2
where industry is null or industry = '';

-- before removing or deleting, make sure to verify

select *
from layoffs_staging2
where company like 'bally%';

-- from the output, it can be deduced from the 2nd row that industry for 'Airbnb' is Travel
-- so it can be poplulated with empty industry rows, same should go with the rest 
-- a join should populate the data

select 
	t1.industry, 
    t2.industry
from layoffs_staging2 as t1
join layoffs_staging2 as t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '') 
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 as t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;

-- ============================================================================================================
-- ============================================================================================================

-- 4. Remove unwanted rows and columns
-- To delete unwanted rows
select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- To drop columns in a table

select *
from layoffs_staging2;

alter table layoffs_staging2
drop column row_num;
