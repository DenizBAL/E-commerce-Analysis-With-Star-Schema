-- 1. Dim_Customer (Müşteri Boyutu)
IF OBJECT_ID('Dim_Customer', 'U') IS NOT NULL DROP TABLE Dim_Customer;

CREATE TABLE Dim_Customer (
    CustomerKey INT NOT NULL PRIMARY KEY,
    CustomerID INT,
    Age INT,
    City VARCHAR(100),
    SignupDate DATE,
    CustomerSegment VARCHAR(50)
);

INSERT INTO Dim_Customer (CustomerKey, CustomerID, Age, City, SignupDate, CustomerSegment)
SELECT 
    ROW_NUMBER() OVER (ORDER BY CustomerID) AS CustomerKey,
    CustomerID,
    Age,
    City,
    SignupDate,
    CustomerSegment
FROM raw_customers;


-- 2. Dim_Product (Ürün Boyutu)
IF OBJECT_ID('Dim_Product', 'U') IS NOT NULL DROP TABLE Dim_Product;

CREATE TABLE Dim_Product (
    ProductKey INT NOT NULL PRIMARY KEY,
    ProductID INT,
    ProductName VARCHAR(150),
    Category VARCHAR(100),
    Price FLOAT
);

INSERT INTO Dim_Product (ProductKey, ProductID, ProductName, Category, Price)
SELECT 
    ROW_NUMBER() OVER (ORDER BY ProductID) AS ProductKey,
    ProductID,
    ProductName,
    Category,
    UnitPrice
FROM raw_products;


-- 3. Dim_Date (Tarih Boyutu)
IF OBJECT_ID('Dim_Date', 'U') IS NOT NULL DROP TABLE Dim_Date;

CREATE TABLE Dim_Date (
    DateKey INT NOT NULL PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Month INT,
    MonthName VARCHAR(20),
    Quarter INT,
    Day INT,
    DayOfWeek VARCHAR(20)
);

WITH DateSequence AS (
    SELECT CAST('2023-01-01' AS DATE) AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < '2026-12-31'
)
INSERT INTO Dim_Date (DateKey, FullDate, Year, Month, MonthName, Quarter, Day, DayOfWeek)
SELECT 
    CAST(CONVERT(VARCHAR(8), DateValue, 112) AS INT) AS DateKey,
    DateValue AS FullDate,
    YEAR(DateValue) AS Year,
    MONTH(DateValue) AS Month,
    DATENAME(MONTH, DateValue) AS MonthName,
    DATEPART(QUARTER, DateValue) AS Quarter,
    DAY(DateValue) AS Day,
    DATENAME(WEEKDAY, DateValue) AS DayOfWeek
FROM DateSequence
OPTION (MAXRECURSION 0);


-- 4. Fact_Sales (Olgu Tablosu)
IF OBJECT_ID('Fact_Sales', 'U') IS NOT NULL DROP TABLE Fact_Sales;

CREATE TABLE Fact_Sales (
    SalesKey INT NOT NULL PRIMARY KEY,
    OrderID INT,
    CustomerKey INT,
    ProductKey INT,
    DateKey INT,
    Quantity INT,
    UnitPrice FLOAT,
    Discount FLOAT,
    TotalRevenue FLOAT,
    PaymentMethod VARCHAR(50),
    Status VARCHAR(50)
);

INSERT INTO Fact_Sales (SalesKey, OrderID, CustomerKey, ProductKey, DateKey, Quantity, UnitPrice, Discount, TotalRevenue, PaymentMethod, Status)
SELECT 
    ROW_NUMBER() OVER (ORDER BY o.OrderID) AS SalesKey,
    o.OrderID,
    c.CustomerKey,
    p.ProductKey,
    CAST(CONVERT(VARCHAR(8), o.OrderDate, 112) AS INT) AS DateKey,
    o.Quantity,
    p.Price AS UnitPrice,
    o.Discount,
    (o.Quantity * p.Price) - o.Discount AS TotalRevenue,
    o.PaymentMethod,
    o.Status
FROM raw_orders o
LEFT JOIN Dim_Customer c ON o.CustomerID = c.CustomerID
LEFT JOIN Dim_Product p ON o.ProductID = p.ProductID;