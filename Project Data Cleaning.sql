-- The aim of this Project is cleaning data in SQL Server
-- We will be using Nashville Housing data 

-- 1. Standarize column SaleData
-- We do not need a datetime format; just date will suffice

--SELECT Saledate,
--	CONVERT(date, SaleDate)
--FROM nashville

ALTER TABLE nashville
ADD Saledate_converted date

UPDATE nashville
SET Saledate_converted = CONVERT(date, SaleDate)

--SELECT Saledate,
--	CONVERT(date, SaleDate),
--	Saledate_converted
--FROM nashville

-- 2. Populate Property Address data

--SELECT a.ParcelId, a.PropertyAddress, b.ParcelId, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
--FROM nashville a
--INNER JOIN nashville b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
--WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville a
INNER JOIN nashville b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

SELECT * 
FROM nashville
WHERE PropertyAddress IS NULL

-- 3. Breaking out address into individual columns (Address, City, State)

-- 3.1. SUBSTRING

SELECT SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress)-1) AS address,
	SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress) + 2, LEN(OwnerAddress) - CHARINDEX(',', OwnerAddress) - 5) AS city,
	RIGHT(OwnerAddress, 2) AS state
FROM nashville

ALTER TABLE nashville
ADD address nvarchar(255),
	city nvarchar(255),
	state nvarchar(255)

UPDATE nashville
SET address = SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress)-1),
	city = SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress) + 2, LEN(OwnerAddress) - CHARINDEX(',', OwnerAddress) - 5),
	state = RIGHT(OwnerAddress, 2)

-- I used a very generic name for the new columns, so I ll rename:

EXEC sp_rename 'nashville.address', 'owner_address'
EXEC sp_rename 'nashville.city', 'owner_city'
EXEC sp_rename 'nashville.state', 'owner_state'

-- 3.2. PARSENAME

-- First, since PARSENAME works with dots, I replace commas with dots

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS city,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS state
FROM nashville

-- We have already populated the new Owner Address columns using the SUBSTRING method, so we work with column Property Address

SELECT PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1) AS city,
	PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2) AS address
FROM nashville

ALTER TABLE nashville
ADD property_address nvarchar(255),
	property_city nvarchar (255)

UPDATE nashville
SET property_address = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2),
	property_city = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1)

-- 4. Yes & No - column SoldAsVacant

SELECT DISTINCT(SoldASVacant),
	COUNT(SoldASVacant) AS count
FROM nashville
GROUP BY SoldASVacant
ORDER BY count

-- "Yes" and "No" are used in most cases. Therefore I will replace "Y" and "N"

UPDATE nashville
SET SoldASVacant = 
	CASE 
	WHEN SoldASVacant = 'Y' THEN 'Yes'
	WHEN SoldASVacant = 'N' THEN 'No'
	ELSE SoldASVacant
	END

-- 5. Remove duplicates

WITH Rownum AS
	(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID
				) row_num
FROM nashville
	)

--SELECT * 
--FROM Rownum
--WHERE row_num > 1

DELETE
FROM Rownum
WHERE row_num > 1

-- 6. Delete unused columns

ALTER TABLE nashville
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT *
FROM nashville


