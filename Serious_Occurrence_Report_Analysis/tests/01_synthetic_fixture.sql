:ON ERROR EXIT
-- Post-internship enhancement. Run only in the isolated synthetic demonstration database.
IF DB_NAME() <> N'SOR_Portfolio_Test'
    THROW 52000, 'This script requires SOR_Portfolio_Test.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND name = N'SORPortfolioDemo' AND CONVERT(nvarchar(20), value) = N'1')
    THROW 52000, 'The database is not marked as this project demonstration.', 1;
GO

-- Entirely fictional fixture. These are not anonymized internship records.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
TRUNCATE TABLE bronze.SO_category;
TRUNCATE TABLE bronze.SO_status;
INSERT INTO bronze.SO_status
    (site_id, site_name, non_funded_licensed_OPR, sor_id, [status], sor_level, media_attention,
     date_serious_occur, time_serious_occur, date_report_submit, time_report_submit,
     last_update_date, last_update_time, update_due_date, revision_due_date,
     num_individuals, num_unique_individuals, num_unique_categories)
VALUES
('DEMO-SITE-01', ' Demo Site A ', ' y ', ' DEMO-E001 ', 'Open', '1', 'N',
 '2026-06-01', '09:30:00', '2026-06-02', '10:00:00', '2026-06-03', '12:00:00', '', 'n/a', '2', '2', '2'),
('DEMO-SITE-02', 'Demo Site B', 'N', 'DEMO-E002', 'Closed', '2', 'Y',
 '2026-06-02', '08:00:00', '2026-06-02', '11:00:00', '2026-06-04', '13:00:00', NULL, NULL, '1', '1', '2'),
('DEMO-SITE-01', 'Demo Site A', 'N', 'DEMO-E003', 'Open', '1', 'N',
 '2026-06-03', NULL, '2026-06-04', NULL, '2026-06-05', NULL, '', '', '0', '0', '0');

INSERT INTO bronze.SO_category
    (site_id, site_name, related_OPR, sor_id, [status], media_attention,
     date_time_serious_occur, date_time_report_submit, last_update_date_time,
     category, sub_category, [type], claim, [role], [location], client_id, client_DOB,
     client_age, guardian_status, CSC, program, provider_notification, noti_police)
VALUES
('DEMO-SITE-01', 'Demo Site A', 'N', 'DEMO-E001', 'Open', 'N',
 '2026-06-01T09:30:00', '2026-06-02T10:00:00', '2026-06-03T12:00:00',
 'Demo category A', 'Demo subcategory A', '', '', '', 'Demo location', 'DEMO-P001', '2010-01-01',
 '16', '', 'Y', 'Demo program', '', 'N'),
('DEMO-SITE-01', 'Demo Site A', 'N', 'DEMO-E001', 'Open', 'N',
 '2026-06-01 09:30:00', '2026-06-02 10:00:00', '2026-06-03 12:00:00',
 'Demo category B', 'Demo subcategory B', '', '', '', 'Demo location', 'DEMO-P002', '',
 'n/a', '', 'N', 'Demo program', '', 'N'),
('DEMO-SITE-02', 'Demo Site B', 'Y', 'DEMO-E002', 'Closed', 'Y',
 '2026-06-02T08:00:00', '2026-06-02T11:00:00', '2026-06-04T13:00:00',
 'Demo category A', 'Demo subcategory A', '', '', '', 'Demo location', 'DEMO-P001', '2010-01-01',
 '16', '', 'Y', 'Demo program', '', 'Y'),
('DEMO-SITE-02', 'Demo Site B', 'Y', 'DEMO-E002', 'Closed', 'Y',
 '2026-06-02T08:00:00', '2026-06-02T11:00:00', '2026-06-04T13:00:00',
 'Demo category B', 'Demo subcategory B', '', '', '', 'Demo location', 'DEMO-P001', '2010-01-01',
 '16', '', 'Y', 'Demo program', '', 'Y');
COMMIT TRANSACTION;
GO
