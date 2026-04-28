SELECT
DB_NAME() AS DbName, 
name AS FileName, 
physical_name AS PhysicalName, 
CASE WHEN data_space_id = 0 THEN 'LOG' WHEN data_space_id <> 0 THEN FILEGROUP_NAME(data_space_id) END AS FileGroupName, 
type_desc AS TypeDesc, 
ROUND(FORMAT(size/128.0, 'g18'), 2) AS 'CurrentSize[MB]', 
ROUND(FORMAT(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0, 'g18'), 2) AS 'FreeSpace[MB]',
ROUND(FORMAT(ROUND((size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0)/(size/128.0)*100, 2), 'g18'), 2) AS 'PercentOfFreeSpace[%]',
CASE WHEN is_percent_growth = 1 THEN growth ELSE FORMAT(growth/128.0, 'g18') END AS AutogrowthValue,
CASE WHEN growth = 0 THEN '' WHEN max_size = -1 THEN 'Unlimited' ELSE FORMAT(max_size/128.0, 'g18') END AS AutogrowthMaxSize,
CASE WHEN is_percent_growth = 1 THEN 'Percentage %' when growth = 0 THEN '' ELSE 'Fixed MB' END AS AutogrowthType
FROM sys.database_files
WHERE TYPE IN (0,  1)
ORDER BY FileGroupName

SELECT
ROUND(FORMAT(SUM(size/128.0), 'g18'), 2) AS 'SumCurrentSizeDataFiles[MB]',
ROUND(FORMAT(SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0), 'g18'), 2) AS 'SumFreeSpaceDataFiles[MB]',
ROUND(FORMAT((SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0))/(SUM((size/128.0)))*100, 'g18'), 2) AS 'PercentOfFreeSpaceDataFiles[%]'
FROM sys.database_files
WHERE data_space_id <> 0
 
SELECT
ROUND(FORMAT(SUM(size/128.0), 'g18'), 2) AS 'SumCurrentSizeLogFiles[MB]',
ROUND(FORMAT(SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0), 'g18'), 2) AS 'SumFreeSpaceLogFiles[MB]',
ROUND(FORMAT((SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0))/(SUM((size/128.0)))*100, 'g18'), 2) AS 'PercentOfFreeSpaceLogFiles[%]'
FROM sys.database_files
WHERE data_space_id = 0

SELECT
CASE WHEN data_space_id = 0 THEN 'LOG' ELSE FILEGROUP_NAME(data_space_id) END AS GroupByFileGroupName,
ROUND(FORMAT(SUM(size/128.0), 'g18'), 2) AS 'SumCurrentSizeByFileGroupName[MB]',
ROUND(FORMAT(SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0), 'g18'), 2) AS 'SumFreeSpaceByFileGroupName[MB]',
ROUND(FORMAT((SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0))/(SUM((size/128.0)))*100, 'g18'), 2) AS 'PercentOfFreeSpaceByFileGroupName[%]'
FROM sys.database_files
GROUP BY CASE WHEN data_space_id = 0 THEN 'LOG' ELSE FILEGROUP_NAME(data_space_id) END  

SELECT 
name AS DatabaseName,
recovery_model_desc AS RecoveryModel
FROM sys.databases 
WHERE name = DB_NAME()

;with backup_cte as
(
    select
        database_name,
        backup_type =
            case type
                when 'D' then 'Full'
                when 'L' then 'Log'
                when 'I' then 'Differential'
                else 'IDK'
            end,
		backup_start_date,
        backup_finish_date,
        rownum = 
            row_number() over
            (
                partition by database_name, type 
                order by backup_finish_date desc
            )
    from msdb.dbo.backupset
)
select
    database_name AS DatabaseName,
    backup_type AS BackupType,
	backup_start_date AS StartDate,
    backup_finish_date AS FinishDate
from backup_cte
where rownum = 1 and database_name = DB_NAME()
order by database_name;

SELECT
log_reuse_wait_desc AS 'What cause blocking transaction log'
FROM master.sys.databases
WHERE name = DB_NAME()