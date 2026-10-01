# World Layoffs — Exploratory Data Analysis

## 1. Project Overview

This project is a continuation of the **World Layoffs Data Cleaning Project**.

The same raw layoffs CSV file was used for this analysis. The data was first cleaned using SQL and then explored to identify patterns and trends in layoffs.

The purpose of the Exploratory Data Analysis (EDA) was to understand:

* How many people were laid off
* Which companies had the highest layoffs
* Which industries were most affected
* Which countries had the highest number of layoffs
* How layoffs changed over the years
* Which company stages were most affected
* Which companies had the highest layoffs each year
* How layoffs accumulated over time

The analysis was performed using **MySQL**.

---

# 2. Objective

The main objective of this analysis was to explore the cleaned layoffs dataset and identify important patterns that could be useful for further analysis and visualization.

The analysis focused on:

1. Overall layoffs
2. Companies with the highest layoffs
3. 100% layoffs
4. Industries affected
5. Countries affected
6. Yearly trends
7. Company stages
8. Monthly layoffs
9. Cumulative layoffs
10. Top companies by year

---

# 3. Dataset

The analysis uses the cleaned version of the World Layoffs dataset created during the data-cleaning stage.

The main columns used in the analysis were:

| Column                | Description                      |
| --------------------- | -------------------------------- |
| company               | Company name                     |
| location              | Company location                 |
| industry              | Company industry                 |
| total_laid_off        | Number of employees laid off     |
| percentage_laid_off   | Percentage of employees laid off |
| date                  | Date of the layoff               |
| stage                 | Company stage                    |
| country               | Country                          |
| funds_raised_millions | Funds raised by the company      |

---

# 4. Data Preparation

Before performing the EDA, the raw CSV data was cleaned using SQL.

The cleaning process included:

* Removing duplicate records
* Removing unnecessary spaces
* Standardizing industry names
* Standardizing country names
* Converting the date column to a proper date format
* Handling missing values
* Filling some missing industry values where possible
* Removing records where both layoff figures were missing

The cleaned table used for the EDA was:

```text
layoffs_staging2
```

This means the EDA was performed on **cleaned data rather than the original raw CSV**.

---

# 5. Exploratory Data Analysis

## 5.1 Overall Layoff Figures

The first step was to understand the maximum values for:

* Total number of employees laid off
* Percentage of employees laid off

```sql
SELECT
    MAX(total_laid_off),
    MAX(percentage_laid_off)
FROM layoffs_staging2;
```

### Purpose

This provides an initial understanding of the scale of layoffs in the dataset.

---

# 6. Companies With 100% Layoffs

The next step was to identify companies where the recorded layoff percentage was 100%.

```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;
```

The results were ordered by the total number of employees laid off.

### Purpose

This helps identify companies that reported laying off their entire workforce.

I also examined these companies based on the amount of funding they had raised:

```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
```

This provides another way of examining companies that experienced complete layoffs.

---

# 7. Companies With the Highest Total Layoffs

I grouped the data by company and calculated the total number of layoffs for each company.

```sql
SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;
```

### Purpose

This identifies the companies with the highest total number of layoffs across the dataset.

This is useful for understanding which companies contributed significantly to the total layoffs recorded.

---

# 8. Layoff Date Range

I checked the earliest and latest dates in the dataset.

```sql
SELECT
    MIN(`date`) AS start_date,
    MAX(`date`) AS end_date
FROM layoffs_staging2;
```

### Purpose

This establishes the time period covered by the dataset.

Knowing the date range is important before analyzing yearly and monthly trends.

---

# 9. Layoffs by Industry

Next, I grouped the layoffs by industry.

```sql
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;
```

### Purpose

This helps identify the industries with the highest number of recorded layoffs.

It allows the data to be viewed from an industry perspective rather than only looking at individual companies.

---

# 10. Layoffs by Country

I also grouped the data by country.

```sql
SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;
```

### Purpose

This shows how layoffs were distributed across different countries.

It can be used to identify countries with higher recorded numbers of layoffs within the dataset.

---

# 11. Layoffs by Year

To understand how layoffs changed over time, I grouped the data by year.

```sql
SELECT
    YEAR(`date`) AS year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY year DESC;
```

### Purpose

This helps identify yearly changes in the number of recorded layoffs.

---

# 12. Layoffs by Company Stage

The analysis also looked at the stage of the companies affected.

```sql
SELECT
    stage,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;
```

### Purpose

This helps understand the distribution of layoffs across different company stages.

For example, the dataset contains stages such as:

* Startup
* Series A
* Series B
* Series C
* Series D
* Series E
* Series F
* Post-IPO

---

# 13. Monthly Layoffs

To understand the monthly trend, I extracted the year and month from the date.

```sql
SELECT
    SUBSTR(`date`, 1, 7) AS month,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTR(`date`, 1, 7) IS NOT NULL
GROUP BY month
ORDER BY month;
```

### Purpose

This allows layoffs to be viewed month by month rather than only by year.

This can help identify periods when layoffs increased or decreased.

---

# 14. Rolling Total of Layoffs

I then calculated a cumulative or rolling total of layoffs over time.

First, I calculated the total layoffs for each month.

```sql
WITH monthly_layoffs AS (
    SELECT
        SUBSTR(`date`, 1, 7) AS month,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    WHERE SUBSTR(`date`, 1, 7) IS NOT NULL
    GROUP BY month
)

SELECT
    month,
    total_laid_off,
    SUM(total_laid_off) OVER (
        ORDER BY month
    ) AS rolling_total
FROM monthly_layoffs;
```

