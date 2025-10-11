CREATE PROCEDURE SP_FINAL_REPORT_DENEME
@START_DATE DATETIME = NULL,
@END_DATE DATETIME = NULL,
@REPORT_TYPE VARCHAR(20) = 'ALL',
@CARD_ID INT = NULL,
@CARD_TYPE_ID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tarih parametreleri kontrolü
    IF @START_DATE IS NULL SET @START_DATE = '1900-01-01';
    IF @END_DATE IS NULL SET @END_DATE = GETDATE();
    
    ;WITH AllTransactions AS
    (
        -- TÜM BOARDING ÝÞLEMLERÝ (Tarih filtresi YOK)
        SELECT 
            T.TRANSACTION_ID AS TXN_ID,
            T.TRANSACTION_DATE AS TXN_DATE,
            T.CARD_ID,
            'BOARDING' AS TXN_TYPE,
            -T.SPENT_AMOUNT AS AMOUNT,
            C.CARD_NO,
            CT.CARD_TYPE,
            V.PLATE,
            L.LINE_NAME,
            NULL AS CHANNEL,
            NULL AS INSTITUTION_NAME,
            NULL AS DEALER_NAME,
            C.CARD_TYPE_ID,
            -- Tarih aralýðýnda mý kontrolü
            CASE 
                WHEN CAST(T.TRANSACTION_DATE AS DATE) BETWEEN CAST(@START_DATE AS DATE) AND CAST(@END_DATE AS DATE)
                THEN 1 ELSE 0 
            END AS IN_RANGE
        FROM TRANSACTIONS T
        INNER JOIN CARDS C ON T.CARD_ID = C.CARD_ID
        INNER JOIN CARDTYPES CT ON C.CARD_TYPE_ID = CT.CARD_TYPE_ID
        LEFT JOIN VEHICLE V ON T.VEHICLE_ID = V.VEHICLE_ID
        LEFT JOIN LINES L ON V.LINE_ID = L.LINE_ID
        WHERE (@CARD_ID IS NULL OR T.CARD_ID = @CARD_ID)
        AND (@CARD_TYPE_ID IS NULL OR C.CARD_TYPE_ID = @CARD_TYPE_ID)
        
        UNION ALL
        
        -- TÜM TOPUP ÝÞLEMLERÝ (Tarih filtresi YOK)
        SELECT 
            TU.TOP_UP_TRANSACTION_ID,
            TU.TOP_UP_TRANSACTION_DATE,
            TU.CARD_ID,
            'TOPUP' AS TXN_TYPE,
            TU.AMOUNT,
            C.CARD_NO,
            CT.CARD_TYPE,
            NULL AS PLATE,
            NULL AS LINE_NAME,
            TU.TOP_UP_CHANNEL,
            I.INSTITUTION_NAME,
            ISNULL(D.DEALER_NAME, 'DIRECT'),
            C.CARD_TYPE_ID,
            CASE 
                WHEN CAST(TU.TOP_UP_TRANSACTION_DATE AS DATE) BETWEEN CAST(@START_DATE AS DATE) AND CAST(@END_DATE AS DATE)
                THEN 1 ELSE 0 
            END AS IN_RANGE
        FROM TOPUPTRANSACTIONS TU
        INNER JOIN CARDS C ON TU.CARD_ID = C.CARD_ID
        INNER JOIN CARDTYPES CT ON C.CARD_TYPE_ID = CT.CARD_TYPE_ID
        LEFT JOIN INSTITUTION I ON TU.INSTITUTION_ID = I.INSTITUTION_ID
        LEFT JOIN DEALER D ON TU.DEALER_ID = D.DEALER_ID
        WHERE (@CARD_ID IS NULL OR TU.CARD_ID = @CARD_ID)
        AND (@CARD_TYPE_ID IS NULL OR C.CARD_TYPE_ID = @CARD_TYPE_ID)
    ),
    OrderedAll AS
    (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY CARD_ID 
                ORDER BY 
                    TXN_DATE,
                    CASE WHEN TXN_TYPE = 'TOPUP' THEN 0 ELSE 1 END,
                    TXN_ID
            ) AS RN
        FROM AllTransactions
    ),
    -- Her kart için rapor baþlangýç bakiyesini hesapla
    OpeningBalances AS
    (
        SELECT 
            CARD_ID,
            -- Güncel bakiyeden rapor sonrasýndaki iþlemleri çýkar
            SUM(CASE 
                WHEN TXN_DATE > @END_DATE THEN -AMOUNT 
                ELSE 0 
            END) AS FUTURE_ADJUSTMENT
        FROM OrderedAll
        GROUP BY CARD_ID
    ),
    -- Tüm iþlemler için kümülatif bakiye hesapla
    CalculatedAll AS
    (
        SELECT 
            OA.*,
            C.BALANCE + OB.FUTURE_ADJUSTMENT + 
            SUM(OA.AMOUNT) OVER (
                PARTITION BY OA.CARD_ID 
                ORDER BY OA.RN 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS RUNNING_BALANCE
        FROM OrderedAll OA
        INNER JOIN CARDS C ON OA.CARD_ID = C.CARD_ID
        INNER JOIN OpeningBalances OB ON OA.CARD_ID = OB.CARD_ID
    )
    -- Sadece rapor tarih aralýðýndakileri göster
    SELECT 
        TXN_TYPE AS TRANSACTION_TYPE,
        TXN_ID AS TRANSACTION_ID,
        TXN_DATE AS TRANSACTION_DATE,
        CARD_ID,
        CARD_NO,
        CARD_TYPE,
        PLATE,
        LINE_NAME,
        CHANNEL,
        INSTITUTION_NAME,
        DEALER_NAME,
        -- BOARDING kolonlarý
        CASE 
            WHEN TXN_TYPE = 'BOARDING' 
            THEN RUNNING_BALANCE - AMOUNT  -- Ýþlem öncesi
            ELSE NULL 
        END AS PRE_BALANCE,
        CASE 
            WHEN TXN_TYPE = 'BOARDING' 
            THEN -AMOUNT 
            ELSE NULL 
        END AS SPENT_AMOUNT,
        CASE 
            WHEN TXN_TYPE = 'BOARDING' 
            THEN RUNNING_BALANCE  -- Ýþlem sonrasý
            ELSE NULL 
        END AS REMAINING_BALANCE,
        -- TOPUP kolonlarý
        CASE 
            WHEN TXN_TYPE = 'TOPUP' 
            THEN AMOUNT 
            ELSE NULL 
        END AS TOP_UP_AMOUNT,
        CASE 
            WHEN TXN_TYPE = 'TOPUP' 
            THEN RUNNING_BALANCE  -- Ýþlem sonrasý
            ELSE NULL 
        END AS CURRENT_BALANCE
    FROM CalculatedAll
    WHERE IN_RANGE = 1  -- Sadece tarih aralýðýndakiler
    ORDER BY 
        CARD_ID, 
        TXN_DATE,
        CASE WHEN TXN_TYPE = 'TOPUP' THEN 0 ELSE 1 END,
        TXN_ID;
END