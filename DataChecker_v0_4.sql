SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[x_DataChecker_v0_3]
(
    @Mode char(1) = 'T',
    @SchemaSearchPattern varchar(1024),
    @SchemaSearchExclusion varchar(1024) = NULL,
	@TableSearchPattern varchar(1024),
    @TableSearchExclusion varchar(1024) = NULL,
	@WhereClause varchar(1024) = '',
    @IncludeTables bit = 1, 
    @IncludeViews bit = 0,
    @DataTypeRestriction varchar(256) = NULL,
    @ResultsOutputTableSchema varchar(1024) = NULL,
    @ResultsOutputTableName varchar(1024) = NULL,
    @ResultsOutputTruncate bit = 0
)

AS


SET NOCOUNT ON


DECLARE @TablesToCheck TABLE
(
    id int IDENTITY(1,1),
    TableSchema varchar(256),
    TableName varchar(256)    
);

 
DECLARE @TableTypeTable varchar(18) = CASE WHEN @IncludeTables = 1 THEN 'BASE TABLE' ELSE NULL END
DECLARE @TableTypeView  varchar(18) = CASE WHEN @IncludeViews = 1 THEN 'VIEW' ELSE NULL END

INSERT INTO @TablesToCheck
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE 
TABLE_SCHEMA LIKE @SchemaSearchPattern 
AND (@SchemaSearchExclusion IS NULL OR TABLE_SCHEMA NOT LIKE @SchemaSearchExclusion)
AND TABLE_NAME LIKE @TableSearchPattern
AND (@TableSearchExclusion IS NULL OR TABLE_NAME NOT LIKE @TableSearchExclusion)
AND (
    (TABLE_TYPE = @TableTypeTable)
    OR
    (TABLE_TYPE = @TableTypeView)
    )   

IF NOT EXISTS (SELECT TOP 1 1 FROM @TablesToCheck)
BEGIN

 RAISERROR('No object matched the search pattern',0,1);

END;

IF EXISTS (SELECT TOP 1 1 FROM @TablesToCheck)
BEGIN

IF @Mode = 'T'
BEGIN
 SELECT * FROM @TablesToCheck
END

IF @Mode = 'P'
BEGIN
DECLARE 
    @counter_max INT = (SELECT MAX(id) FROM @TablesToCheck),
    @TableName varchar(256),
    @counter_current int = 1,
    @sql NVARCHAR(MAX) =''

IF OBJECT_ID ('tempdb..#DataCheckerTable') IS NOT NULL DROP TABLE #DataCheckerTable

CREATE TABLE #DataCheckerTable 
(
TableName sysname,
ColumnName sysname,
ColumnPosition int,
DataType varchar(256),
TotalRows bigint,
DistinctCount int, 
NullCount int, 
NonNullCount int,
NullPercentage float, 
MinInt bigint,
MaxInt bigint,
MinDate datetime,
MaxDate datetime,
SpaceAsLastChar int
)

WHILE (@counter_current <= @counter_max)
BEGIN

 SELECT @TableName = TableName FROM @TablesToCheck WHERE id = @counter_current

 SELECT @sql += 'SELECT
                '''+TABLE_NAME+''' AS TableName,
                '''+COLUMN_NAME+''' AS ColumnName,  
                '''+CONVERT(VARCHAR(5),ORDINAL_POSITION)+''' AS ColumnPosition,
                '''+DATA_TYPE+'''  AS DataType,
                COUNT(1) AS Row_Count,
                COUNT(DISTINCT '+COLUMN_NAME+') AS DistinctCount, 
                SUM(CASE WHEN '+COLUMN_NAME+' IS NULL THEN 1 ELSE 0 END) AS CountNulls,
                COUNT(' +COLUMN_NAME+') AS CountnonNulls,
                ROUND(100 * CAST(SUM(CASE WHEN '+COLUMN_NAME+' IS NULL THEN 1 ELSE 0 END) AS float) / CAST(COUNT(1) AS float), 1) AS NullPercentage,
                
                CASE 
                     WHEN '''+DATA_TYPE+''' IN (''int'', ''bigint'') 
                        THEN MIN('+COLUMN_NAME+') 
                     ELSE NULL 
                    END AS MinInt,
                 CASE 
                     WHEN '''+DATA_TYPE+''' IN (''int'', ''bigint'') 
                        THEN MAX('+COLUMN_NAME+') 
                     ELSE NULL 
                END AS MaxInt,
                CASE 
                     WHEN '''+DATA_TYPE+''' IN (''datetime'',''smalldatetime'',''datetime2'',''date'', ''datetimeoffset'', ''time'') 
                     THEN MIN('+COLUMN_NAME+') 
                     ELSE NULL 
                    END AS MinDate,
                CASE 
                     WHEN '''+DATA_TYPE+''' IN (''datetime'',''smalldatetime'',''datetime2'',''date'', ''datetimeoffset'', ''time'') 
                     THEN MAX('+COLUMN_NAME+') 
                     ELSE NULL 
                    END AS MaxDate,
               CASE 
                     WHEN '''+DATA_TYPE+''' IN (''varchar'', ''char'', ''nvarchar'')
                     THEN 
                        CASE 
                           WHEN 
                                 SUM(CASE WHEN RIGHT('+COLUMN_NAME+', 1) = '' '' 
                                 THEN 1 ELSE 0 END)
                           > 0 THEN 1 
                           ELSE 0 
                        END
                     ELSE NULL END
                     AS SpaceAsLastChar
                FROM '+QUOTENAME(TABLE_SCHEMA)+'.'+QUOTENAME(TABLE_NAME)
                     +@WhereClause+' ;'+ CHAR(10)
 FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA LIKE @SchemaSearchPattern
 AND TABLE_NAME = @TableName
 AND DATA_TYPE <> 'bit'
 AND (@DataTypeRestriction IS NULL OR DATA_TYPE = @DataTypeRestriction)
 

 INSERT INTO #DataCheckerTable
 EXEC sp_executesql @sql;

 
 SET @counter_current += 1