### Purpose

The rolling total shows how the total number of layoffs accumulated over time.

For example:

```text
Month       Monthly Layoffs    Rolling Total
2020-01        500               500
2020-02        300               800
2020-03        700              1500
```

The rolling total keeps accumulating as the months progress.

---

# 15. Layoffs by Company and Year

I also examined how many employees each company laid off in each year.

```sql
SELECT
    company,
    YEAR(`date`) AS year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;
```

### Purpose

This provides a more detailed view of company layoffs over time.

Instead of looking only at the total layoffs for a company, it shows the layoffs for each company in each year.

---

# 16. Ranking Companies by Year

To identify the companies with the highest layoffs in each year, I used the `DENSE_RANK()` window function.

```sql
WITH company_year AS (
    SELECT
        company,
        YEAR(`date`) AS year,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
)

SELECT
    *,
    DENSE_RANK() OVER (
        PARTITION BY year
        ORDER BY total_laid_off DESC
    ) AS rank_laid_off
FROM company_year
WHERE year IS NOT NULL
ORDER BY year, rank_laid_off;
```

### Why use DENSE_RANK()?

`DENSE_RANK()` assigns a ranking to companies within each year.

For example:

```text
Company A     10,000 layoffs     Rank 1
Company B      8,000 layoffs     Rank 2
Company C      8,000 layoffs     Rank 2
Company D      5,000 layoffs     Rank 3
```

Companies with the same number of layoffs receive the same rank.

---

# 17. Top 5 Companies by Year

Finally, I filtered the ranking to show the top five ranked companies for each year.

```sql
WITH company_year AS (
    SELECT
        company,
        YEAR(`date`) AS year,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),

company_year_rank AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY year
            ORDER BY total_laid_off DESC
        ) AS rank_laid_off
    FROM company_year
    WHERE year IS NOT NULL
)

SELECT *
FROM company_year_rank
WHERE rank_laid_off <= 5
ORDER BY year, rank_laid_off;
```

### Purpose

This provides a yearly view of the companies with the highest recorded layoffs.

This analysis is useful for identifying the major contributors to layoffs in each year.

---

# 18. Key Analysis Areas

The EDA can be summarized into the following areas:

| Analysis         | Question Answered                                                   |
| ---------------- | ------------------------------------------------------------------- |
| Overall layoffs  | How large were the recorded layoffs?                                |
| 100% layoffs     | Which companies reported laying off their entire workforce?         |
| Company analysis | Which companies had the highest total layoffs?                      |
| Date range       | What period does the dataset cover?                                 |
| Industry         | Which industries recorded the most layoffs?                         |
| Country          | Which countries recorded the most layoffs?                          |
| Yearly analysis  | How did layoffs change by year?                                     |
| Company stage    | Which company stages recorded the most layoffs?                     |
| Monthly analysis | How did layoffs change month by month?                              |
| Rolling total    | How did layoffs accumulate over time?                               |
| Company/year     | How many layoffs did companies record each year?                    |
| Ranking          | Which companies ranked highest by layoffs each year?                |
| Top 5            | Which companies were among the top five ranked companies each year? |

---

# 19. SQL Concepts Used

This analysis demonstrates practical use of:

### Aggregate Functions

```sql
MAX()
MIN()
SUM()
```

Used to calculate totals, minimums and maximums.

### GROUP BY

Used to group the data by:

* Company
* Industry
* Country
* Year
* Stage
* Month

### ORDER BY

Used to sort results from highest to lowest or chronologically.

### Common Table Expressions

```sql
WITH
```

Used to break more complex queries into smaller and easier-to-understand steps.

### Window Functions

```sql
SUM() OVER()
DENSE_RANK() OVER()
```

Used for:

* Rolling totals
* Ranking companies within each year

### Date Functions

```sql
YEAR()
MIN()
MAX()
```

Used to analyze the time dimension of the dataset.

### String Function

```sql
SUBSTR()
```

Used to extract the year and month portion of the date.

---

# 20. Project Workflow

The overall project followed this process:

```text
Raw CSV
   ↓
Data Cleaning
   ↓
Cleaned Dataset
   ↓
Exploratory Data Analysis
   ↓
Identify Patterns and Trends
   ↓
Prepare Data for Further Analysis / Visualization
```

The **data cleaning stage** focused on improving data quality.

The **EDA stage** focused on understanding what the cleaned data was telling us.

---

# 21. Project Outcome

The EDA provided different views of the layoffs dataset by:

* Company
* Industry
* Country
* Year
* Month
* Company stage

It also demonstrated how SQL can be used to move from simple summaries to more advanced analysis using:

* CTEs
* Window functions
* Ranking
* Rolling totals
* Date-based analysis

The analysis provides a foundation for creating visualizations and extracting further business insights from the cleaned dataset.

---

# 22. What I Learned

Through this EDA project, I learned how to use SQL to explore a cleaned dataset and identify meaningful patterns.

The main lessons were:

1. Start with simple questions before moving to advanced analysis.
2. Use aggregation to summarize large datasets.
3. Group data by different dimensions to understand patterns.
4. Use dates to analyze changes over time.
5. Use CTEs to make complex queries easier to understand.
6. Use window functions for rolling totals and rankings.
7. Always organize analysis around clear questions.

This project helped me move from simply cleaning data to **using SQL to understand the data and answer analytical questions.**
