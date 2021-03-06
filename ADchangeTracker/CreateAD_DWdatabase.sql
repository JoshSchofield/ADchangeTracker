USE [master]
GO
CREATE DATABASE [AD_DW]
GO
ALTER DATABASE [AD_DW] MODIFY FILE
( NAME = N'AD_DW' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 4096KB )
GO
ALTER DATABASE [AD_DW] MODIFY FILE
( NAME = N'AD_DW_log' , SIZE = 10MB , MAXSIZE = UNLIMITED , FILEGROWTH = 10%)
GO
ALTER DATABASE [AD_DW] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [AD_DW].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [AD_DW] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [AD_DW] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [AD_DW] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [AD_DW] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [AD_DW] SET ARITHABORT OFF 
GO
ALTER DATABASE [AD_DW] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [AD_DW] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [AD_DW] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [AD_DW] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [AD_DW] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [AD_DW] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [AD_DW] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [AD_DW] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [AD_DW] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [AD_DW] SET  DISABLE_BROKER 
GO
ALTER DATABASE [AD_DW] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [AD_DW] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [AD_DW] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [AD_DW] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [AD_DW] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [AD_DW] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [AD_DW] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [AD_DW] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [AD_DW] SET  MULTI_USER 
GO
ALTER DATABASE [AD_DW] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [AD_DW] SET DB_CHAINING OFF 
GO
/****** Object:  Table [dbo].[ADevents]    Script Date: 21.6.2015 14:25:13 ******/
USE [AD_DW]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ADevents](
	[SourceDC] [nvarchar](128) NOT NULL,
	[EventRecordID] [int] NOT NULL,
	[EventTime] [datetime2](7) NOT NULL,
	[EventID] [int] NOT NULL,
	[ObjClass] [nvarchar](64) NULL,
	[Target] [nvarchar](256) NULL,
	[Changes] [nvarchar](256) NULL,
	[ModifiedBy] [nvarchar](128) NULL,
	[EventXml] [xml] NULL,
 CONSTRAINT [PK_ADevents] PRIMARY KEY NONCLUSTERED 
(
	[SourceDC] ASC,
	[EventRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Index [IX_EventTime]    Script Date: 21.6.2015 14:25:13 ******/
CREATE CLUSTERED INDEX [IX_EventTime] ON [dbo].[ADevents]
(
	[EventTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EventDescription]    Script Date: 21.6.2015 14:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventDescription](
	[EventID] [int] NOT NULL,
	[Description] [nvarchar](128) NULL,
 CONSTRAINT [PK_EventID] PRIMARY KEY CLUSTERED 
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[vADevents]    Script Date: 21.6.2015 14:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vADevents]
AS
SELECT e.[SourceDC]
      ,e.[EventRecordID]
      ,e.[EventTime]
      ,e.[EventID]
	  ,d.[Description]
      ,e.[ObjClass]
      ,e.[Target]
      ,e.[Changes]
      ,e.[ModifiedBy]
      ,e.[EventXml]
  FROM [AD_DW].[dbo].[ADevents] e
  LEFT JOIN [AD_DW].dbo.EventDescription d ON e.EventID = d.EventID
GO
/****** Object:  View [dbo].[vADeventsEx]    Script Date: 21.6.2015 14:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vADeventsEx]
AS
SELECT e.[SourceDC]
      ,e.[EventRecordID]
      ,e.[EventTime]
	  ,'<a href="https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=' + CONVERT(nvarchar, e.[EventID]) + '">' + CONVERT(nvarchar, e.[EventID]) + '</a>' AS [EventID]
	  ,d.[Description]
      ,e.[ObjClass]
      ,e.[Target]
      ,e.[Changes]
      ,e.[ModifiedBy]
      ,e.[EventXml]
  FROM [AD_DW].[dbo].[ADevents] e
  LEFT JOIN [AD_DW].dbo.EventDescription d ON e.EventID = d.EventID

GO
/****** Object:  StoredProcedure [dbo].[usp_ADchgEventEx]    Script Date: 21.6.2015 14:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================================
-- Author:		Snorri Kristjánsson
-- Create date: 16.05.2015
-- Description:	Receives AD changes event data as XML.
-- Called from ADchangeTracker service that runs on domain controllers.
-- Data is extracted from the XML and stored in table columns. The XML data is also stored
-- unchanged.
-- Column:			XML data XPath:
-- [SourceDC]		/Event/System/Computer
-- [EventRecordID]	/Event/System/EventRecordID
-- [EventTime]		/Event/System/TimeCreated/@SystemTime
-- [EventID]		/Event/System/EventID
-- [ObjClass]		**1
-- [Target]			**2
-- [Changes]		**3
-- [ModifiedBy]		/Event/EventData/Data[@Name="SubjectDomainName"]
--					+ '\' + /Event/EventData/Data[@Name="SubjectUserName"]
--
-- **1 [ObjClass] is set depending on EventID:
-- [ObjClass] = 'user' when EventID = 4738, 4740, 4720, 4725, 4724, 4723 OR 4722, 4767.
--
-- [ObjClass] = 'group' when EventID = 4728, 4732, 4733 OR 4756.
--
-- [ObjClass] = 'unknown' when EventID = 4781.
--
-- [ObjClass] = Data from XML, XPath: /Event/EventData/Data[@Name="ObjectClass"] 
--              when EventID = 5136, 5137, 5139, 5141.
--
-- **2 [Target] is set depending on EventID:
-- [Target] = Data from XML, XPath: /Event/EventData/Data[@Name="TargetDomainName"]
--                                  + '\' +/Event/EventData/Data[@Name="TargetUserName"]
--            when EventID = 4738, 4740, 4725, 4724, 4723 OR 4722, 4720, 4732, 4733, 4781, 4728, 4756, 4767.
--
-- [Target] = Data from XML, XPath: /Event/EventData/Data[@Name="ObjectDN"]
--            when EventID = 5136, 5137 OR 5141.
--
-- [Target] = Data from XML, XPath: /Event/EventData/Data[@Name="OldObjectDN"]
--            when EventID = 5139.
--
-- [Target] = Data from XML, XPath: /Event/EventData/Data[@Name="SubjectDomainName"]
--                                  + '\' + /Event/EventData/Data[@Name="SubjectDomainName"]
--            when EventID = 4740.
--
-- **3 [Changes] is set depending on EventID:
-- [Changes] = 'NewTargetUserName: ' + Data from XML, XPath: /Event/EventData/Data[@Name="NewTargetUserName"]
--            when EventID = 4781
--
-- [Changes] = 'MemberName: ' + Data from XML, XPath: /Event/EventData/Data[@Name="MemberName"]
--            when EventID = 4728 OR 4756
--
-- [Changes] = 'MemberSID: ' + Data from XML, XPath: /Event/EventData/Data[@Name="MemberSid"]
--            when EventID = 4732, 4733
--
-- [Changes] = '(Value Added) ' OR '(Value Deleted) ' 
--             + Data from XML, XPath: /Event/EventData/Data[@Name="AttributeLDAPDisplayName"]
--             + ': ' + /Event/EventData/Data[@Name="AttributeValue"]
--            when EventID = 5136
--
-- [Changes] = 'NewObjectDN: ' + Data from XML, XPath: /Event/EventData/Data[@Name="NewObjectDN"]
--            when EventID = 5139
--
-- [Changes] = 'Calling computer: ' + Data from XML, XPath: /Event/EventData/Data[@Name="TargetDomainName"]
--            when EventID = 4740
--
-- ======================================================================================
CREATE PROCEDURE [dbo].[usp_ADchgEventEx]
	@XmlData nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @x XML = @XmlData;

	-- Get EventRecordID and SourceDC from XML data.
	DECLARE @EventRecordID int;
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @EventRecordID = @x.value('(/Event/System/EventRecordID)[1]', 'int');
	DECLARE @SourceDC nvarchar(128);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @SourceDC = @x.value('(/Event/System/Computer)[1]', 'nvarchar(128)');

	-- Early exit if event already processed (exists in table).
	IF EXISTS(SELECT EventRecordID FROM dbo.ADevents 
		WHERE EventRecordID = @EventRecordID AND SourceDC = @SourceDC)
		RETURN;

	DECLARE @EventID int;
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @EventID = @x.value('(/Event/System/EventID)[1]', 'int'); -- AS EventID

	DECLARE @ObjClass nvarchar(128), @Target nvarchar(256) = '', @Changes nvarchar(256) = '';

	-- Set @ObjClass depending on EventID:
	SELECT @ObjClass = 'user' WHERE @EventID IN (4740, 4738, 4725, 4724, 4723, 4722, 4720, 4767);
	SELECT @ObjClass = 'unknown' WHERE @EventID IN (4781);
	SELECT @ObjClass = 'group' WHERE @EventID IN (4728, 4732, 4733, 4756);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @ObjClass = @x.value('(/Event/EventData/Data[@Name="ObjectClass"])[1]', 'nvarchar(64)')
		WHERE @EventID IN (5136, 5137, 5139, 5141);

	-- Set @Target depending on EventID:
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Target = @x.value('(/Event/EventData/Data[@Name="SubjectDomainName"])[1]', 'nvarchar(64)') + '\' 
			+ @x.value('(/Event/EventData/Data[@Name="TargetUserName"])[1]', 'nvarchar(64)')
		WHERE @EventID IN (4740);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Target = @x.value('(/Event/EventData/Data[@Name="TargetDomainName"])[1]', 'nvarchar(64)') + '\' 
			+ @x.value('(/Event/EventData/Data[@Name="TargetUserName"])[1]', 'nvarchar(64)')
		WHERE @EventID IN (4738, 4725, 4724, 4723, 4722, 4720, 4728, 4732, 4733, 4756, 4767);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Target = @x.value('(/Event/EventData/Data[@Name="TargetDomainName"])[1]', 'nvarchar(64)') + '\' 
			+ @x.value('(/Event/EventData/Data[@Name="OldTargetUserName"])[1]', 'nvarchar(64)')
		WHERE @EventID IN (4781);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Target = @x.value('(/Event/EventData/Data[@Name="ObjectDN"])[1]', 'nvarchar(128)')
		WHERE @EventID IN (5136, 5137, 5141);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Target = @x.value('(/Event/EventData/Data[@Name="OldObjectDN"])[1]', 'nvarchar(128)')
	WHERE @EventID IN (5139);

	-- Set @Changes depending on EventID:
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Changes = 'Calling computer: ' 
			+ @x.value('(/Event/EventData/Data[@Name="TargetDomainName"])[1]', 'nvarchar(128)')
		WHERE @EventID IN (4740);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Changes = 'NewTargetUserName: ' 
			+ @x.value('(/Event/EventData/Data[@Name="NewTargetUserName"])[1]', 'nvarchar(128)')
		WHERE @EventID IN (4781);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Changes = 'MemberName: ' 
			+ @x.value('(/Event/EventData/Data[@Name="MemberName"])[1]', 'nvarchar(128)')
		WHERE @EventID IN (4728, 4756);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Changes = 'MemberSID: ' 
			+ @x.value('(/Event/EventData/Data[@Name="MemberSid"])[1]', 'nvarchar(128)')
		WHERE @EventID IN (4732, 4733);
	WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
		SELECT @Changes = 'NewObjectDN: '
			+ @x.value('(/Event/EventData/Data[@Name="NewObjectDN"])[1]', 'nvarchar(128)')
		WHERE @EventID IN (5139);
	IF @EventID = 5136
	BEGIN
		DECLARE @OpType nvarchar(32);
		WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
			SELECT @OpType = @x.value('(/Event/EventData/Data[@Name="OperationType"])[1]', 'nvarchar(32)');
		IF @OpType = '%%14674' 
			SET @OpType = 'Value Added';
		ELSE IF @OpType = '%%14675' 
			SET @OpType = 'Value Deleted';

		WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/win/2004/08/events/event')
			SELECT @Changes = '(' + @OpType + ') ' 
				+ @x.value('(/Event/EventData/Data[@Name="AttributeLDAPDisplayName"])[1]', 'nvarchar(128)') 
				+ ': ' + @x.value('(/Event/EventData/Data[@Name="AttributeValue"])[1]', 'nvarchar(128)');
	END

	-- Insert new row into ADevents table.
	;WITH XMLNAMESPACES (
	  default 'http://schemas.microsoft.com/win/2004/08/events/event'
	)
	,[Event] AS
	(
	SELECT @x.value('(/Event/System/TimeCreated/@SystemTime)[1]', 'datetime2') AS EventTime
		,@x.value('(/Event/EventData/Data[@Name="SubjectDomainName"])[1]', 'nvarchar(64)') + '\' 
			+ @x.value('(/Event/EventData/Data[@Name="SubjectUserName"])[1]', 'nvarchar(64)') AS ModifiedBy
		,@x AS EventXml
	)
	INSERT INTO dbo.ADevents
		SELECT @SourceDC, @EventRecordID, e.EventTime, @EventID AS EventID, 
		@ObjClass AS ObjClass, @Target AS [Target], @Changes AS [Changes], e.ModifiedBy, 
		e.EventXml 
	FROM [Event] e
END
GO
/****** Object:  StoredProcedure [dbo].[usp_CheckConnection]    Script Date: 21.6.2015 14:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Snorri Kristjánsson
-- Create date: 25.05.2015
-- Description:	Dummy proc - to check SQL connection
-- =============================================
CREATE PROCEDURE [dbo].[usp_CheckConnection] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

END
GO
/****** Object:  StoredProcedure [dbo].[usp_GetADevents]    Script Date: 21.6.2015 14:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Snorri Kristjansson
-- Create date: 07.06.2015
-- Description:	Get AD events for SSRS report
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetADevents]
	@DateFrom DATETIME,
	@DateTo DATETIME,
	@SourceDC nvarchar(64),
	@ModifiedBy nvarchar(64),
	@EventIDs nvarchar(128),
	@ObjClass nvarchar(64),
	@Changes nvarchar(64),
	@Target nvarchar(64)
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @Url nvarchar(90) = 'https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=';

Declare @SQLQuery AS nvarchar(4000);
SET @SQLQuery =
'SELECT e.SourceDC, e.EventRecordID, e.EventTime, 
''<a href="' + @Url + ''' + CONVERT(nvarchar, e.[EventID]) + ''">'' + CONVERT(nvarchar, e.[EventID]) + ''</a>'' AS [EventID],
e.EventID, d.Description, e.ObjClass, 
e.Changes, e.Target, e.ModifiedBy, ''view XML'' AS EventXml
FROM dbo.ADevents e
LEFT JOIN dbo.EventDescription d ON e.EventID = d.EventID
WHERE EventTime BETWEEN @DateFrom AND @DateTo';

IF @SourceDC != '' SET @SQLQuery = @SQLQuery + ' AND e.SourceDC LIKE ''%' + @SourceDC + '%''';
IF @ModifiedBy != '' SET @SQLQuery = @SQLQuery + ' AND e.ModifiedBy LIKE ''%' + @ModifiedBy + '%''';
IF @ObjClass != '' SET @SQLQuery = @SQLQuery + ' AND e.ObjClass LIKE ''%' + @ObjClass + '%''';
IF @Changes != '' SET @SQLQuery = @SQLQuery + ' AND e.Changes LIKE ''%' + @Changes + '%''';
IF @Target != '' SET @SQLQuery = @SQLQuery + ' AND e.Target LIKE ''%' + @Target + '%''';
IF @EventIDs != ''
BEGIN
	SET @SQLQuery = @SQLQuery + ' AND e.EventID IN (' + @EventIDs + ')';
END
	SET @SQLQuery = @SQLQuery + ' ORDER BY e.EventTime, e.EventRecordID';

    Declare @ParamDefinition AS nvarchar(2000);

	Set @ParamDefinition = 
		'@DateFrom DATETIME,
		@DateTo DATETIME,
		@SourceDC nvarchar(64),
		@ModifiedBy nvarchar(64),
		@EventIDs nvarchar(128),
		@ObjClass nvarchar(64),
		@Changes nvarchar(64),
		@Target nvarchar(64)';
	
    /* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
    Execute sp_Executesql @SQLQuery, @ParamDefinition, 
		@DateFrom,
		@DateTo,
		@SourceDC,
		@ModifiedBy,
		@EventIDs,
		@ObjClass,
		@Changes,
		@Target;
END
GO
USE [AD_DW]
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4720, N'A user account was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4722, N'A user account was enabled')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4723, N'An attempt was made to change an account’s password')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4724, N'An attempt was made to reset an accounts password')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4725, N'A user account was disabled')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4726, N'A user account was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4727, N'A security - enabled global group was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4728, N'A member was added to a security - enabled global group')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4729, N'A member was removed from a security - enabled global group')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4730, N'A security - enabled global group was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4731, N'A security - enabled local group was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4732, N'A member was added to a security - enabled local group')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4733, N'A member was removed from a security - enabled local group')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4734, N'A security - enabled local group was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4738, N'A user account was changed')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4740, N'A user account was locked out')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4744, N'A security - disabled local group was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4746, N'A member was added to a security - disabled local group(distribution list)')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4747, N'A member was removed from a security - disabled local group(distribution list)')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4748, N'A security - disabled local group was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4749, N'A security - disabled global group was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4751, N'A member was added to a security - disabled global group(distribution list)')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4752, N'A member was removed from a security - disabled global group(distribution list)')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4753, N'A security - disabled global group was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4754, N'A security - enabled universal group was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4756, N'A member was added to a security - enabled universal group')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4757, N'A member was removed from a security - enabled universal group')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4758, N'A security - enabled universal group was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4759, N'A security - disabled universal group was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4761, N'A member was added to a security - disabled universal group(distribution list)')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4762, N'A member was removed from a security - disabled universal group(distribution list)')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4763, N'A security - disabled universal group was deleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4767, N'A user account was unlocked')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (4781, N'The name of an account was changed')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (5136, N'A directory service object was modified')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (5137, N'A directory service object was created')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (5138, N'A directory service object was undeleted')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (5139, N'A directory service object was moved')
GO
INSERT [dbo].[EventDescription] ([EventID], [Description]) VALUES (5141, N'A directory service object was deleted')
GO
USE [master]
GO
ALTER DATABASE [AD_DW] SET  READ_WRITE 
GO
