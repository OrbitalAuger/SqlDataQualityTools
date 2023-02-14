

CREATE PROCEDURE DC.Datachecker_CreateDataModel
AS

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'D_DataChecker_Columns' AND xtype = 'U')
CREATE TABLE [DC].[D_DataChecker_Columns](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Table_id] [int] NOT NULL,
	[Datatype_id] [int] NOT NULL,
	[ColumnName] [nvarchar](256) NOT NULL
) ON [PRIMARY]
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'D_DataChecker_DataType' AND xtype = 'U')
CREATE TABLE [DC].[D_DataChecker_DataType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TestCategory_id] [int] NULL,
	[DataType] [varchar](256) NOT NULL
) ON [PRIMARY]
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_DataChecker_Tables' AND xtype = 'U')
CREATE TABLE [DC].[D_DataChecker_Tables](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](256) NOT NULL,
	[TableSchema] [nvarchar](256) NOT NULL,
	[TableName] [nvarchar](256) NOT NULL,
	[TableType] [nvarchar](256) NOT NULL
) ON [PRIMARY]

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'F_DataChecker_TableTests' AND xtype = 'U')
CREATE TABLE [DC].[F_DataChecker_TableTests](
	[RunId] [int] IDENTITY(1,1) NOT NULL,
	[Table_id] [nvarchar](256) NOT NULL,
	[Test_id] [nvarchar](256) NOT NULL,
	[Value] int NOT NULL,
) ON [PRIMARY]

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'F_DataChecker_TableTests' AND xtype = 'U')
CREATE TABLE [DC].[F_DataChecker_TableTests](
	[RunId] [int] IDENTITY(1,1) NOT NULL,
	[Column_id] [nvarchar](256) NOT NULL,
	[Test_id] [nvarchar](256) NOT NULL,
	[Value] int NOT NULL,
) ON [PRIMARY]