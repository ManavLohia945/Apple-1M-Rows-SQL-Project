SELECT * FROM SALES;
SELECT * FROM CATEGORY;
SELECT * FROM PRODUCTS;
SELECT * FROM STORES;
SELECT * FROM WARRANTY;

--INDEXING MOST USED COLUMNS TO IMRPOVE QUERY PERFORMANCE (Parallel Scanning VS B-tree Scanning)
-- So by default SQL creates a B-Tree for the indexed column which reduces the traversal time from O(n) to O(log n) 
CREATE INDEX sales_product_id ON SALES(product_id);
CREATE INDEX sales_sale_id ON SALES(sale_id);
CREATE INDEX sales_date ON SALES(sale_date);

EXPLAIN ANALYZE
SELECT * FROM SALES WHERE product_id = 'P-44';