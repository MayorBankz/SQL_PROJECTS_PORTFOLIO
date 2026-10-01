# World Layoffs Data Cleaning Project
# DATE: 01-10-2026

---

## 1. Project Overview

This project focuses on cleaning a raw layoffs dataset using **MySQL**.

The original dataset was provided as a CSV file and contained issues such as:

* Duplicate records
* Inconsistent text values
* Unnecessary spaces
* Inconsistent country names
* Dates stored as text
* Missing values
* Empty values
* Rows that could not provide useful information

The goal of the project was to clean and prepare the dataset so that it could be used for further analysis.

---

## 2. Project Objective

The main objective was to transform the raw layoffs data into a cleaner and more reliable dataset using SQL.

The cleaning process focused on four main areas:

1. Removing duplicate records
2. Standardizing inconsistent data
3. Handling missing and blank values
4. Removing unnecessary rows and columns

---

## 3. Dataset

The dataset contains information about companies that experienced layoffs.

The original dataset contains **2,361 rows and 9 columns**.

### Main Columns

| Column                | Description                             |
| --------------------- | --------------------------------------- |
| company               | Name of the company                     |
| location              | Location of the company                 |
| industry              | Industry of the company                 |
| total_laid_off        | Number of employees laid off            |
| percentage_laid_off   | Percentage of employees laid off        |
| date                  | Date of the layoff                      |
| stage                 | Company's funding/business stage        |
| country               | Country where the company is located    |
| funds_raised_millions | Funds raised by the company in millions |

---

## 4. Raw Data

The original CSV file was not completely clean.

For example, some columns contained missing values.

The raw dataset contained missing values in:

* `industry`
* `total_laid_off`
* `percentage_laid_off`
* `date`
* `stage`
* `funds_raised_millions`

The `date` column was also stored as text instead of a proper date.

There were also inconsistent values such as different versions of the same industry.

For example:

```text
Crypto
Crypto Currency
CryptoCurrency
```

There were also country values with unnecessary punctuation:

```text
United States.
```

instead of:

```text
United States
```

Because of these issues, the raw data needed to be cleaned before analysis.

---

# 5. Data Cleaning Process

The cleaning process was divided into four major steps.

## Step 1: Create a Staging Table

Instead of modifying the original data directly, I created a copy of the original table.

```sql
CREATE TABLE layoffs_staging
LIKE layoffs;
```

Then I copied the data into the new table:

```sql
INSERT layoffs_staging
SELECT *
FROM layoffs;
```

### Why?

This allowed me to work on a separate copy while keeping the original data unchanged.

The original table acts as a backup/reference, while the staging table is used for cleaning.

---

# 6. Removing Duplicate Records

Duplicate records can cause incorrect results during analysis.

To identify duplicates, I used the `ROW_NUMBER()` window function.

```sql
ROW_NUMBER() OVER(
    PARTITION BY company,
                 location,
                 industry,
                 total_laid_off,
                 percentage_laid_off,
                 date,
                 stage,
                 country,
                 funds_raised_millions
) AS row_num
```

The `ROW_NUMBER()` function assigns a number to each record within a group of identical records.

For example:

```text
row_num = 1
```

means the first record in the group.

```text
row_num > 1
```

means the record is a duplicate.

### Why use ROW_NUMBER()?

It allows me to identify duplicate records without immediately deleting anything.

I first checked the duplicates and then created another staging table containing the `row_num` column.

After that, duplicate records were removed:

```sql
DELETE
FROM layoffs_staging2
WHERE row_num > 1;
```

I then verified the result:

```sql
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
```

The expected result was an empty result set, meaning the duplicates had been removed.

---

# 7. Standardizing the Data

After removing duplicates, I standardized inconsistent values.

Standardization means making values consistent so that the same information is represented in the same way.

---

## 7.1 Removing Unnecessary Spaces

I used `TRIM()` to remove unnecessary spaces from company names.

```sql
UPDATE layoffs_staging2
SET company = TRIM(company);
```

### Why?

For example, these could be treated as different values by a database:

```text
Airbnb
Airbnb 
 Airbnb
```

Using `TRIM()` helps make them consistent:

```text
Airbnb
```

---

# 8. Standardizing Industry Names

I checked the different values in the `industry` column:

```sql
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
```

I found different versions of cryptocurrency-related industries, such as:

```text
Crypto
Crypto Currency
CryptoCurrency
```

I standardized values beginning with `Crypto`:

```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

### Result

Different variations were grouped under:

```text
Crypto
```

This makes future analysis more consistent.

---

# 9. Standardizing Country Names

I also checked the country column for unnecessary punctuation.

For example:

```text
United States.
```

was standardized to:

```text
United States
```

I used:

```sql
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```

### Why?

The extra period could cause the database to treat:

```text
United States
```

and

```text
United States.
```

as different values.

---

# 10. Converting the Date Column

The `date` column was originally stored as text.

For example:

```text
3/6/2023
```

I converted the text into a proper MySQL date using:

```sql
STR_TO_DATE(date, '%m/%d/%Y')
```

I then updated the column:

```sql
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y');
```

After converting the values, I changed the column type to `DATE`:

```sql
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;
```

### Why?

A proper date format makes it easier to perform date-based analysis later.

For example:

* Monthly analysis
* Yearly analysis
* Comparing dates
* Sorting by date
* Calculating time periods

---

# 11. Handling NULL and Blank Values

Missing values are common in real-world datasets.

I first checked records where both:

```text
total_laid_off
```

and

```text
percentage_laid_off
```

were missing.

```sql
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```

These records did not provide useful information about the actual layoffs.

---

# 12. Handling Missing Industry Values

I checked for empty industry values:

```sql
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';
```

Instead of immediately deleting these records, I first checked whether the industry could be obtained from another record belonging to the same company.

I used a self-join:

```sql
SELECT
    t1.industry,
    t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
