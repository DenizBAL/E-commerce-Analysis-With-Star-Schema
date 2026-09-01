-- Veri düzenleme ve dönüştürme
UPDATE raw_customers
SET Age = ROUND(CAST(Age AS FLOAT), 0)
WHERE Age IS NOT NULL;

UPDATE raw_orders
SET Quantity = ROUND(CAST(Quantity AS FLOAT), 0)
WHERE Quantity IS NOT NULL;

UPDATE raw_orders
SET Quantity = 1
WHERE Quantity IS NULL OR Quantity <= 0;

UPDATE raw_customers
SET Age = Age / 10
WHERE Age IS NOT NULL;

UPDATE raw_orders
SET Quantity = Quantity / 10
WHERE Quantity IS NOT NULL;

------------------------------------------------ NULL DEĞER BULMA VE DOLDURMA--------------------------------------------------
-- Dinamik T-SQL Null bulma kod bloğu kullanılmıştır.
-- Null değer tespiti ve Doldurma işlemleri ile PowerBL programında dashboard oluşturma sırasında sorun çıkmaması ve hesaplamaların tam olması amaçlandı.

-- raw_customers için Null değer tespiti.
DECLARE @TableName NVARCHAR(255) = 'raw_customers';
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM ' + @TableName + ' WHERE ';

SELECT @SQL = @SQL + COLUMN_NAME + ' IS NULL OR '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName;
SET @SQL = LEFT(@SQL, LEN(@SQL) - 3);
EXEC sp_executesql @SQL;

-------------------------------Age (Yaş) NULL olanları ortalama yaş ile doldurma (IMPUTATION) işlemi .
DECLARE @AvgAge INT;
SELECT @AvgAge = ROUND(AVG(CAST(Age AS FLOAT)), 0) FROM raw_customers WHERE Age IS NOT NULL;

UPDATE raw_customers
SET Age = @AvgAge
WHERE Age IS NULL;

---------------------------------City (Şehir) NULL olanları 'Unknown' olarak güncelleme işlemi.
UPDATE raw_customers
SET City = 'Unknown'
WHERE City IS NULL OR TRIM(City) = '';



-------------------------------- raw_orders için Null değer tespiti.
DECLARE @TableName NVARCHAR(255) = 'raw_orders';
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM ' + @TableName + ' WHERE ';

SELECT @SQL = @SQL + COLUMN_NAME + ' IS NULL OR '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName;
SET @SQL = LEFT(@SQL, LEN(@SQL) - 3);
EXEC sp_executesql @SQL;

-- Discount NULL olanlara 0 (indirim yok) yazıyoruz
UPDATE raw_orders
SET Discount = 0
WHERE Discount IS NULL;

-- PaymentMethod NULL olanları 'Unknown' yapıyoruz
UPDATE raw_orders
SET PaymentMethod = 'Unknown'
WHERE PaymentMethod IS NULL OR TRIM(PaymentMethod) = '';

-- OrderDate NULL olan kayıtları sipariş analizlerini bozmaması için silebiliriz
-- (veya geçmiş sabit bir tarih atanabilir, ancak tarih yoksa Fact_Sales tablosunda eksik veri kalır)
DELETE FROM raw_orders
WHERE OrderDate IS NULL;



--------------------------- raw_payments için Null değer tespiti.
DECLARE @TableName NVARCHAR(255) = 'raw_payments';
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM ' + @TableName + ' WHERE ';

SELECT @SQL = @SQL + COLUMN_NAME + ' IS NULL OR '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName;
SET @SQL = LEFT(@SQL, LEN(@SQL) - 3);
EXEC sp_executesql @SQL;

--  Gerçekten PaymentDate'i NULL olan kayıt var mı?
SELECT COUNT(*) FROM raw_payments WHERE PaymentDate IS NULL;
--35 tane Yetim (Orphaned) Kayıt var . raw_orders tablosunda karşılığı olmayan bu 35 ödeme kaydını siliyoruz:
DELETE FROM raw_payments
WHERE PaymentDate IS NULL 
  AND OrderID NOT IN (SELECT OrderID FROM raw_orders WHERE OrderID IS NOT NULL);


  --------------------------- raw_products için Null değer tespiti.
DECLARE @TableName NVARCHAR(255) = 'raw_products';
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM ' + @TableName + ' WHERE ';

SELECT @SQL = @SQL + COLUMN_NAME + ' IS NULL OR '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName;
SET @SQL = LEFT(@SQL, LEN(@SQL) - 3);
EXEC sp_executesql @SQL;
-- Products yani ürünlerde herhangi bir null değer yoktur.