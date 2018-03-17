Database ua_dillards;


# Q2: How many distinct skus have the brand “Polo fas”, and are either size “XXL” or “black” in color?
SELECT COUNT(DISTINCT sku)
FROM skuinfo
WHERE brand = 'polo fas' AND (color = 'black' OR size = 'XXL');


# Q3: There was one store in the database which had only 11 days in one of its months. In what city and state was this store located?
SELECT trn.store_month_year, sto.city, sto.state
FROM (SELECT store || EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS store_month_year, store
      FROM trnsact
      GROUP BY store_month_year, store
      HAVING COUNT(DISTINCT saledate) = 11) AS trn
LEFT JOIN store_msa sto
ON trn.store = sto.store;


# Q4: Which sku number had the greatest increase in total sales revenue from November to December?
SELECT TOP 3 sku,
       SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  11 THEN amt END) AS nov_rev,
       SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  12 THEN amt END) AS dec_rev,
       dec_rev - nov_rev AS inc
FROM trnsact
WHERE stype = 'P'
GROUP BY sku
HAVING COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  11 THEN saledate END) > 20
       AND COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  12 THEN saledate END) > 20
ORDER BY inc DESC;


# Q5: What vendor has the greatest number of distinct skus in the transaction table that do not exist in the skstinfo table? 
SELECT TOP 10 vendor, COUNT(DISTINCT trn.sku) AS num
FROM trnsact trn
JOIN skuinfo sku
ON trn.sku = sku.sku
WHERE trn.sku NOT IN (SELECT sku
                      FROM skstinfo)
GROUP BY sku.vendor
ORDER BY num DESC;


# Q6: What is the brand of the sku with the greatest standard deviation in sprice? 
SELECT TOP 10 trn.sku, sku.brand, STDDEV_SAMP(sprice) AS std_sprice
SELECT TOP 10 trn.sku, sku.brand, STDDEV_SAMP(sprice) AS std_sprice
FROM trnsact trn
JOIN skuinfo sku
ON trn.sku = sku.sku
WHERE stype = 'P'
      AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
GROUP BY sku.brand, trn.sku
HAVING COUNT(trn.sku) > 100
ORDER BY std_sprice DESC;


# Q7: What is the city and state of the store which had the greatest increase in average daily revenue from November to December?
SELECT TOP 10 sto_rev.store, msa.city, msa.state, sto_rev.inc
FROM (SELECT store,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  11 THEN amt END) AS nov_rev,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  12 THEN amt END) AS dec_rev,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  11 THEN saledate END) AS nov_days,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  12 THEN saledate END) AS dec_days,
             nov_rev / nov_days AS nov_daily_rev, dec_rev / dec_days AS dec_daily_rev,
             dec_daily_rev - nov_daily_rev AS inc
      FROM trnsact
      WHERE stype = 'P' AND EXTRACT(YEAR FROM saledate) = 2004
      GROUP BY store
      HAVING nov_days >= 20 AND dec_days >= 20) AS sto_rev
LEFT JOIN store_msa msa
ON sto_rev.store = msa.store;
ORDER BY sto_rev.inc DESC;


# Q8: Compare the average daily revenue of the store with the highest msa_income and the store with the lowest median msa_income. In what city and state were these two stores, and which store had a higher average daily revenue?
SELECT state, city, cleaned_trnsact.store, SUM(tot_rev) / SUM(num) AS avg_daily_rev, AVG(msa_income) AS income
FROM (SELECT store || EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS store_month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev, store
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store_month_year, store
      HAVING num >= 20) AS cleaned_trnsact
JOIN (SELECT TOP 1 state, city, store, msa_income
      FROM store_msa
      ORDER BY msa_income DESC) AS high_income
ON cleaned_trnsact.store = high_income.store
GROUP BY state, city, cleaned_trnsact.store;

SELECT state, city, cleaned_trnsact.store, SUM(tot_rev) / SUM(num) AS avg_daily_rev, AVG(msa_income) AS income
FROM (SELECT store || EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS store_month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev, store
      FROM trnsact
      WHERE stype = 'P' 
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store_month_year, store
      HAVING num >= 20) AS cleaned_trnsact
JOIN (SELECT TOP 1 state, city, store, msa_income
      FROM store_msa
      ORDER BY msa_income ASC) AS low_income
ON cleaned_trnsact.store = low_income.store
GROUP BY state, city, cleaned_trnsact.store;


# Q9: Divide the msa_income groups. And Which of these groups has the highest average daily revenue per store?
SELECT SUM(tot_rev) / SUM(num) AS avg_daily_rev,
       CASE WHEN msa.msa_income >= 1 and msa.msa_income <= 20000 THEN 'low'
            WHEN msa.msa_income >= 20001 and msa.msa_income <= 30000 THEN 'med-low'
            WHEN msa.msa_income >= 30001 and msa.msa_income <= 40000 THEN 'med-high'
            WHEN msa.msa_income >= 40001 and msa.msa_income <= 60000 THEN 'high' 
       END AS income_level