```

If another record for the same company and location contained the industry, I used that information to fill the missing value.

```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
```

### Why?

I did not want to delete useful records simply because the industry was missing.

Where possible, I used existing information in the dataset to populate the missing value.

---

# 13. Removing Records With No Layoff Information

After checking the missing values, I removed records where both:

```text
total_laid_off
```

and

```text
percentage_laid_off
```

were NULL.

```sql
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```

### Why?

If both values are missing, the record does not provide information about either the number or percentage of employees laid off.

Removing these records helps keep the final dataset useful for layoffs analysis.

---

# 14. Removing the Temporary Column

The `row_num` column was only created to help identify duplicates.

It was not part of the original dataset and was no longer needed after duplicate removal.

Therefore, I removed it:

```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

---

# 15. Final Data Cleaning Workflow

The complete cleaning process can be summarized as:

```text
Raw CSV
   ↓
Import into MySQL
   ↓
Create Staging Table
   ↓
Identify Duplicates
   ↓
Remove Duplicates
   ↓
Standardize Text Values
   ↓
Clean Company Names
   ↓
Standardize Industry
   ↓
Standardize Country
   ↓
Convert Date to DATE
   ↓
Handle NULL / Blank Values
   ↓
Populate Missing Industry Where Possible
   ↓
Remove Records With No Layoff Information
   ↓
Remove Temporary Columns
   ↓
Clean Dataset
```

---

# 16. Before and After

### Before Cleaning

The raw dataset contained:

* 2,361 rows
* 9 columns
* Duplicate records
* Missing values
* Inconsistent industry names
* Country names with unnecessary punctuation
* Dates stored as text
* Records without useful layoff information

### After Cleaning

The cleaned dataset was prepared to have:

* Duplicate records removed
* Text values standardized
* Industry values made more consistent
* Country names standardized
* Dates converted to proper date format
* Missing industry values populated where possible
* Records with no layoff information removed
* Temporary cleaning columns removed

The final table is therefore more suitable for analysis.

---

# 17. SQL Concepts Used

This project helped demonstrate practical use of several SQL concepts:

### Database Management

```sql
CREATE DATABASE
DROP DATABASE
USE
```

### Table Creation

```sql
CREATE TABLE
```

### Data Insertion

```sql
INSERT INTO
```

### Data Modification

```sql
UPDATE
DELETE
ALTER TABLE
```

### Data Cleaning Functions

```sql
TRIM()
STR_TO_DATE()
```

### Conditional Filtering

```sql
WHERE
LIKE
IS NULL
```

### Window Functions

```sql
ROW_NUMBER()
```

### Common Table Expressions

```sql
WITH
```

### Joins

```sql
JOIN
```

### Data Validation

```sql
SELECT DISTINCT
```

---

# 18. Tools Used

* **MySQL** – Data cleaning and transformation
* **SQL** – Data manipulation and validation
* **CSV** – Raw dataset
* **GitHub** – Project documentation and version control

---

# 19. Project Outcome

The main outcome of this project was a cleaner and more consistent layoffs dataset.

The project demonstrates how SQL can be used to take a raw dataset and prepare it for further analysis.

The cleaning process focused on:

* Data quality
* Consistency
* Missing values
* Duplicate records
* Correct data types
* Data validation

The cleaned dataset can now be used for further analysis, visualization, or a data analytics project.

---

# 20. What I Learned

Through this project, I learned how to approach a real-world data cleaning task using SQL.

Some of the key lessons were:

1. Always keep a copy of the original data.
2. Check the data before making changes.
3. Do not immediately delete missing values.
4. Verify duplicates before deleting them.
5. Standardize inconsistent values.
6. Convert columns to the correct data type.
7. Validate the data after making changes.
8. Remove temporary columns after they are no longer needed.

This project helped me understand that data cleaning is not just about deleting bad data. It is also about **understanding the data, identifying problems, making appropriate corrections, and validating the results.**

---

## Project Structure

```text
World-Layoffs-Data-Cleaning/
│
├── raw_data/
│   └── layoffs.csv
│
├── sql/
│   └── Data Cleaning Project.sql
│
├── cleaned_data/
│   └── layoffs_cleaned.csv
│
└── README.md
```

## Conclusion

This project demonstrates a practical SQL data-cleaning workflow, starting with a raw CSV file and transforming it into a cleaner dataset that can be used for further analysis.

The main focus was not simply to remove data, but to understand the problems within the dataset and use SQL to correct them in a structured way.
