CREATE PROCEDURE SP_SIMULATEBOARDINGS
@START_DATE DATETIME,
@END_DATE DATETIME,
@VEHICLE_ID INT = NULL,
@RECORD_COUNT INT = 2
AS
BEGIN
    SET NOCOUNT ON;

    -- DEÐÝÞKENLER
    DECLARE @SUCCESS_COUNT INT = 0;
    DECLARE @ERROR_COUNT INT = 0;
    DECLARE @SYSTEM_TIME DATETIME = GETDATE();
    DECLARE @SELECTED_VEHICLE_ID INT;
    DECLARE @RANDOM_CARD_ID INT;
    DECLARE @CARD_NO BIGINT;
    DECLARE @CARD_TYPE_ID INT;
    DECLARE @CURRENT_BALANCE DECIMAL(10,2);
    DECLARE @FARE_PRICE DECIMAL(10,2);
    DECLARE @RANDOM_DEVICE_TYPE_ID INT;

    
    IF @START_DATE >= @END_DATE
    BEGIN
        PRINT 'HATA: Baþlangýç tarihi bitiþ tarihinden küçük olmalý';
        RETURN;
    END
    IF @RECORD_COUNT <= 0
    BEGIN
        PRINT 'HATA: Kayýt sayýsý 0''dan büyük olmalý';
        RETURN;
    END

    -- RASTGELE TARÝHLERÝ GEÇÝCÝ TABLOYA EKLE
    DECLARE @Temp TABLE (
        RowNum INT IDENTITY(1,1),
        RandomDate DATETIME
    );

    DECLARE @i INT = 1;
    WHILE @i <= @RECORD_COUNT
    BEGIN
        INSERT INTO @Temp (RandomDate)
        SELECT DATEADD(SECOND, CAST(RAND() * DATEDIFF(SECOND, @START_DATE, @END_DATE) AS INT), @START_DATE);
        SET @i += 1;
    END

    -- ARAÇ SEÇÝMÝ
    IF @VEHICLE_ID IS NULL
        SELECT TOP 1 @SELECTED_VEHICLE_ID = VEHICLE_ID FROM VEHICLE WHERE ISACTIVE = 1 ORDER BY NEWID();
    ELSE
        SET @SELECTED_VEHICLE_ID = @VEHICLE_ID;

    -- ÝÞLEMLERÝ SIRAYLA TARÝHE GÖRE YAP
    DECLARE date_cursor CURSOR FOR
    SELECT RandomDate FROM @Temp ORDER BY RandomDate;

    OPEN date_cursor;
    DECLARE @CURR_DATE DATETIME;

    FETCH NEXT FROM date_cursor INTO @CURR_DATE;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Kart seç
        SELECT TOP 1 
            @RANDOM_CARD_ID = CARD_ID,
            @CARD_NO = CARD_NO,
            @CARD_TYPE_ID = CARD_TYPE_ID,
            @CURRENT_BALANCE = BALANCE
        FROM CARDS
        WHERE ISACTIVE = 1 AND BALANCE > 0
        ORDER BY NEWID();

        -- Ücret al
        SELECT @FARE_PRICE = PRICE FROM CARDTYPES WHERE CARD_TYPE_ID = @CARD_TYPE_ID AND ISACTIVE = 1;

        SET @RANDOM_DEVICE_TYPE_ID = ABS(CHECKSUM(NEWID())) % 5 + 1;

        IF @CURRENT_BALANCE >= @FARE_PRICE
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION;

                INSERT INTO TRANSACTIONS(
                    VEHICLE_ID, CARD_ID, CARD_NO, CARD_TYPE_ID, DEVICE_TYPE_ID, 
                    TRANSACTION_DATE, SPENT_AMOUNT, REMAINING_BALANCE, PRE_BALANCE, SYSTEM_TIME_, LOCATION_INFO
                )
                VALUES(
                    @SELECTED_VEHICLE_ID, @RANDOM_CARD_ID, @CARD_NO, @CARD_TYPE_ID, @RANDOM_DEVICE_TYPE_ID,
                    @CURR_DATE, @FARE_PRICE, @CURRENT_BALANCE - @FARE_PRICE, @CURRENT_BALANCE, @SYSTEM_TIME, NULL
                );

                UPDATE CARDS 
                SET BALANCE = BALANCE - @FARE_PRICE, 
                    MODIFIED_DATE = @SYSTEM_TIME
                WHERE CARD_ID = @RANDOM_CARD_ID;

                COMMIT TRANSACTION;
                SET @SUCCESS_COUNT += 1;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                SET @ERROR_COUNT += 1;
            END CATCH
        END

        FETCH NEXT FROM date_cursor INTO @CURR_DATE;
    END
    CLOSE date_cursor;
    DEALLOCATE date_cursor;

    -- Sonuç göster
    SELECT TOP (@SUCCESS_COUNT) 
        T.TRANSACTION_ID,
        T.TRANSACTION_DATE,
        T.PRE_BALANCE,
        T.SPENT_AMOUNT,
        T.REMAINING_BALANCE,
        T.SYSTEM_TIME_
    FROM TRANSACTIONS T
    ORDER BY T.TRANSACTION_DATE ASC;
END



EXEC SP_SIMULATEBOARDINGS 
    @START_DATE = '2025-02-19',
    @END_DATE = '2026-01-31', 
    @VEHICLE_ID = NULL,  
    @RECORD_COUNT = 2;