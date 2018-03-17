Database ua_dillards;


# Exercise 1:
SELECT EXTRACT (YEAR FROM saledate) AS years, EXTRACT (MONTH FROM saledate) AS months, COUNT(DISTINCT saledate) AS num
from trnsact
GROUP BY years, months
ORDER BY years, months;

# Exercise 2:
SELECT sku, 
       SUM(CASE WHEN EXTRACT(MONTH from saledate) = 6
                THEN amt
                END) as june_sale, 
       SUM(CASE WHEN EXTRACT(MONTH from saledate) = 7
                THEN amt
                END) as july_sale, 
       SUM(CASE WHEN EXTRACT(MONTH from saledate) = 8
                THEN amt
                END) as aug_sale,
       (june_sale + july_sale + aug_sale) AS summer_sale
FROM trnsact
WHERE stype = 'P' 
group by sku
order by summer_sale desc;


# Exercise 3:
SELECT EXTRACT (YEAR FROM saledate) AS years, EXTRACT (MONTH FROM saledate) AS months, 
       store, COUNT(DISTINCT saledate) AS num
from trnsact
WHERE stype = 'P' 
GROUP BY years, months, store
ORDER BY num ASC;


# Exercise 4:
SELECT store, EXTRACT (YEAR FROM saledate) AS years, EXTRACT (MONTH FROM saledate) AS months, 
       SUM(amt) / COUNT(DISTINCT saledate) AS avg_daily_rev
from trnsact
WHERE stype = 'P' 
GROUP BY store, years, months
ORDER BY store, years, months;

SELECT store_month_year, tot_rev / num AS avg_daily_rev
FROM (SELECT store || EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS store_month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store_month_year
      HAVING num >= 20) AS cleaned_trnsact;


# Exercise 5:
SELECT CASE WHEN msa_high >= 50 AND msa_high <= 60 THEN 'low' 
            WHEN msa_high > 60 AND msa_high <= 70 THEN 'medium'
	    WHEN msa_high > 70 THEN 'high'
	    END AS edu, SUM(tot_rev) / SUM(num) AS avg_daily_rev
FROM (SELECT store || EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS store_month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev, store
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store_month_year, store
      HAVING num >= 20) AS cleaned_trnsact
JOIN store_msa
ON cleaned_trnsact.store = store_msa.store
GROUP BY edu;


# Exercise 6:
SELECT state, city, cleaned_trnsact.store, SUM(tot_rev) / SUM(num) AS avg_daily_rev, AVG(msa_income) AS income
FROM (SELECT store || EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS store_month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev, store
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store_month_year, store
      HAVING num >= 20) AS cleaned_trnsact
JOIN (SELECT TOP 5 state, city, store, msa_income
      FROM store_msa
      ORDER BY msa_income DESC) AS high_income
ON cleaned_trnsact.store = high_income.store
GROUP BY state, city, cleaned_trnsact.store;


# Exercise 7:
SELECT brand, std_sprice
FROM (SELECT top 5 sku, STDDEV_SAMP(sprice) AS std_sprice, COUNT(sku) AS num
      FROM trnsact
      WHERE stype = 'P' 
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY sku
      HAVING num >= 100
      ORDER BY std_sprice DESC) AS cleaned_trnsact
LEFT JOIN skuinfo s
ON s.sku = cleaned_trnsact.sku;


# Exercise 8:
SELECT *
FROM (SELECT top 1 sku, STDDEV_SAMP(sprice) AS std_sprice, COUNT(sku) AS num
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY sku
      HAVING num >= 100
      ORDER BY std_sprice DESC) AS cleaned_trnsact
JOIN trnsact t
ON t.sku = cleaned_trnsact.sku;


# Exercise 9:
SELECT EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS month_year,
       SUM(amt) / COUNT(DISTINCT saledate) AS avg_daily_rev
FROM trnsact
WHERE stype = 'P' 
AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
GROUP BY month_year
HAVING COUNT(DISTINCT saledate) >= 20
ORDER BY month_year;