FROM (SELECT store, EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(month_year, ' ', '') not like '%82005'
      GROUP BY store, month_year
      HAVING num >= 20) AS cleaned_trn
JOIN store_msa msa
ON cleaned_trn.store = msa.store
GROUP BY income_level
ORDER BY avg_daily_rev DESC;


# Q10: Divide stores up so that stores with msa populations, What is the average daily revenue for a store in a “very large” population msa?
SELECT SUM(tot_rev) / SUM(num) AS avg_daily_rev,
       CASE WHEN msa.msa_pop >= 1 and msa.msa_pop <= 100000 THEN 'very small'
            WHEN msa.msa_pop >= 100001 and msa.msa_pop <= 200000 THEN 'small' 
            WHEN msa.msa_pop >= 200001 and msa.msa_pop <= 500000 THEN 'med_small' 
            WHEN msa.msa_pop >= 500001 and msa.msa_pop <= 1000000 THEN 'med_large' 
            WHEN msa.msa_pop >= 1000001 and msa.msa_pop <= 5000000 THEN 'large' 
            WHEN msa.msa_pop >= 5000001 THEN 'very large' 
       END AS pop_level
FROM (SELECT store, EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate) AS month_year,
             COUNT(DISTINCT saledate) AS num, SUM(amt) AS tot_rev
      FROM trnsact
      WHERE stype = 'P'
            AND OREPLACE(month_year, ' ', '') not like '%82005'
      GROUP BY store, month_year
      HAVING num >= 20) AS cleaned_trn
JOIN store_msa msa
ON cleaned_trn.store = msa.store
GROUP BY pop_level;

# Q11: Which department in which store had the greatest percent increase in average daily sales revenue from November to December, and what city and state was that store located in? 
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
      HAVING nov_days >= 20 AND dec_days >= 20 AND nov_rev + dec_rev >= 1000) AS dep_rev
LEFT JOIN store_msa msa
ON dep_rev.store = msa.store
ORDER BY dep_rev.inc_ratio DESC;


# Q12: Which department within a particular store had the greatest decrease in average daily sales revenue from August to September, and in what city and state was that store located?
SELECT TOP 10 dep_rev.deptdesc, msa.city, msa.state, dep_rev.store, dep_rev.inc
FROM (SELECT store, dep.deptdesc,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  8 THEN amt END) AS aug_rev,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  9 THEN amt END) AS sept_rev,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  8 THEN saledate END) AS aug_days,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  9 THEN saledate END) AS sept_days,
             aug_rev / aug_days AS aug_daily_rev, sept_rev / sept_days AS sept_daily_rev,
             sept_daily_rev - aug_daily_rev AS inc
      FROM trnsact trn
      LEFT JOIN skuinfo sku
      ON trn.sku = sku.sku
      LEFT JOIN deptinfo dep
      ON sku.dept = dep.dept
      WHERE stype = 'P' AND EXTRACT(YEAR FROM saledate) = 2004
      GROUP BY store, dep.deptdesc
      HAVING aug_days >= 20 AND sept_days >= 20) AS dep_rev
LEFT JOIN store_msa msa
ON dep_rev.store = msa.store
ORDER BY dep_rev.inc ASC;


# Q13: dentify which department, in which city and state of what store, had the greatest DECREASE in the number of items sold from August to September. How many fewer items did that department sell in September compared to August?
SELECT TOP 10 dep_quant.deptdesc, msa.city, msa.state, dep_quant.store, inc_quant
FROM (SELECT store, dep.deptdesc,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  8 THEN quantity END) AS aug_quant,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate) =  9 THEN quantity END) AS sept_quant,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  8 THEN saledate END) AS aug_days,
             COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM saledate) =  9 THEN saledate END) AS sept_days,
             sept_quant - aug_quant AS inc_quant
      FROM trnsact trn
      LEFT JOIN skuinfo sku
      ON trn.sku = sku.sku
      LEFT JOIN deptinfo dep
      ON sku.dept = dep.dept
      WHERE stype = 'P' AND EXTRACT(YEAR FROM saledate) = 2004
      GROUP BY store, dep.deptdesc
      HAVING aug_days >= 20 AND sept_days >= 20) AS dep_quant
LEFT JOIN store_msa msa
ON dep_quant.store = msa.store
ORDER BY dep_quant.inc_quant ASC;


# Q14: During which month(s) did over 100 stores have their minimum average daily revenue?
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
      QUALIFY rev_rank = 12) AS sto_mth;

# Q15: During which month did the greatest number of stores have their maximum number of sku units returned?
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
      WHERE stype = 'R' 
            AND OREPLACE(EXTRACT (MONTH FROM saledate) || EXTRACT (YEAR FROM saledate), ' ', '') not like '%82005'
      GROUP BY store, months
      HAVING COUNT(DISTINCT saledate) >= 20
      QUALIFY rev_rank = 1) AS sto_mth;