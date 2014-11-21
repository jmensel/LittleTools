
-- Tested and known good by JHM, 04-04-2012
-- Declare variable used by the cursor
DECLARE @databasename AS nvarchar(128)

-- Create a cursor with all custom databases on the server

DECLARE db_list CURSOR FOR

SELECT [name] AS databasename

FROM master.dbo.sysdatabases

WHERE [name] NOT IN ('master', 'tempdb', 'model', 'msdb')

-- Open the cursor

OPEN db_list

-- Fetch next database name from the list and process it

FETCH NEXT FROM db_list INTO @databasename

WHILE @@FETCH_STATUS = 0 BEGIN

DECLARE @sqlCmd AS nvarchar(4000)

-- Set master as database

EXECUTE dbo.sp_ExecuteSQL N'USE [master]'

-- Modify logging mode instantly

SET @sqlCmd = N'ALTER DATABASE [' + @databasename + N']

SET RECOVERY FULL WITH NO_WAIT'

EXECUTE dbo.sp_ExecuteSQL @sqlCmd

SET @sqlCmd = N'ALTER DATABASE [' + @databasename + N']

SET RECOVERY FULL'

FETCH NEXT FROM db_list

INTO @databasename END

-- Close and release the cursor

CLOSE db_list

DEALLOCATE db_list
