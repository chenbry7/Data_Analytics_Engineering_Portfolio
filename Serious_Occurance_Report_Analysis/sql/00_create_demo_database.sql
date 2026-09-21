:ON ERROR EXIT
USE master;
GO
-- Never overwrite an existing unrecognized database; never drop a database.
IF DB_ID(N'SOR_Portfolio_Test') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [SOR_Portfolio_Test]');
    EXEC(N'USE [SOR_Portfolio_Test]; EXEC sys.sp_addextendedproperty @name=N''SORPortfolioDemo'', @value=N''1'';');
END
ELSE
    EXEC(N'USE [SOR_Portfolio_Test];
      IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0
                     AND name=N''SORPortfolioDemo'' AND CONVERT(nvarchar(20),value)=N''1'')
        THROW 52000, ''Existing database is not owned by this demonstration; no changes made.'', 1;');
GO
