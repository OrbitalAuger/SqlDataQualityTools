

CREATE PROCEDURE DC.Datachecker_CreateDataModel
AS

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT TOP 1 1 FROM [DC].[D_DataChecker_Columns])
CREATE TABLE [DC].[D_DataChecker_Columns](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Table_id] [int] NOT NULL,
	[Datatype_id] [int] NOT NULL,
	[ColumnName] [nvarchar](256) NOT NULL
) ON [PRIMARY]

IF NOT EXISTS (SELECT TOP 1 1 FROM [DC].[D_DataChecker_DataType])
CREATE TABLE [DC].[D_DataChecker_DataType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TestCategory_id] [int] NULL,
	[DataType] [varchar](256) NOT NULL
) ON [PRIMARY]

IF NOT EXISTS (SELECT TOP 1 1 FROM [DC].[D_DataChecker_Tables])
CREATE TABLE [DC].[D_DataChecker_Tables](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](256) NOT NULL,
	[TableSchema] [nvarchar](256) NOT NULL,
	[TableName] [nvarchar](256) NOT NULL,
	[TableType] [nvarchar](256) NOT NULL
) ON [PRIMARY]