END



IF (@ResultsOutputTableName IS NOT NULL OR @ResultsOutputTableSchema IS NOT NULL)
BEGIN

 IF @ResultsOutputTableName IS NULL
 BEGIN
 RAISERROR('Name for results output table was not specified.',0,1);
 END

 IF @ResultsOutputTableSchema IS NULL
 BEGIN
 RAISERROR('Schema for results output was not specified.',0,1);
 END


 IF NOT EXISTS 
  (SELECT 1
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_NAME = @ResultsOutputTableName
   AND TABLE_SCHEMA = @ResultsOutputTableSchema) 
BEGIN
  DECLARE @sql2 nvarchar(max);
  SET 
  @sql2 = 'CREATE TABLE '+QUOTENAME(@ResultsOutputTableSchema)+'.'+QUOTENAME(@ResultsOutputTableName)+'
    (
    RunId int,
    TableName sysname,
    ColumnName sysname,
    ColumnPosition int,
    DataType varchar(256),
    TotalRows bigint,
    DistinctCount int, 
    NullCount int, 
    NonNullCount int,
    NullPercentage float, 
    MinInt bigint,
    MaxInt bigint,
    MinDate datetime,
    MaxDate datetime,
    SpaceAsLastChar int,
    LoadTime datetime DEFAULT GETDATE()
    )';

  EXEC sp_executesql @sql2;
 END




DECLARE @RunId int = 1;

DECLARE @sql3 nvarchar(MAX);
SET @sql3 =
 N'IF EXISTS (SELECT TOP 1 1 FROM '+QUOTENAME(@ResultsOutputTableSchema)+'.'+QUOTENAME(@ResultsOutputTableName)+')
 BEGIN
    SET @RunId = ((SELECT MAX(RUNID) FROM '+QUOTENAME(@ResultsOutputTableSchema)+'.'+QUOTENAME(@ResultsOutputTableName)+') + 1)
 END';
EXEC sp_executesql @sql3, N'@RunId int OUTPUT', @RunId = @RunId OUTPUT;


DECLARE @sql4 nvarchar(MAX);
SET @sql4 = 
 'INSERT INTO '+QUOTENAME(@ResultsOutputTableSchema)+'.'+QUOTENAME(@ResultsOutputTableName)+'
    (RunId, TableName, ColumnName, ColumnPosition, DataType, TotalRows, DistinctCount, NullCount, NonNullCount, NullPercentage, MinInt, MaxInt, MinDate, MaxDate, SpaceAsLastChar)
 SELECT
   RunId = @RunId, 
   TableName, ColumnName, ColumnPosition, DataType, TotalRows, DistinctCount, NullCount, NonNullCount, NullPercentage, MinInt, MaxInt, MinDate, MaxDate, SpaceAsLastChar  
 FROM #DataCheckerTable';
EXEC sp_executesql @sql4, N'@RunId int', @RunId;

 END

IF @ResultsOutputTableName IS NULL AND @ResultsOutputTableSchema IS NULL
BEGIN
 SELECT TableName, ColumnName, TotalRows, DistinctCount, NullCount, NullPercentage, SpaceAsLastChar  FROM #DataCheckerTable
END

DROP TABLE IF EXISTS #DataCheckerTable

END
END
GO
