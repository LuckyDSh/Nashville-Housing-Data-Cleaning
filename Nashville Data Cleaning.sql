-- Tickluck
-- All rights reserved

------------------------------------
-- Date Converting (Standardize format)
BEGIN

Select Formated_SaleDate, CONVERT(Date, SaleDate) as DateFormat
From [Nashville Housing]..Nashville_Housing

Update Nashville_Housing
SET SaleDate = CAST(SaleDate AS DATE)

ALTER TABLE Nashville_Housing
ADD Formated_SaleDate Date

Update Nashville_Housing
SET Formated_SaleDate = CAST(SaleDate AS DATE)

END
------------------------------------
-- Populate Property Address Data
BEGIN

SELECT * 
FROM [Nashville Housing]..Nashville_Housing
ORDER BY ParcelID

SELECT nh1.ParcelID, nh1.PropertyAddress, temp.ParcelID, temp.PropertyAddress, ISNULL(nh1.PropertyAddress, temp.PropertyAddress)
FROM [Nashville Housing]..Nashville_Housing nh1
	JOIN [Nashville Housing]..Nashville_Housing temp
		ON nh1.ParcelID = temp.ParcelID
		AND nh1.[UniqueID] <> temp.[UniqueID]
WHERE nh1.PropertyAddress IS NULL

UPDATE nh1
SET PropertyAddress =  ISNULL(nh1.PropertyAddress, temp.PropertyAddress)
FROM [Nashville Housing]..Nashville_Housing nh1
	JOIN [Nashville Housing]..Nashville_Housing temp
		ON nh1.ParcelID = temp.ParcelID
		AND nh1.[UniqueID] <> temp.[UniqueID]
WHERE nh1.PropertyAddress IS NULL

END
------------------------------------
-- Breaking Address into (Address, City, State)
BEGIN

SELECT PropertyAddress
FROM [Nashville Housing]..Nashville_Housing

-- We say CHARINDEX(',',PropertyAddress) - 1 to get rid of comma in the resulting Address
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress,  CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM [Nashville Housing]..Nashville_Housing

 -- Apply Changes
BEGIN
ALTER TABLE Nashville_Housing
ADD PropertySplitAddress NVARCHAR(255)

Update Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1)

ALTER TABLE Nashville_Housing
ADD PropertySplitCity NVARCHAR(255)

Update Nashville_Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress,  CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress))
END

-- Resulting Table Check
SELECT *
FROM [Nashville Housing]..Nashville_Housing
--------------------------
 
 SELECT OwnerAddress
 FROM [Nashville Housing]..Nashville_Housing

 -- PARSENAME works in REVERSED order so 1 - is the last string | 3 - is the first one 
 SELECT PARSENAME(REPLACE(OwnerAddress,',','.'), 3) AS OwnerAddress,
 PARSENAME(REPLACE(OwnerAddress,',','.'), 2) AS OwnerCity,
 PARSENAME(REPLACE(OwnerAddress,',','.'), 1) AS OwnerState
 FROM [Nashville Housing]..Nashville_Housing

 -- Apply Changes 
BEGIN
ALTER TABLE Nashville_Housing
ADD OwnerSplitAddress NVARCHAR(255)

Update Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE Nashville_Housing
ADD OwnerSplitCity NVARCHAR(255)

Update Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE Nashville_Housing
ADD OwnerSplitState NVARCHAR(255)

Update Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
END

-- Resulting Table Check
SELECT *
FROM [Nashville Housing]..Nashville_Housing
--------------------------

END
------------------------------------
-- Substitude Y and N in SoldAsVacant to Yes or No
BEGIN

-- To see the Current Situation in the Table
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM [Nashville Housing]..Nashville_Housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END AS new_column
FROM [Nashville Housing]..Nashville_Housing

-- Apply Changes
UPDATE [Nashville Housing]..Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
END
------------------------------------
-- Remove Duplications
BEGIN

-- To see the Current Situation in the Table
SELECT *
FROM [Nashville Housing]..Nashville_Housing

WITH NH_with_duplicates_identified AS (
SELECT *, 
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY UniqueID
	) AS row_number

FROM [Nashville Housing]..Nashville_Housing
)

SELECT *
FROM NH_with_duplicates_identified
WHERE row_number > 1
ORDER BY PropertyAddress

-- RUN this after writing a CTE first time, to remove Duplicants
DELETE 
FROM NH_with_duplicates_identified
WHERE row_number > 1

END
------------------------------------
-- DELETE Unused Columns
-- OwnerAddress | PropertyAddress | TaxDistrict | SaleDate

BEGIN

SELECT *
FROM [Nashville Housing]..Nashville_Housing

ALTER TABLE [Nashville Housing]..Nashville_Housing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate

END
------------------------------------