# Exercise 10:
SELECT TOP 10 dep_rev.deptdesc, msa.city, msa.state, dep_rev.store, dep_rev.inc_ratio
FROM (SELECT store, dep.deptdesc,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  11 THEN amt END) AS nov_rev,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  12 THEN amt END) AS dec_rev,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  11 THEN saledate END) AS nov_days,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  12 THEN saledate END) AS dec_days,
             nov_rev / nov_days AS nov_daily_rev, dec_rev / dec_days AS dec_daily_rev,
             (dec_daily_rev - nov_daily_rev) / nov_daily_rev AS inc_ratio
      FROM trnsact trn
      LEFT JOIN skuinfo sku
      ON trn.sku = sku.sku
      LEFT JOIN deptinfo dep
      ON sku.dept = dep.dept
      WHERE stype = 'P'
      GROUP BY trn.store, dep.deptdesc
      HAVING nov_days >= 20 AND dec_days >= 20) AS dep_rev
LEFT JOIN store_msa msa
ON dep_rev.store = msa.store
ORDER BY dep_rev.inc_ratio DESC;


# Exercise 11:
SELECT TOP 10 sto_rev.store, msa.city, msa.state, sto_rev.inc
FROM (SELECT store,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  8 THEN amt END) AS aug_rev,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  9 THEN amt END) AS sept_rev,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  8 THEN saledate END) AS aug_days,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  9 THEN saledate END) AS sept_days,
             aug_rev / aug_days AS aug_daily_rev, sept_rev / sept_days AS sept_daily_rev,
             sept_daily_rev - aug_daily_rev AS inc
      FROM trnsact
      WHERE stype = 'P' AND EXTRACT(YEAR FROM saledate) = 2004
      GROUP BY store
      HAVING aug_days >= 20 AND sept_days >= 20) AS sto_rev
LEFT JOIN store_msa msa
ON sto_rev.store = msa.store
ORDER BY sto_rev.inc ASC;


# Exercise 12:
SELECT COUNT(CASE months WHEN 1 THEN store END) AS Jan_cnt,
       COUNT(CASE months WHEN 2 THEN store END) AS Feb_cnt,
       COUNT(CASE months WHEN 3 THEN store END) AS Mar_cnt,
       COUNT(CASE months WHEN 4 THEN store END) AS Apr_cnt,
       COUNT(CASE months WHEN 5 THEN store END) AS May_cnt,
       COUNT(CASE months WHEN 6 THEN store END) AS June_cnt,
       COUNT(CASE months WHEN 7 THEN store END) AS July_cnt,
       COUNT(CASE months WHEN 8 THEN store END) AS Aug_cnt,
       COUNT(CASE months WHEN 9 THEN store END) AS Sept_cnt,
       COUNT(CASE months WHEN 10 THEN store END) AS Oct_cnt,
       COUNT(CASE months WHEN 11 THEN store END) AS Nov_cnt,
       COUNT(CASE months WHEN 12 THEN store END) AS Dec_cnt
FROM (SELECT store, EXTRACT (MONTH FROM saledate) AS months, SUM(amt) AS month_rev,
             ROW_NUMBER() OVER (PARTITION BY store ORDER BY month_rev DESC) AS rev_rank
      FROM trnsact
      WHERE stype = 'P' 
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store, months
      HAVING COUNT(DISTINCT saledate) >= 20
      QUALIFY rev_rank = 1) AS sto_mth;

SELECT COUNT(CASE months WHEN 1 THEN store END) AS Jan_cnt,
       COUNT(CASE months WHEN 2 THEN store END) AS Feb_cnt,
       COUNT(CASE months WHEN 3 THEN store END) AS Mar_cnt,
       COUNT(CASE months WHEN 4 THEN store END) AS Apr_cnt,
       COUNT(CASE months WHEN 5 THEN store END) AS May_cnt,
       COUNT(CASE months WHEN 6 THEN store END) AS June_cnt,
       COUNT(CASE months WHEN 7 THEN store END) AS July_cnt,
       COUNT(CASE months WHEN 8 THEN store END) AS Aug_cnt,
       COUNT(CASE months WHEN 9 THEN store END) AS Sept_cnt,
       COUNT(CASE months WHEN 10 THEN store END) AS Oct_cnt,
       COUNT(CASE months WHEN 11 THEN store END) AS Nov_cnt,
       COUNT(CASE months WHEN 12 THEN store END) AS Dec_cnt
FROM (SELECT store, EXTRACT (MONTH FROM saledate) AS months, SUM(amt) / COUNT(DISTINCT saledate) AS month_daily_rev,
             ROW_NUMBER() OVER (PARTITION BY store ORDER BY month_daily_rev DESC) AS rev_rank
      FROM trnsact
      WHERE stype = 'P' 
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store, months
      HAVING COUNT(DISTINCT saledate) >= 20
      QUALIFY rev_rank = 1) AS sto_mth;