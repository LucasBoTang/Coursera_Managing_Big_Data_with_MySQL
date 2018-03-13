Database ua_dillards;

# Q3: On what day was Dillard’s income based on total sum of purchases the greatest
SELECT TOP 5 saledate, SUM(amt) AS income
FROM trnsact
GROUP BY saledate
ORDER BY income DESC;


# Q4: What is the deptdesc of the departments that have the top 3 greatest numbers of skus from the skuinfo table associated with them?
SELECT TOP 3 dep.deptdesc, COUNT(sku.sku) AS num
FROM skuinfo sku
LEFT JOIN deptinfo dep
ON sku.dept = dep.dept
GROUP BY dep.deptdesc
ORDER BY num DESC;


# Q5: Which table contains the most distinct sku numbers?
SELECT COUNT(DISTINCT sku)
FROM deptinfo;
SELECT COUNT(DISTINCT sku)
FROM trnsact;
SELECT COUNT(DISTINCT sku)
FROM skstinfo;
SELECT COUNT(DISTINCT sku)
FROM skuinfo;

# Q6: How many skus are in the skstinfo table, but NOT in the skuinfo table?
SELECT COUNT(sks.sku)
FROM skstinfo sks
LEFT JOIN skuinfo sku
ON sks.sku = sku.sku
WHERE sku.sku IS NULL;

# Q7: What is the average amount of profit Dillard’s made per day?
SELECT SUM(amt-(cost*quantity))/ COUNT(DISTINCT saledate) AS avg_sales
FROM trnsact trn
JOIN skstinfo sks
ON trn.sku=sks.sku AND trn.store=sks.store
WHERE stype='P';

# Q8:  how many MSAs are there within the state of North Carolina (abbreviated “NC”), 
# and within these MSAs, what is the lowest population level (msa_pop) and highest income level (msa_income)?
SELECT str.state, sto.msa, sto.msa_pop, sto.msa_income
FROM STORE_MSA sto
JOIN STRINFO str
ON sto.store = str.store
WHERE str.state = 'NC'
ORDER BY sto.msa_pop DESC;


# Q9 What department (with department description), brand, style, and color brought in the greatest total amount of sales?
SELECT TOP 10 dep.deptdesc, sku.brand, sku.style, sku.color, SUM(trn.amt) AS total_amount
FROM trnsact trn
JOIN skuinfo sku
ON trn.sku=sku.sku
JOIN deptinfo dep
ON sku.dept=dep.dept
GROUP BY dep.deptdesc, sku.brand, sku.style, sku.color
ORDER BY total_amount DESC;

# Q10 How many stores have more than 180,000 distinct skus associated with them in the skstinfo table?
SELECT store, COUNT(DISTINCT sku)
FROM skstinfo
GROUP BY store
HAVING COUNT(DISTINCT sku)> 180000;

# Q11 In which columns do these skus have different values from one another, meaning that their features differ in the categories represented by the columns? Choose all that apply. 
SELECT sku.style, sku.size, sku.vendor, sku.packsize
FROM skuinfo sku
JOIN deptinfo dep
ON sku.dept = dep.dept
WHERE dep.deptdesc = 'COP' AND sku.brand = 'federal' AND sku.color = 'rinse wash';

# Q12 How many skus are in the skuinfo table, but NOT in the skstinfo table?
SELECT COUNT(DISTINCT sku.sku)
FROM skuinfo sku
LEFT JOIN skstinfo sks
ON sku.sku = sks.sku
WHERE sks.sku IS NULL;

# Q13 In what city and state is the store that had the greatest total sum of sales?
SELECT TOP 5 str.store, str.city, str.state, SUM(amt) AS tot_sales
FROM trnsact trn JOIN strinfo str 
ON trn.store = str.store
GROUP BY str.store, str.city, str.state
ORDER BY tot_sales DESC


# Q15: How many states have more than 10 Dillards stores in them?
SELECT COUNT(DISTINCT state),
FROM strinfo
GROUP BY state
HAVING COUNT(DISTINCT store) > 10

# Q16: What is the suggested retail price of all the skus in the “reebok” department with the “skechers” brand and a “wht/saphire” color?
SELECT DISTINCT sku.sku, sku.dept, sku.color, dep.deptdesc, sks.retail
FROM skuinfo sku
JOIN deptinfo dep
ON sku.dept= dep.dept
JOIN skstinfo sks
ON sku.sku=sks.sku
WHERE dep.deptdesc='reebok' AND sku.brand='skechers' AND sku.color='wht/saphire';