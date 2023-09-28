
--1) Standardize date format

SELECT SaleDateConverted, CONVERT (date, SaleDate)
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT (date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT (date , SaleDate)

----------------

--2) Property Address

SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL (a.PropertyAddress, b.PropertyAddress)      -- if Property address is null, populate it w/ property address b 
FROM PortfolioProject..NashvilleHousing AS a																			-- joinself the table to check if two similar parcel IDs have the same property address
JOIN PortfolioProject..NashvilleHousing AS b             
	ON a.ParcelID = b.ParcelID																							-- if Parcel ID are the same with different unique ID, display them in a table to check what parcel IDs have null property addresses 
	AND a.[UniqueID ] <> b.[UniqueID ]                         
WHERE a.PropertyAddress is NULL																							--Display Parcel IDs with null property addresses 

UPDATE a																												-- Update Table a 
SET PropertyAddress = ISNULL (a.PropertyAddress, b.PropertyAddress)														-- in property address of table a, replace the null values by the property addresses of table b 
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b             
	ON a.ParcelID = b.ParcelID                                 
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE a.PropertyAddress is NULL

----------------

--3) Breaking out address into individual columns (Adress, City, State)
--3-a) Property address

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,									            -- starting position is the first position and going until the position before the comma
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1 , LEN(PropertyAddress)) AS Address                          -- starting position is one position after the comma and going until the end of the string 
FROM PortfolioProject..NashvilleHousing																	   		        -- charindex gives the position of a requested value, here the comma


ALTER TABLE NashvilleHousing                                                                                            -- creates a new column in the original table
ADD Property_Split_Address nvarchar(255)

UPDATE NashvilleHousing																	            	                -- adds the values to the created column
SET Property_Split_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD Property_Split_City nvarchar(255)

UPDATE NashvilleHousing
SET Property_Split_City = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1 , len (PropertyAddress))	


--3-b) Owner Address
--1st method (complex)

SELECT 
SUBSTRING(OwnerAddress, 1, CHARINDEX(',',OwnerAddress)-1),
SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress) + 1, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - CHARINDEX(',', OwnerAddress) - 1),
SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) + 1, LEN(OwnerAddress))                     
FROM PortfolioProject..NashvilleHousing		


--2nd method (simpler)

SELECT
PARSENAME(REPLACE (OwnerAddress,',','.'),3),                                                         --Parsename looks for periods and not comma
PARSENAME(REPLACE (OwnerAddress,',','.'),2),  
PARSENAME(REPLACE (OwnerAddress,',','.'),1)  
FROM PortfolioProject..NashvilleHousing                                                              --Repalce commas with periods 

ALTER TABLE NashvilleHousing      
ADD Owner_Split_Address nvarchar(255)

UPDATE NashvilleHousing  
SET Owner_Split_Address = PARSENAME(REPLACE (OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing      
ADD Owner_Split_City nvarchar(255)

UPDATE NashvilleHousing  
SET Owner_Split_City = PARSENAME(REPLACE (OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing      
ADD Owner_Split_State nvarchar(255)

UPDATE NashvilleHousing  
SET Owner_Split_State = PARSENAME(REPLACE (OwnerAddress,',','.'),1)

----------------

--4) Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)  AS Count                                   -- use distinct to see if they are using other connotations than yes or no 
FROM PortfolioProject..NashvilleHousing                                                         -- use count to see how many of each connotations there are 
GROUP BY SoldAsVacant
ORDER BY Count

SELECT SoldAsVacant, 
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
	    WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsvacant
	END
FROM PortfolioProject..NashvilleHousing    


UPDATE NashvilleHousing
SET SoldAsvacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsvacant
			       END

----------------

--5) Remove Duplicates

WITH RowNumCTE AS (
SELECT *, 
ROW_NUMBER () OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM PortfolioProject..NashvilleHousing   
)

SELECT *                         -- replace select * by delete, run it, and replace it again by select *
FROM RowNumCTE
WHERE row_num > 1 
ORDER BY PropertyAddress

----------------

--6) Delete Unused Columns

SELECT *
FROM PortfolioProject..NashvilleHousing   

ALTER TABLE  NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE  NashvilleHousing
DROP COLUMN SaleDate