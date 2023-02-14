




CREATE PROCEDURE [DC].[DataChecker_AddTest] 
(
  @Mode char(16) = 'Show',
  @Database varchar(256) = NULL,
  @SchemaSearchPattern varchar(1024),
  @SchemaSearchExclusion varchar(1024) = NULL,
	@TableSearchPattern varchar(1024),
  @TableSearchExclusion varchar(1024) = NULL,
  @ColumnNameSearchPattern varchar(1024) = NULL,
  @ColumnNameSearchExclusion varchar(1024) = NULL,
  @ColumnDataType varchar(256) = NULL,
  @IncludeTables bit = 1, 
  @IncludeViews bit = 0
)

AS
SET NOCOUNT ON

DECLARE @TableTypeTable varchar(18) = CASE WHEN @IncludeTables = 1 THEN 'BASE TABLE' ELSE NULL END
DECLARE @TableTypeView  varchar(18) = CASE WHEN @IncludeViews = 1 THEN 'VIEW' ELSE NULL END

DECLARE @SearchResult TABLE
(
  id int IDENTITY(1,1),
  DatabaseName varchar(256), 
  TableSchema varchar(256),
  TableName varchar(256),
  TableType varchar(128),
  ColumnName varchar(128),   
  ColumnDataType varchar(256)
);

INSERT INTO @SearchResult
SELECT 
DatabaseName = tables.TABLE_CATALOG,
TableSchema = tables.TABLE_SCHEMA, 
TableName = tables.TABLE_NAME,
TableType = tables.TABLE_TYPE,
ColumnName = COLUMN_NAME, 
ColumnDataType = DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS columns
JOIN INFORMATION_SCHEMA.TABLES tables
  ON columns.TABLE_SCHEMA = tables.TABLE_SCHEMA
  AND columns.TABLE_NAME = tables.TABLE_NAME
WHERE 
  tables.TABLE_SCHEMA LIKE @SchemaSearchPattern 
  AND (@SchemaSearchExclusion IS NULL 
      OR tables.TABLE_SCHEMA NOT LIKE @SchemaSearchExclusion)
  AND tables.TABLE_SCHEMA LIKE @SchemaSearchPattern 
  AND (@TableSearchExclusion IS NULL 
      OR tables.TABLE_NAME NOT LIKE @TableSearchExclusion)
  AND tables.TABLE_NAME LIKE @TableSearchPattern
  AND ((TABLE_TYPE = @TableTypeTable)
      OR
      (TABLE_TYPE = @TableTypeView))
  AND (@ColumnNameSearchPattern IS NULL 
      OR
      COLUMN_NAME LIKE @ColumnNameSearchPattern) 

IF NOT EXISTS (SELECT TOP 1 1 FROM @SearchResult)
  BEGIN
    RAISERROR('No object matched the search pattern',0,1);
  END;

IF @Mode = 'Show'
BEGIN
 SELECT DISTINCT DatabaseName, TableSchema, TableName, TableType FROM @SearchResult
 SELECT * FROM @SearchResult
END

IF @Mode = 'Push'
BEGIN
  MERGE [DC].D_DataChecker_Tables AS tgt
  USING (SELECT DISTINCT DatabaseName, TableSchema, TableName, TableType 
        FROM @SearchResult) AS src
  ON src.DatabaseName = tgt.DatabaseName
  AND src.TableSchema = tgt.TableSchema
  AND src.TableName = tgt.TableName
  AND src.TableType = tgt.TableType
  WHEN NOT MATCHED THEN
  INSERT (DatabaseName, TableSchema, TableName, TableType)
  VALUES (src.DatabaseName, src.TableSchema, src.TableName, src.TableType);
  
  MERGE [DC].[D_DataChecker_Columns] AS tgt
  USING (SELECT Table_id = d2.id, DataType_id = d1.id, ColumnName 
        FROM @SearchResult q
        LEFT JOIN DC.D_DataChecker_DataType d1 ON q.ColumnDataType = d1.DataType
        LEFT JOIN DC.D_DataChecker_Tables d2 
          ON q.TableSchema = d2.TableSchema
          AND q.TableName = d2.TableName
          AND q.TableType = d2.TableType
          AND q.DatabaseName = d2.DatabaseName) AS src
  ON src.Table_id = tgt.Table_id
  AND src.ColumnName = tgt.ColumnName
  WHEN NOT MATCHED THEN
  INSERT (Table_id, DataType_id, ColumnName)
  VALUES (src.Table_id, src.Datatype_id, src.ColumnName);

END


