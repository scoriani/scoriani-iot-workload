IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'scoriani-iot')
BEGIN
CREATE DATABASE [scoriani-iot]  (EDITION = 'Hyperscale', SERVICE_OBJECTIVE = 'HS_Gen5_8') WITH CATALOG_COLLATION = SQL_Latin1_General_CP1_CI_AS;

END
GO
ALTER DATABASE [scoriani-iot] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [scoriani-iot] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [scoriani-iot] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [scoriani-iot] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [scoriani-iot] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [scoriani-iot] SET ARITHABORT OFF 
GO
ALTER DATABASE [scoriani-iot] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [scoriani-iot] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [scoriani-iot] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [scoriani-iot] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [scoriani-iot] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [scoriani-iot] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [scoriani-iot] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [scoriani-iot] SET AUTO_UPDATE_STATISTICS_ASYNC ON 
GO
ALTER DATABASE [scoriani-iot] SET ALLOW_SNAPSHOT_ISOLATION ON 
GO
ALTER DATABASE [scoriani-iot] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [scoriani-iot] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [scoriani-iot] SET  MULTI_USER 
GO
ALTER DATABASE [scoriani-iot] SET ENCRYPTION ON
GO
ALTER DATABASE [scoriani-iot] SET QUERY_STORE = ON
GO
ALTER DATABASE [scoriani-iot] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1024, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/*** The scripts of database scoped configurations in Azure should be executed inside the target database connection. ***/
GO
-- ALTER DATABASE SCOPED CONFIGURATION SET ASYNC_STATS_UPDATE_WAIT_AT_LOW_PRIORITY = ON;
GO
-- ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 8;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[events](
	[deviceid] [varchar](50) NULL,
	[timestamp] [datetime] NULL,
	[json] [varchar](max) NULL,
	[engineState]  AS (CONVERT([char](3),json_value([json],'$.engine'))),
	[eventTime]  AS (CONVERT([varchar](28),json_value([json],'$.time'))),
	[temp]  AS (CONVERT([int],json_value([json],'$.temp'))) PERSISTED
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND name = N'clEvents')
CREATE CLUSTERED INDEX [clEvents] ON [dbo].[events]
(
	[timestamp] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vTimeSeriesBuckets]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [dbo].[vTimeSeriesBuckets]
AS
SELECT 
	DATEADD(MINUTE, DATEDIFF(MINUTE, ''2000'', timestamp) / 10 * 10, ''2000'') as timeslot,
	deviceid,
	AVG(CONVERT(int,temp)) as temp
FROM 
	dbo.events 
WHERE 
	timestamp > DATEADD(HOUR, -12, getdate())
GROUP BY DATEADD(MINUTE, DATEDIFF(MINUTE, ''2000'', timestamp) / 10 * 10, ''2000''), deviceid
' 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[devices]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[devices](
	[deviceid] [varchar](50) NULL
) ON [PRIMARY]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[test]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[test](
	[id] [int] NULL,
	[val] [varchar](255) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND name = N'ncclEvents')
CREATE NONCLUSTERED INDEX [ncclEvents] ON [dbo].[events]
(
	[deviceid] ASC
)
INCLUDE([temp],[engineState],[eventTime]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER DATABASE [scoriani-iot] SET  READ_WRITE 
GO
