rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb+90 \
rem dbdrv: checkfile:~PROD:~PATH:~FILE

set verify off

whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback
create or replace PACKAGE BODY      MISIMD_HZ_SPM_SYNC AS
  -- $Header: MISIMD_HZ_SPM_SYNC.plb 120.12 2018/03/16 10:02:34 rkasinad noship $
  -- =========================================================================
  -- =
  -- =
  -- Incident Bug #:
  --
  --   Copyright (c) 2005, 2017 Oracle and/or its affiliates
  --   All rights reserved.
  -- Purpose:
  --
  --   This package is used to create payload for GSI to SPM Customer Sync
  --
  -- Notes:
  --
  -- Modifications:
  --
  --   File     Date in
  --   Version  Production  Author    Modification
  --   =======  ==========  ========  ========================================
  -- =
  -- =
  --   120.0    2014/04/07  dhuramas - created
  --   120.8    2016/01/19  vetsrini - added fix for Multi Org , 22308073
  --   120.9    2016/01/20  vetsrini - copyright fix for GSCC error
  --   120.10   2016/03/22  vetsrini - adding commit
  --   120.12 2018/03/16  srechand - performance fix#27477840
  --   120.13 2018/06/01  nitesaxe - Changes for SPM-14270 CF 18.6
  --
  -- =========================================================================
  -- =
  g_cdc_target_colmap VARCHAR2(300) := 'FE03000000000000000000000000000000000000000000000000000000000000000000000000000'  ||
  '000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'   ||
  '00000000000000000000000000000000000000000000000000000000';
  /* <START> BOILERPLATE: Common helper Procedures/Global Vars for Error Logging Framework */
  g_tracefile_identifier VARCHAR2 (150) := 'MISIMD_HZ_SPM_SYNC' || TO_CHAR ( sysdate, 'DDMMHHMISS');
  g_log_level            NUMBER         := 12;
  g_trxn_reference       NUMBER         := to_number(TO_CHAR(systimestamp, 'DDMMYYYYHH24MISSFF'));
  g_trace_enabled        VARCHAR2(2)    := '-';
  PROCEDURE insert_log(
      p_module           IN VARCHAR2,
      p_audit_message    IN VARCHAR2,
      p_audit_level      IN NUMBER,
      p_context_name1    IN VARCHAR2 := NULL,
      p_context_id1      IN NUMBER   := NULL,
      p_context_name2    IN VARCHAR2 := NULL,
      p_context_id2      IN NUMBER   := NULL,
      p_context_name3    IN VARCHAR2 := NULL,
      p_context_id3      IN NUMBER   := NULL,
      p_audit_attachment IN CLOB     := NULL)
  IS
    x_dummy VARCHAR2 (30) := NULL;
  BEGIN
    IF G_TRACE_ENABLED = 'N' THEN
      RETURN;
    END IF;
    IF p_audit_level <= g_log_level THEN
      MISIMD_AUDIT.intf_log (p_transaction_reference => g_trxn_reference,
    p_audit_message => p_audit_message, p_audit_level => p_audit_level,
    p_application => 'GSI-SPM CLOUD BRIDGE', p_component=> 'MISIMD_HZ_SPM_SYNC',
    p_module => p_module, p_timestamp => systimestamp,
    p_context_name1 => p_context_name1, p_context_id1 => p_context_id1,
    p_context_name2 => p_context_name2, p_context_id2 => p_context_id2,
    p_context_name3 => p_context_name3, p_context_id3 => p_context_id3,
    p_platform => 'Oracle Database', p_audit_attachment => p_audit_attachment,
    errbuf => x_dummy);
    END IF;
  END insert_log;
  PROCEDURE init
  IS
    v_trace_level NUMBER;
  BEGIN
    IF G_TRACE_ENABLED = 'Y' THEN
      RETURN;
    END IF;
    SELECT NVL (to_number (MAX (lookup_value)), 12)
    INTO v_trace_level
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE application       = 'GSI-SPM CLOUD BRIDGE'
    AND component           = 'MISIMD_HZ_SPM_SYNC'
    AND lookup_code         = 'TRACE_LEVEL'
    AND enabled             = 'Y';
    --Fetch global log_level to determine granularity of Logging
    SELECT NVL (to_number (MAX (lookup_value)), 3)
    INTO g_log_level
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE application       = 'GSI-SPM CLOUD BRIDGE'
    AND component           = 'MISIMD_HZ_SPM_SYNC'
    AND lookup_code         = 'LOG_LEVEL'
    AND enabled             = 'Y';
    SELECT DECODE (fnd_global.conc_request_id, - 1, to_number (TO_CHAR ( systimestamp, 'DDMMYYYYHH24MISSFF')), fnd_global.conc_request_id)
    INTO g_trxn_reference
    FROM dual;
    SELECT NVL ( (MAX (lookup_value)), 'N')
    INTO G_TRACE_ENABLED
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE application       = 'GSI-SPM CLOUD BRIDGE'
    AND component           = 'MISIMD_HZ_SPM_SYNC'
    AND lookup_code = 'TRACE_ENABLED'
    AND enabled             = 'Y';
    IF G_TRACE_ENABLED      = 'Y' THEN
      MISIMD_AUDIT.enable_trace (v_trace_level, g_tracefile_identifier);
    END IF;
    insert_log (p_module =>'INIT', p_audit_message => 'Initialize Logging FWK ...', p_audit_level => 1,
  p_context_name1 => 'Requestor', p_context_id1 => fnd_global.user_id);
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END init;
  PROCEDURE insert_error(
      p_error_code    IN VARCHAR2,
      p_error_message IN VARCHAR2,
      p_module        IN VARCHAR2,
      p_context_name1 IN VARCHAR2 := NULL,
      p_context_id1   IN NUMBER   := NULL,
      p_context_name2 IN VARCHAR2 := NULL,
      p_context_id2   IN NUMBER   := NULL,
      p_context_name3 IN VARCHAR2 := NULL,
      p_context_id3   IN NUMBER   := NULL)
  IS
    x_dummy VARCHAR2 (30) := NULL;
  BEGIN
    IF G_TRACE_ENABLED = 'N' THEN
      RETURN;
    END IF;
    MISIMD_AUDIT.intf_error (p_transaction_reference =>g_trxn_reference, p_error_code => p_error_code,
  p_error_message => p_error_message, p_application => 'GSI-SPM CLOUD BRIDGE', p_component => 'MISIMD_HZ_SPM_SYNC',
  p_module => p_module, p_timestamp => systimestamp, p_context_name1 => p_context_name1,
  p_context_id1 => p_context_id1, p_context_name2 => p_context_name2, p_context_id2 => p_context_id2,
  p_context_name3 => p_context_name3, p_context_id3 => p_context_id3, p_platform => 'Oracle Database',
  p_log_details =>'Tracefile Identifier:' || g_tracefile_identifier, errbuf => x_dummy);
  END insert_error;
/* <END> BOILERPLATE: Common helper Procedures/Global Vars for Error Logging Framework */
/* <BEGIN> Local Function/Proc Signatures */
  PROCEDURE CREATE_CUST_XML_PAYLOAD(
      p_gsi_entity_id NUMBER := NULL,
      x_entity_xml OUT NOCOPY XMLTYPE);
    PROCEDURE CREATE_ADDR_XML_PAYLOAD(
        p_gsi_entity_id NUMBER := NULL,
        x_entity_xml OUT NOCOPY XMLTYPE);
      PROCEDURE CREATE_CONT_XML_PAYLOAD(
          p_gsi_entity_id NUMBER := NULL,
          x_entity_xml OUT NOCOPY XMLTYPE);
        PROCEDURE CREATE_CUST_DTLS_XML_PAYLOAD(
            p_gsi_entity_id NUMBER := NULL,
            x_entity_xml OUT NOCOPY XMLTYPE);
          PROCEDURE INSERT_CUSTOMER_ENTITY;
            PROCEDURE INSERT_CONTACT_ENTITY;
              PROCEDURE INSERT_ADDRESS_ENTITY;
                PROCEDURE INSERT_NEW_ENTITY(
                    p_gsi_entity_type VARCHAR2,
                    p_gsi_entity_id   NUMBER,
                    p_spm_entity_id   VARCHAR2,
                    p_trxn_type       VARCHAR2);
                  /* <END> Local Function/Proc Signatures */
                  /* Note:
                  The status of a message goes from PRE_STAGE-> AQ_STAGED -> PROCESSED (or ERROR)-> */
                  PROCEDURE manual_sync(
                      p_errbuf OUT NOCOPY  VARCHAR2,
                      p_retcode OUT NOCOPY NUMBER,
                      p_org_id            IN NUMBER,
                      p_cust_account_id   IN VARCHAR2,
                      p_cust_acct_site_id IN VARCHAR2,
                      p_contact_id        IN VARCHAR2,
                      p_defer             IN VARCHAR2 := 'Y' )
                  IS
                  BEGIN
                    INSERT
                    INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG
                      (
                        TRANSACTION_ID,
                        TRANSACTION_DATE,
                        TRANSACTION_TYPE,
                        SPM_ENTITY_TYPE,
                        SPM_ENTITY_ID,
                        GSI_ENTITY_TYPE,
                        GSI_ENTITY_ID,
                        cust_account_id,
                        cust_acct_site_id,
                        contact_id,
                        record_status,
                        org_id
                      )
                      VALUES
                      (
                        OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
                        sysdate,
                        'INSERT',
                        'GSI_CUSTOMER_DETAILS',
                        NULL,
                        'HZ_CUSTOMER_DETAILS',
                        p_cust_account_id,
                        p_cust_account_id,
                        p_cust_acct_site_id,
                        p_contact_id,
                        'PRE_STAGE',
                        p_org_id
                      );
                    /*
                    IF p_cust_account_id is not null THEN
                    INSERT INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG(
                    TRANSACTION_ID,
                    TRANSACTION_DATE,
                    TRANSACTION_TYPE,
                    SPM_ENTITY_TYPE,
                    SPM_ENTITY_ID,
                    GSI_ENTITY_TYPE,
                    GSI_ENTITY_ID,
                    record_status,
                    org_id)
                    VALUES (
                    OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
                    sysdate,
                    'INSERT',
                    'GSI_CUSTOMER',
                    null,
                    'HZ_CUST_ACCOUNTS',
                    p_cust_account_id,
                    'PRE_STAGE',
                    p_org_id);
                    END IF;
                    IF p_cust_acct_site_id is not null THEN
                    INSERT INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG(
                    TRANSACTION_ID,
                    TRANSACTION_DATE,
                    TRANSACTION_TYPE,
                    SPM_ENTITY_TYPE,
                    SPM_ENTITY_ID,
                    GSI_ENTITY_TYPE,
                    GSI_ENTITY_ID,
                    record_status,
                    org_id)
                    VALUES (
                    OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
                    sysdate,
                    'INSERT',
                    'GSI_ADDRESS',
                    null,
                    'HZ_CUST_ACCT_SITES_ALL',
                    p_cust_acct_site_id,
                    'PRE_STAGE',
                    p_org_id);
                    END IF;
                    IF p_contact_id is not null THEN
                    INSERT INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG(
                    TRANSACTION_ID,
                    TRANSACTION_DATE,
                    TRANSACTION_TYPE,
                    SPM_ENTITY_TYPE,
                    SPM_ENTITY_ID,
                    GSI_ENTITY_TYPE,
                    GSI_ENTITY_ID,
                    record_status,
                    org_id)
                    VALUES (
                    OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
                    sysdate,
                    'INSERT',
                    'GSI_CONTACT',
                    null,
                    'HZ_CUST_ACCOUNT_ROLES',
                    p_contact_id,
                    'PRE_STAGE',
                    p_org_id);
                    END IF;*/
                    COMMIT;
                    IF p_defer = 'N' THEN
                      START_CUST_SYNC( p_errbuf => p_errbuf, p_retcode => p_retcode );
                    END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                    p_errbuf  := 'Backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE|| '; Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK;
                    p_retcode := 1; --Return Warning
                  END manual_sync;
                PROCEDURE UPDATE_UNPROCESSED_ROWS
                IS
                  v_minutes NUMBER;
                BEGIN
                  SELECT NVL ( (MAX (lookup_value)), '300')
                  INTO v_minutes
                  FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                  WHERE application       = 'GSI-SPM CLOUD BRIDGE'
                  AND component           = 'MISIMD_HZ_SPM_SYNC'
                  AND lookup_code = 'UNPROCESSED_THRESHOLD_MINUTES'
                  AND enabled             = 'Y';
                  UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
                  SET record_status = 'ERROR',
                    record_error    = 'No Response from OSB for more than '
                    || v_minutes
                    ||' minutes'
                  WHERE transaction_id IN
                    (SELECT transaction_id
                    FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG
                    WHERE record_status  = 'AQ_STAGED'
                    AND transaction_date < sysdate - v_minutes/60/24
                    ) ;
                END UPDATE_UNPROCESSED_ROWS;
              PROCEDURE error_retry_strategy
              IS
              BEGIN
                UPDATE_UNPROCESSED_ROWS();
                -- Add retry strategy based on record_error field. For example in case of Remote fault retry
                -- AND in other cases mark for archival.
              END error_retry_strategy;
            PROCEDURE START_CUST_SYNC(
                p_errbuf OUT NOCOPY  VARCHAR2,
                p_retcode OUT NOCOPY VARCHAR2 )
            IS
              x_errbuf  VARCHAR2(500);
              x_retcode NUMBER;
            BEGIN
              init();
              insert_log (p_module =>'START_CUST_SYNC(+)', p_audit_message => 'Executing main start_cust_sync proc', p_audit_level => 1);
              g_cdc_target_colmap := MISIMD_HZ_SPM_SYNC.get_lookup('GSI-SPM CLOUD BRIDGE','CDC_TARGET_COLMAP');
              error_retry_strategy();
              CLEAR_STAGING(p_errbuf =>x_errbuf, p_retcode=> x_retcode, p_archive_type => 'SUCCESS');
              CLEAR_STAGING(p_errbuf =>x_errbuf, p_retcode=> x_retcode, p_archive_type => 'ERROR');
              EXTEND_CDC_WINDOW('SPM_CUST');
              INSERT_CHANGED_ENTITIES();
              CREATE_XML_PAYLOAD();
              PUSH_TO_AQ();
              PURGE_CDC_WINDOW('SPM_CUST');
              insert_log (p_module =>'START_CUST_SYNC(-)', p_audit_message => 'start_cust_sync proc successful', p_audit_level => 1);
            EXCEPTION
            WHEN OTHERS THEN
              insert_log (p_module =>'START_CUST_SYNC(*)', p_audit_message => 'Error Raising Business Event. Check misimd_intf_error', p_audit_level => 1);
              insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
        p_module => 'START_CUST_SYNC', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
        p_context_id1 => SQLCODE);
            END START_CUST_SYNC;
          PROCEDURE CLEAR_STAGING(
              p_errbuf OUT NOCOPY  VARCHAR2,
              p_retcode OUT NOCOPY VARCHAR2,
              p_archive_type  IN VARCHAR2 := 'PROCESSED',
              p_archive_as_of IN VARCHAR2 := TO_CHAR(
                TRUNC(
                  sysdate-7),
                'DD/MM/YYYY HH24:MI:SS') )
          IS
            CURSOR c1(p_arch_type VARCHAR2, p_arch_as_of VARCHAR2)
            IS
              SELECT *
              FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG a
              WHERE record_status   = p_arch_type
              AND transaction_date <= to_date(p_arch_as_of, 'DD/MM/YYYY HH24:MI:SS') ;
          TYPE MISIMD_SPM_CUST_STG_TT
        IS
          TABLE OF OSS_INTF_USER.MISIMD_SPM_CUST_STG%rowtype;
          v_transactions MISIMD_SPM_CUST_STG_TT;
        BEGIN
          insert_log (p_module =>'CLEAR_STAGING(+)', p_audit_message => 'Clear Staging Tables', p_audit_level => 1,
      p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
          OPEN c1(p_archive_type, p_archive_as_of );
          LOOP
            FETCH c1 BULK COLLECT INTO v_transactions LIMIT 2000;
            EXIT
          WHEN v_transactions.COUNT =0;
            FORALL i IN 1..v_transactions.COUNT
            INSERT
            INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG_ARCH
              (
                archive_date ,
                TRANSACTION_ID ,
                RECORD_STATUS ,
                RECORD_ERROR ,
                TRANSACTION_DATE ,
                TRANSACTION_TYPE ,
                GSI_ENTITY_TYPE ,
                GSI_ENTITY_ID ,
                SPM_ENTITY_TYPE ,
                SPM_ENTITY_ID ,
                REQUEST_ID ,
                PARTY_ID ,
                PARTY_NUMBER ,
                PARTY_NAME ,
                PARTY_TYPE ,
                PARTY_STATUS ,
                ORGANIZATION_NAME_PHONETIC ,
                EMAIL_ADDRESS ,
                PRIMARY_PHONE_NUMBER ,
                CUST_ACCOUNT_ID ,
                ACCOUNT_NUMBER ,
                CUST_ACCOUNT_STATUS ,
                PARTY_SITE_ID ,
                PARTY_SITE_NUMBER ,
                PARTY_SITE_STATUS ,
                LOCATION_ID ,
                ADDRESS1 ,
                ADDRESS2 ,
                ADDRESS3 ,
                ADDRESS4 ,
                POSTAL_CODE ,
                COUNTY ,
                CITY ,
                COUNTRY ,
                CONTACT_ID ,
                CUST_ACCT_SITE_ID ,
                ORG_ID ,
                CUST_ACCT_SITE_STATUS ,
                ENTITY_XML
              )
              VALUES
              (
                sysdate ,
                v_transactions(i).TRANSACTION_ID ,
                v_transactions(i).RECORD_STATUS ,
                v_transactions(i).RECORD_ERROR ,
                v_transactions(i).TRANSACTION_DATE ,
                v_transactions(i).TRANSACTION_TYPE ,
                v_transactions(i).GSI_ENTITY_TYPE ,
                v_transactions(i).GSI_ENTITY_ID ,
                v_transactions(i).SPM_ENTITY_TYPE ,
                v_transactions(i).SPM_ENTITY_ID ,
                v_transactions(i).REQUEST_ID ,
                v_transactions(i).PARTY_ID ,
                v_transactions(i).PARTY_NUMBER ,
                v_transactions(i).PARTY_NAME ,
                v_transactions(i).PARTY_TYPE ,
                v_transactions(i).PARTY_STATUS ,
                v_transactions(i).ORGANIZATION_NAME_PHONETIC ,
                v_transactions(i).EMAIL_ADDRESS ,
                v_transactions(i).PRIMARY_PHONE_NUMBER ,
                v_transactions(i).CUST_ACCOUNT_ID ,
                v_transactions(i).ACCOUNT_NUMBER ,
                v_transactions(i).CUST_ACCOUNT_STATUS ,
                v_transactions(i).PARTY_SITE_ID ,
                v_transactions(i).PARTY_SITE_NUMBER ,
                v_transactions(i).PARTY_SITE_STATUS ,
                v_transactions(i).LOCATION_ID ,
                v_transactions(i).ADDRESS1 ,
                v_transactions(i).ADDRESS2 ,
                v_transactions(i).ADDRESS3 ,
                v_transactions(i).ADDRESS4 ,
                v_transactions(i).POSTAL_CODE ,
                v_transactions(i).COUNTY ,
                v_transactions(i).CITY ,
                v_transactions(i).COUNTRY ,
                v_transactions(i).CONTACT_ID ,
                v_transactions(i).CUST_ACCT_SITE_ID ,
                v_transactions(i).ORG_ID ,
                v_transactions(i).CUST_ACCT_SITE_STATUS ,
                v_transactions(i).ENTITY_XML
              );
            FORALL i IN 1..v_transactions.count
            DELETE
            FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG
            WHERE transaction_id = v_transactions(i).transaction_id;
          END LOOP;
        CLOSE c1;
        insert_log (p_module =>'CLEAR_STAGING(-)', p_audit_message => 'Clear Staging Tables',
    p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        IF C1%isopen THEN
          CLOSE c1;
        END IF;
        insert_log (p_module =>'CLEAR_STAGING(*)', p_audit_message => 'Error Raising clearing Stage Table. Check misimd_intf_error', p_audit_level => 1);
        insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => 'CLEAR_STAGING', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127), p_context_id1 => SQLCODE);
      END CLEAR_STAGING;
      PROCEDURE INSERT_CHANGED_ENTITIES
      IS
      BEGIN
        INSERT_CUSTOMER_ENTITY();
        INSERT_ADDRESS_ENTITY();
        INSERT_CONTACT_ENTITY();
      END INSERT_CHANGED_ENTITIES;
    PROCEDURE INSERT_CUSTOMER_ENTITY
    IS
      CURSOR C1
      IS
        SELECT DISTINCT cust_account_id,
          osr.orig_system_reference ref_id
        FROM HZ_CUST_ACCOUNTS_SPM_CDC_VIEW cdc_cust,
          HZ_ORIG_SYS_REFERENCEs osr
        WHERE 1                      =1
        AND osr.owner_table_name     = 'HZ_CUST_ACCOUNTS'
        AND osr.owner_Table_id       = cdc_cust.cust_account_id
        AND osr.orig_system          = 'SPM'
        AND operation$               = 'UN'
        AND cdc_cust.TARGET_COLMAP$ <> g_cdc_target_colmap
        AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
        AND osr.status = 'A'
      UNION
      SELECT DISTINCT cust_account_id,
        osr.orig_system_reference ref_id
      FROM HZ_PARTIES_SPM_CDC_VIEW cdc_party,
        hz_cust_accounts hca,
        HZ_ORIG_SYS_REFERENCEs osr
      WHERE 1                       =1
      AND hca.party_id              = cdc_party.party_id
      AND osr.owner_table_name      = 'HZ_CUST_ACCOUNTS'
      AND osr.owner_Table_id        = hca.cust_account_id
      AND osr.orig_system           = 'SPM'
      AND cdc_party.TARGET_COLMAP$ <> g_cdc_target_colmap
      AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
      AND osr.status = 'A'
      AND operation$ = 'UN';
      v_enitites SYSTEM.NUMBER_TBL_TYPE;
      v_references SYSTEM.VARCHAR_TBL_TYPE;
    BEGIN
      insert_log (p_module =>'INSERT_CUSTOMER_ENTITY(+)', p_audit_message => 'Inserting the Customer Entity', p_audit_level => 1,
    p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
      OPEN C1;
      LOOP
        FETCH C1 BULK COLLECT INTO v_enitites, v_references LIMIT 2000;
        EXIT
      WHEN v_enitites.COUNT =0;
        /* Delete unprocessed entries from the stage which are also present in new Capture window,
        since anyway same entity is going to come through again in this new window */
        FORALL i IN 1..v_enitites.COUNT
        DELETE
        FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG
        WHERE RECORD_STATUS = ANY('AQ_STAGED', 'PRE_STAGE')
        AND gsi_entity_type = 'HZ_CUST_ACCOUNTS'
        AND GSI_entity_id   = v_enitites(i);
        FORALL i IN 1..v_enitites.COUNT
        INSERT
        INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG
          (
            TRANSACTION_ID,
            TRANSACTION_DATE,
            TRANSACTION_TYPE,
            SPM_ENTITY_TYPE,
            SPM_ENTITY_ID,
            GSI_ENTITY_TYPE,
            GSI_ENTITY_ID,
            record_status
          )
          VALUES
          (
            OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
            sysdate,
            'UPDATE',
            'GSI_CUSTOMER',
            v_references(i),
            'HZ_CUST_ACCOUNTS',
            v_enitites(i),
            'PRE_STAGE'
          );
        COMMIT;
      END LOOP;
      insert_log (p_module =>'INSERT_CUSTOMER_ENTITY(-)', p_audit_message => 'Inserting the Customer Entity', p_audit_level => 1,
    p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
    END INSERT_CUSTOMER_ENTITY;
  PROCEDURE INSERT_ADDRESS_ENTITY
  IS
    CURSOR C1
    IS
      SELECT DISTINCT hcas.cust_acct_site_id,
        osr.orig_system_reference ref_id
      FROM hz_cust_acct_sites_all hcas,
        hz_party_sites hps,
        hz_locations hl,
        hz_orig_sys_references osr
      WHERE 1                    =1
      AND osr.owner_table_name   = 'HZ_CUST_ACCT_SITES_ALL'
      AND hcas.cust_acct_site_id = osr.owner_table_id
      AND osr.orig_system        = 'SPM'
      AND hps.party_site_id      = hcas.party_site_id
      AND hps.location_id        = hl.location_id
      AND hl.location_id        IN
        (SELECT location_id
        FROM HZ_LOCATIONS_SPM_CDC_VIEW
        WHERE 1             =1
        AND operation$      = 'UN'
        AND TARGET_COLMAP$ <> g_cdc_target_colmap
        )
    AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
    AND osr.status = 'A'
    UNION
    SELECT DISTINCT hcas.cust_acct_site_id,
      osr.orig_system_reference ref_id
    FROM hz_cust_acct_sites_all hcas,
      hz_party_sites hps,
      hz_orig_sys_references osr
    WHERE 1                    =1
    AND osr.owner_table_name   = 'HZ_CUST_ACCT_SITES_ALL'
    AND hcas.cust_acct_site_id = osr.owner_table_id
    AND osr.orig_system        = 'SPM'
    AND hps.party_site_id      = hcas.party_site_id
    AND hps.party_site_id     IN
      (SELECT party_site_id
      FROM HZ_PARTY_SITES_SPM_CDC_VIEW
      WHERE 1             =1
      AND operation$      = 'UN'
      AND TARGET_COLMAP$ <> g_cdc_target_colmap
      )
    AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
    AND osr.status = 'A'
    UNION
    SELECT DISTINCT hcas.cust_acct_site_id,
      osr.orig_system_reference ref_id
    FROM hz_cust_acct_sites_all hcas,
      hz_orig_sys_references osr
    WHERE 1                     =1
    AND osr.owner_table_name    = 'HZ_CUST_ACCT_SITES_ALL'
    AND hcas.cust_acct_site_id  = osr.owner_table_id
    AND osr.orig_system         = 'SPM'
    AND hcas.cust_acct_site_id IN
      (SELECT cust_acct_site_id
      FROM HZ_ACCT_SITES_SPM_CDC_VIEW
      WHERE 1             =1
      AND operation$      = 'UN'
      AND TARGET_COLMAP$ <> g_cdc_target_colmap
      )
    AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
    AND osr.status = 'A';
    v_enitites SYSTEM.NUMBER_TBL_TYPE;
    v_references SYSTEM.VARCHAR_TBL_TYPE;
  BEGIN
    insert_log (p_module =>'INSERT_ADDRESS_ENTITY(+)', p_audit_message => 'Inserting the Address entities', p_audit_level => 1,
  p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
    OPEN C1;
    LOOP
      FETCH C1 BULK COLLECT INTO v_enitites, v_references LIMIT 2000;
      EXIT
    WHEN v_enitites.COUNT =0;
      /* Delete unprocessed entries from the stage which are also present in new Capture window,
      since anyway same entity is going to come through again in this new window */
      FORALL i IN 1..v_enitites.COUNT
      DELETE
      FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG
      WHERE RECORD_STATUS = ANY('AQ_STAGED', 'PRE_STAGE')
      AND gsi_entity_type = 'HZ_CUST_ACCTS_SITES_ALL'
      AND GSI_entity_id   = v_enitites(i);
      FORALL i IN 1..v_enitites.COUNT
      INSERT
      INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG
        (
          TRANSACTION_ID,
          TRANSACTION_DATE,
          TRANSACTION_TYPE,
          SPM_ENTITY_TYPE,
          SPM_ENTITY_ID,
          GSI_ENTITY_TYPE,
          GSI_ENTITY_ID,
          record_status
        )
        VALUES
        (
          OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
          sysdate,
          'UPDATE',
          'GSI_ADDRESS',
          v_references(i),
          'HZ_CUST_ACCT_SITES_ALL',
          v_enitites(i),
          'PRE_STAGE'
        );
      COMMIT;
    END LOOP;
    insert_log (p_module =>'INSERT_ADDRESS_ENTITY(-)', p_audit_message => 'Inserting the Address entities', p_audit_level => 1,
  p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
  END INSERT_ADDRESS_ENTITY;
  PROCEDURE INSERT_CONTACT_ENTITY
  IS
    CURSOR C1
    IS
      SELECT DISTINCT cust_account_role_id,
        osr.orig_system_reference ref_id
      FROM hz_cust_Account_roles hcar,
        hz_orig_sys_references osr
      WHERE 1                       =1
      AND osr.owner_table_name      = 'HZ_CUST_ACCOUNT_ROLES'
      AND hcar.cust_account_role_id = osr.owner_table_id
      AND osr.orig_system           = 'SPM'
      AND hcar.role_type            = 'CONTACT'
      AND hcar.party_id            IN
        (SELECT party_id
        FROM HZ_PARTIES_SPM_CDC_VIEW
        WHERE party_type    = 'PARTY_RELATIONSHIP'
        AND operation$      = 'UN'
        AND TARGET_COLMAP$ <> g_cdc_target_colmap
        )
    AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
    AND osr.status = 'A'
    UNION
    SELECT DISTINCT cust_account_role_id,
      osr.orig_system_reference ref_id
    FROM hz_cust_Account_roles hcar,
      hz_orig_sys_references osr,
      hz_relationships hr
    WHERE 1                       =1
    AND osr.owner_table_name      = 'HZ_CUST_ACCOUNT_ROLES'
    AND hcar.cust_account_role_id = osr.owner_table_id
    AND osr.orig_system           = 'SPM'
    AND hcar.role_type            = 'CONTACT'
    AND hr.party_id               = hcar.party_id
    AND hr.subject_id            IN
      (SELECT party_id
      FROM HZ_PARTIES_SPM_CDC_VIEW
      WHERE party_type    = 'PERSON'
      AND operation$      = 'UN'
      AND TARGET_COLMAP$ <> g_cdc_target_colmap
      )
    AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
    AND osr.status           = 'A'
    AND hr.subject_type      = 'PERSON'
    AND hr.relationship_code = 'CONTACT_OF';
    v_enitites SYSTEM.NUMBER_TBL_TYPE;
    v_references SYSTEM.VARCHAR_TBL_TYPE;
  BEGIN
    insert_log (p_module =>'INSERT_CONTACT_ENTITY(+)', p_audit_message => 'Inserting the Contact entities', p_audit_level => 1,
  p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
    OPEN C1;
    LOOP
      FETCH C1 BULK COLLECT INTO v_enitites, v_references LIMIT 2000;
      EXIT
    WHEN v_enitites.COUNT =0;
      /* Delete unprocessed entries from the stage which are also present in new Capture window,
      since anyway same entity is going to come through again in this new window */
      FORALL i IN 1..v_enitites.COUNT
      DELETE
      FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG
      WHERE RECORD_STATUS = ANY('AQ_STAGED', 'PRE_STAGE')
      AND gsi_entity_type = 'HZ_CUST_ACCOUNT_ROLES'
      AND GSI_entity_id   = v_enitites(i);
      FORALL i IN 1..v_enitites.COUNT
      INSERT
      INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG
        (
          TRANSACTION_ID,
          TRANSACTION_DATE,
          TRANSACTION_TYPE,
          SPM_ENTITY_TYPE,
          SPM_ENTITY_ID,
          GSI_ENTITY_TYPE,
          GSI_ENTITY_ID,
          record_status
        )
        VALUES
        (
          OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
          sysdate,
          'UPDATE',
          'GSI_CONTACT',
          v_references(i),
          'HZ_CUST_ACCOUNT_ROLES',
          v_enitites(i),
          'PRE_STAGE'
        );
      COMMIT;
    END LOOP;
    insert_log (p_module =>'INSERT_CONTACT_ENTITY(+)', p_audit_message => 'Inserting the Contact entities', p_audit_level => 1,
  p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
  END INSERT_CONTACT_ENTITY;
  PROCEDURE CREATE_XML_PAYLOAD
  IS
    v_dummy xmltype;
  BEGIN
    --Create and Store XML Payload in stage table before queuing to AQ
    CREATE_ADDR_XML_PAYLOAD(NULL, v_dummy);
    CREATE_CUST_XML_PAYLOAD(NULL, v_dummy);
    CREATE_CONT_XML_PAYLOAD(NULL, v_dummy);
    CREATE_CUST_DTLS_XML_PAYLOAD(NULL, v_dummy);
  EXCEPTION
  WHEN OTHERS THEN
    insert_log (p_module =>'CREATE_XML_PAYLOAD(*)', p_audit_message => 'Error Raising creating XML. Check misimd_intf_error', p_audit_level => 1);
    insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
  p_module => 'CREATE_XML_PAYLOAD', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127), p_context_id1 => SQLCODE);
    raise;
  END CREATE_XML_PAYLOAD;
  PROCEDURE CREATE_CUST_XML_PAYLOAD
    (
      p_gsi_entity_id NUMBER := NULL,
      x_entity_xml OUT NOCOPY XMLTYPE
    )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    CURSOR c1
    IS
      SELECT xmlelement("SPM_CUST_SYNC_PAYLOAD", xmlconcat( xmlelement("TRANSACTION_ID", stage.transaction_id),
    xmlelement("TRANSACTION_TYPE", transaction_type), xmlelement("SPM_ENTITY_TYPE", SPM_ENTITY_TYPE),
    xmlelement("SPM_ENTITY_ID", SPM_ENTITY_ID), xmlelement("GSI_ORG_ID", COALESCE(stage.org_id, 1001) ),
    sys_xmlgen( OSS_INTF_USER.MISIMD_SPM_CUSTOMER( party.party_id
        /*PARTY_ID*/
        ,
        (SELECT parent_id
        FROM hz_hierarchy_nodes pp,
          hz_parties hp
        WHERE pp.parent_id = hp.party_id
        AND level_number   =
          (SELECT MAX (level_number)
          FROM hz_hierarchy_nodes cp
          WHERE cp.child_id = pp.child_id
          AND sysdate BETWEEN cp.effective_start_date AND cp.effective_end_date
          AND hierarchy_type = 'Support360 - Parent/Subsidiary'
          )
      AND hierarchy_type = 'Support360 - Parent/Subsidiary'
      AND sysdate BETWEEN pp.effective_start_date AND pp.effective_end_date
      AND pp.child_id = party.party_id
      AND rownum      < 2
        )
        /*PARENT_PARTY_ID*/
        , party.party_number
        /*PARTY_NUMBER */
        , party.party_name
        /*PARTY_NAME */
        , party.party_type
        /*PARTY_TYPE */
        , party.jgzz_fiscal_code
        /*TAX_ID */
        , party.organization_name_phonetic
        /*TRANSLATED_NAME */
        , party.url
        /*URL */
        , hca.cust_account_id
        /*TCA_CUST_ACCOUNT_ID */
        , hca.account_number
        /*CUST_ACCOUNT_NUMBER */
        , NULL
        /*PARTY_SITE_ID */
        , NULL
        /*PARTY_SITE_NUMBER */
        , NULL
        /*CUST_ACCT_SITE_ID */
        , NULL
        /*LOCATION_ID */
        , NULL
        /*ADDRESS1 */
        , NULL
        /*ADDRESS2 */
        , NULL
        /*CITY */
        , NULL
        /*POSTAL_CODE */
        , NULL
        /*STATE */
        , NULL
        /*COUNTRY */
        , NULL
        /*SITE_USE_TYPE */
        , NULL
        /*SITE_USE_ID */
        , NULL
        /*CONTACT_ID */
        , NULL
        /*CONTACT_FIRST_NAME */
        , NULL
        /*CONTACT_LAST_NAME */
        , NULL
        /*CONTACT_EMAIL */
        , NULL
        /*CONTACT_PHONE */
        , NULL
        /*CONTACT_PARTY_ID */
        , NULL
        /*CONTACT_CUST_ACCT_ROLE_ID */
        , NULL
        /*CONTACT_CUST_ACCT_SITE_ID */
        , NULL
        /*BILL_TO_SITE_USE_ID */
        , NULL
        /*SHIP_TO_SITE_USE_ID */
        , 
        (SELECT NVL(
          (SELECT class_code
          FROM hz_code_assignments
          WHERE owner_table_name = 'HZ_PARTIES'
          AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
          AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
          AND owner_table_id = party.party_id
          ) , 'No')
        FROM DUAL
        )
        /*IS_PUBLIC_SECTOR */
        , 
        (SELECT NVL(
          (SELECT 'Yes'
          FROM hz_code_assignments
          WHERE owner_table_name = 'HZ_PARTIES'
          AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
          AND CLASS_CATEGORY = 'CHAIN'
          AND CLASS_CODE    IS NOT NULL
          AND owner_table_id = party.party_id
          ),'No')
        FROM DUAL
        )
        /*IS_CHAIN_CUSTOMER */
        ,
        (SELECT class_code
         FROM hz_code_assignments
         WHERE owner_table_name = 'HZ_PARTIES'
         AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
         AND CLASS_CATEGORY = 'CHAIN'
         AND CLASS_CODE    IS NOT NULL
         AND owner_table_id = party.party_id
        )
        /*CUSTOMER_CHAIN_TYPE */
        ), xmlformat.createformat ( 'MISIMD_SPM_CUSTOMER')))),
        transaction_id
      FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG stage,
        hz_cust_accounts hca,
        hz_parties party
      WHERE stage.GSI_ENTITY_TYPE                   = 'HZ_CUST_ACCOUNTS'
      AND NVL(p_gsi_entity_id, hca.cust_account_id) = stage.gsi_entity_id
      AND stage.record_status                       = 'PRE_STAGE'
      AND hca.cust_Account_id                       = stage.gsi_entity_id
      AND hca.party_id                              = party.party_id
      ORDER BY stage.transaction_date DESC;
      v_entity_xml SYS.XMLSEQUENCETYPE;
      v_trxn_ids SYSTEM.NUMBER_TBL_TYPE;
      v_transaction_id NUMBER;
    BEGIN
      insert_log (p_module =>'CREATE_CUST_XML_PAYLOAD(+)', p_audit_message => 'Inserting the Customer XML(s)',
    p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
    p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
      OPEN c1;
      IF (p_gsi_entity_id IS NOT NULL) THEN --For Standalone procedure call
        FETCH c1 INTO x_entity_xml, v_transaction_id;
        UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
        SET entity_xml       = x_entity_xml,
          record_status      = 'AQ_STAGED'
        WHERE transaction_id = v_transaction_id
        AND record_status    = 'PRE_STAGE';
        COMMIT;
        CLOSE c1;
        RETURN;
      END IF;
      LOOP
        FETCH c1 BULK COLLECT INTO v_entity_xml, v_trxn_ids LIMIT 2000;
        EXIT
      WHEN v_trxn_ids.COUNT = 0;
        FORALL i IN 1..v_trxn_ids.COUNT
        UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
        SET entity_xml       = v_entity_xml(i),
          transaction_date   = sysdate
        WHERE transaction_id = v_trxn_ids(i)
        AND record_status    = 'PRE_STAGE';
        COMMIT;
        PUSH_TO_AQ('HZ_CUST_ACCOUNTS');
      END LOOP;
      CLOSE c1;
      insert_log (p_module =>'CREATE_CUST_XML_PAYLOAD(-)', p_audit_message => 'Inserting the Customer XML(s)',
    p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
    p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
    EXCEPTION
    WHEN OTHERS THEN
      CLOSE c1;
      x_entity_xml := NULL;
      insert_log (p_module =>'CREATE_CUST_XML_PAYLOAD(*)', p_audit_message => 'Error creating XML. Check misimd_intf_error', p_audit_level => 1);
      insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => 'CREATE_CUST_XML_PAYLOAD', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127), p_context_id1 => SQLCODE);
    END CREATE_CUST_XML_PAYLOAD;
    PROCEDURE CREATE_CUST_DTLS_XML_PAYLOAD(
        p_gsi_entity_id NUMBER := NULL,
        x_entity_xml OUT NOCOPY XMLTYPE)
    IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      CURSOR c1
      IS
        SELECT xmlelement("SPM_CUST_SYNC_PAYLOAD", xmlconcat( xmlelement("TRANSACTION_ID", stage.transaction_id),
    xmlelement("TRANSACTION_TYPE", transaction_type), xmlelement("SPM_ENTITY_TYPE", SPM_ENTITY_TYPE),
    xmlelement("SPM_ENTITY_ID", SPM_ENTITY_ID), xmlelement("GSI_ORG_ID", COALESCE(stage.org_id, 1001)),
    sys_xmlgen ( OSS_INTF_USER.MISIMD_SPM_CUSTOMER( party.party_id
          /*PARTY_ID*/
          ,
          (SELECT parent_id
          FROM hz_hierarchy_nodes pp,
            hz_parties hp
          WHERE pp.parent_id = hp.party_id
          AND level_number   =
            (SELECT MAX (level_number)
            FROM hz_hierarchy_nodes cp
            WHERE cp.child_id = pp.child_id
            AND sysdate BETWEEN cp.effective_start_date AND cp.effective_end_date
            AND hierarchy_type = 'Support360 - Parent/Subsidiary'
            )
        AND hierarchy_type = 'Support360 - Parent/Subsidiary'
        AND sysdate BETWEEN pp.effective_start_date AND pp.effective_end_date
        AND pp.child_id = party.party_id
        AND rownum      < 2
          )
          /*PARENT_PARTY_ID*/
          , party.party_number
          /*PARTY_NUMBER */
          , party.party_name
          /*PARTY_NAME */
          , party.party_type
          /*PARTY_TYPE */
          , party.jgzz_fiscal_code
          /*TAX_ID */
          , party.organization_name_phonetic
          /*TRANSLATED_NAME */
          , party.url
          /*URL */
          , hca.cust_account_id
          /*TCA_CUST_ACCOUNT_ID */
          , hca.account_number
          /*CUST_ACCOUNT_NUMBER */
          , NULL
          /*PARTY_SITE_ID */
          , NULL
          /*PARTY_SITE_NUMBER */
          , NULL
          /*CUST_ACCT_SITE_ID */
          , NULL
          /*LOCATION_ID */
          , NULL
          /*ADDRESS1 */
          , NULL
          /*ADDRESS2 */
          , NULL
          /*CITY */
          , NULL
          /*POSTAL_CODE */
          , NULL
          /*STATE */
          , NULL
          /*COUNTRY */
          , NULL
          /*SITE_USE_TYPE */
          , NULL
          /*SITE_USE_ID */
          , NULL
          /*CONTACT_ID */
          , NULL
          /*CONTACT_FIRST_NAME */
          , NULL
          /*CONTACT_LAST_NAME */
          , NULL
          /*CONTACT_EMAIL */
          , NULL
          /*CONTACT_PHONE */
          , NULL
          /*CONTACT_PARTY_ID */
          , NULL
          /*CONTACT_CUST_ACCT_ROLE_ID */
          , NULL
          /*CONTACT_CUST_ACCT_SITE_ID */
          , NULL
          /*BILL_TO_SITE_USE_ID */
          , NULL
          /*SHIP_TO_SITE_USE_ID */
          , 
          (SELECT NVL(
            (SELECT class_code
            FROM hz_code_assignments
            WHERE owner_table_name = 'HZ_PARTIES'
            AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
            AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
            AND owner_table_id = party.party_id
            ) , 'No')
          FROM DUAL
          )
          /*IS_PUBLIC_SECTOR */
          , 
          (SELECT NVL(
            (SELECT 'Yes'
            FROM hz_code_assignments
            WHERE owner_table_name = 'HZ_PARTIES'
            AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
            AND CLASS_CATEGORY = 'CHAIN'
            AND CLASS_CODE    IS NOT NULL
            AND owner_table_id = party.party_id
            ),'No')
          FROM DUAL
          )
          /*IS_CHAIN_CUSTOMER */
          ,
          (SELECT class_code
           FROM hz_code_assignments
           WHERE owner_table_name = 'HZ_PARTIES'
           AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
           AND CLASS_CATEGORY = 'CHAIN'
           AND CLASS_CODE    IS NOT NULL
           AND owner_table_id = party.party_id
          )
         /*CUSTOMER_CHAIN_TYPE */
          ), xmlformat.createformat ( 'MISIMD_SPM_CUSTOMER') ), sys_xmlgen( oss_intf_user.misimd_spm_customer( NULL
          /*PARTY_ID*/
          , NULL
          /*PARENT_PARTY_ID*/
          , NULL
          /*PARTY_NUMBER */
          , NULL
          /*PARTY_NAME */
          , NULL
          /*PARTY_TYPE */
          , NULL
          /*TAX_ID */
          , NULL
          /*TRANSLATED_NAME */
          , NULL
          /*URL */
          , NULL
          /*TCA_CUST_ACCOUNT_ID */
          , NULL
          /*CUST_ACCOUNT_NUMBER */
          , hps.party_site_id
          /*PARTY_SITE_ID */
          , hps.party_site_number
          /*PARTY_SITE_NUMBER */
          , hcas.cust_acct_Site_id
          /*CUST_ACCT_SITE_ID */
          , hl.location_id
          /*LOCATION_ID */
          , hl.address1
          /*ADDRESS1 */
          , hl.address2
          /*ADDRESS2 */
          , hl.city
          /*CITY */
          , hl.postal_code
          /*POSTAL_CODE */
          , COALESCE(hl.state, hl.province)
          /*STATE */
          , hl.country
          /*COUNTRY */
          , 'BILL_TO'
          /*SITE_USE_TYPE- DONT USE */
          , hcsua_bill.site_use_id
          /*SITE_USE_ID - DONT USE */
          , NULL
          /*CONTACT_ID */
          , NULL
          /*CONTACT_FIRST_NAME */
          , NULL
          /*CONTACT_LAST_NAME */
          , NULL
          /*CONTACT_EMAIL */
          , NULL
          /*CONTACT_PHONE */
          , NULL
          /*CONTACT_PARTY_ID */
          , NULL
          /*CONTACT_CUST_ACCT_ROLE_ID */
          , NULL
          /*CONTACT_CUST_ACCT_SITE_ID */
          , hcsua_bill.site_use_id
          /*BILL_TO_SITE_USE_ID */
          , hcsua_ship.site_use_id
          /*SHIP_TO_SITE_USE_ID */
          , NULL
          /*IS_PUBLIC_SECTOR */
          , NULL
          /*IS_CHAIN_CUSTOMER */
          , NULL
          /*CUSTOMER_CHAIN_TYPE */
          ), xmlformat.createformat ( 'MISIMD_SPM_ADDRESS') ) ,
          (SELECT xmlconcat( sys_xmlgen( oss_intf_user.misimd_spm_customer( NULL
            /*PARTY_ID*/
            , NULL
            /*PARENT_PARTY_ID*/
            , NULL
            /*PARTY_NUMBER */
            , NULL
            /*PARTY_NAME */
            , NULL
            /*PARTY_TYPE */
            , NULL
            /*TAX_ID */
            , NULL
            /*TRANSLATED_NAME */
            , NULL
            /*URL */
            , NULL
            /*TCA_CUST_ACCOUNT_ID */
            , NULL
            /*CUST_ACCOUNT_NUMBER */
            , NULL
            /*PARTY_SITE_ID */
            , NULL
            /*PARTY_SITE_NUMBER */
            , NULL
            /*CUST_ACCT_SITE_ID */
            , NULL
            /*LOCATION_ID */
            , NULL
            /*ADDRESS1 */
            , NULL
            /*ADDRESS2 */
            , NULL
            /*CITY */
            , NULL
            /*POSTAL_CODE */
            , NULL
            /*STATE */
            , NULL
            /*COUNTRY */
            , NULL
            /*SITE_USE_TYPE */
            , NULL
            /*SITE_USE_ID */
            , hcar.cust_account_role_id
            /*CONTACT_ID */
            , person.person_first_name
            /*CONTACT_FIRST_NAME */
            , person.person_last_name
            /*CONTACT_LAST_NAME */
            ,
            (SELECT email_address
            FROM hz_contact_points hcpe
            WHERE hcpe.owner_table_id = hcar.party_id
            AND hcpe.owner_table_name = 'HZ_PARTIES'
            AND contact_point_type    = 'EMAIL'
            AND hcpe.primary_flag     = 'Y'
            AND rownum                < 2
            )
            /*CONTACT_EMAIL */
            ,
            (SELECT
              /*Warning: Reverse() is an undocumented Oracle SQL function*/
              reverse(TO_CHAR(transposed_phone_number))
            FROM hz_contact_points hcpe
            WHERE hcpe.owner_table_id = hcar.party_id
            AND hcpe.owner_table_name = 'HZ_PARTIES'
            AND hcpe.primary_flag     = 'Y'
            AND contact_point_type    = 'PHONE'
            AND rownum                < 2
            )
            /*CONTACT_PHONE */
            , person.party_id
            /*CONTACT_PARTY_ID */
            , hcar.cust_account_role_id
            /*CONTACT_CUST_ACCT_ROLE_ID */
            , hcar.cust_acct_site_id
            /*CONTACT_CUST_ACCT_SITE_ID */
            , NULL
            /*BILL_TO_SITE_USE_ID */
            , NULL
            /*SHIP_TO_SITE_USE_ID */
            , NULL
            /*IS_PUBLIC_SECTOR */
            , NULL
            /*IS_CHAIN_CUSTOMER */
            , NULL
            /*CUSTOMER_CHAIN_TYPE */
            ), xmlformat.createformat ( 'MISIMD_SPM_CONTACT') ))
          FROM hz_parties person,
            hz_relationships hr,
            hz_parties rel,
            hz_parties party,
            hz_cust_account_roles hcar,
            hz_cust_accounts hca
          WHERE 1                   =1
          AND person.party_type     = 'PERSON'
          AND person.party_id       = hr.subject_id
          AND hr.subject_type       = 'PERSON'
          AND hr.relationship_code  = 'CONTACT_OF'
          AND hr.object_id          = party.party_id
          AND hr.object_type        = 'ORGANIZATION'
          AND party.party_type      = hr.object_type
          AND hcar.party_id         = hr.party_id
          AND hcar.cust_account_id  = hca.cust_account_id
          AND stage.record_status   = 'PRE_STAGE'
          AND stage.contact_id      = hcar.cust_account_role_id
          AND stage.gsi_entity_type = 'HZ_CUSTOMER_DETAILS'
          AND rel.party_id          = hcar.party_id
          AND rel.party_type        = 'PARTY_RELATIONSHIP'
          ) )),
          transaction_id
        FROM hz_cust_acct_sites_all hcas
        LEFT OUTER JOIN hz_cust_site_uses_all hcsua_bill
        ON (hcsua_bill.cust_acct_site_id = hcas.cust_acct_site_id
        AND hcsua_bill.site_use_code     = 'BILL_TO')
        LEFT OUTER JOIN hz_cust_site_uses_all hcsua_ship
        ON (hcsua_ship.cust_acct_site_id = hcas.cust_acct_site_id
        AND hcsua_ship.site_use_code     = 'SHIP_TO'),
          hz_party_sites hps,
          hz_locations hl,
          hz_cust_accounts hca,
          hz_parties party,
          OSS_INTF_USER.MISIMD_SPM_CUST_STG stage
        WHERE 1                    =1
        AND hca.cust_account_id    = hcas.cust_account_id
        AND party.party_id         = hca.party_id
        AND stage.gsi_entity_type  = 'HZ_CUSTOMER_DETAILS'
        AND stage.record_status    = 'PRE_STAGE'
        AND hcas.cust_acct_site_id = stage.cust_acct_site_id
        AND hcas.party_site_id     = hps.party_site_id
        AND hl.location_id         = hps.location_id
          --and stage.transaction_id = 1603957
        ORDER BY stage.transaction_date DESC;
        v_entity_xml SYS.XMLSEQUENCETYPE;
        v_trxn_ids SYSTEM.NUMBER_TBL_TYPE;
        v_transaction_id NUMBER;
      BEGIN
        insert_log (p_module =>'CREATE_CUST_DTLS_XML_PAYLOAD(+)', p_audit_message => 'Inserting the Customer XML(s)',
    p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
    p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
        OPEN c1;
        IF (p_gsi_entity_id IS NOT NULL) THEN --For Standalone procedure call
          FETCH c1 INTO x_entity_xml, v_transaction_id;
          UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
          SET entity_xml       = x_entity_xml,
            record_status      = 'AQ_STAGED'
          WHERE transaction_id = v_transaction_id
          AND record_status    = 'PRE_STAGE';
          COMMIT;
          CLOSE c1;
          RETURN;
        END IF;
        LOOP
          FETCH c1 BULK COLLECT INTO v_entity_xml, v_trxn_ids LIMIT 2000;
          EXIT
        WHEN v_trxn_ids.COUNT = 0;
          FORALL i IN 1..v_trxn_ids.COUNT
          UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
          SET entity_xml       = v_entity_xml(i),
            transaction_date   = sysdate
          WHERE transaction_id = v_trxn_ids(i)
          AND record_status    = 'PRE_STAGE';
          COMMIT;
        END LOOP;
        CLOSE c1;
        insert_log (p_module =>'CREATE_CUST_DTLS_XML_PAYLOAD(-)', p_audit_message => 'Inserting the Customer XML(s)',
    p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
    p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
      EXCEPTION
      WHEN OTHERS THEN
        CLOSE c1;
        x_entity_xml := NULL;
        insert_log (p_module =>'CREATE_CUST_DTLS_XML_PAYLOAD(*)', p_audit_message => 'Error creating XML. Check misimd_intf_error', p_audit_level => 1);
        insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => 'CREATE_CUST_DTLS_XML_PAYLOAD', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127), p_context_id1 => SQLCODE);
      END CREATE_CUST_DTLS_XML_PAYLOAD;
      PROCEDURE CREATE_CONT_XML_PAYLOAD(
          p_gsi_entity_id NUMBER := NULL,
          x_entity_xml OUT NOCOPY XMLTYPE)
      IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        CURSOR c1
        IS
          SELECT xmlelement("SPM_CUST_SYNC_PAYLOAD", xmlconcat( xmlelement("TRANSACTION_ID", stage.transaction_id),
      xmlelement("TRANSACTION_TYPE", transaction_type), xmlelement("SPM_ENTITY_TYPE", SPM_ENTITY_TYPE),
      xmlelement("SPM_ENTITY_ID", SPM_ENTITY_ID), xmlelement("GSI_ORG_ID", COALESCE(stage.org_id, 1001)),
      sys_xmlgen( OSS_INTF_USER.MISIMD_SPM_CUSTOMER( party.party_id
            /*PARTY_ID*/
            ,
            (SELECT parent_id
            FROM hz_hierarchy_nodes pp,
              hz_parties hp
            WHERE pp.parent_id = hp.party_id
            AND level_number   =
              (SELECT MAX (level_number)
              FROM hz_hierarchy_nodes cp
              WHERE cp.child_id = pp.child_id
              AND sysdate BETWEEN cp.effective_start_date AND cp.effective_end_date
              AND hierarchy_type = 'Support360 - Parent/Subsidiary'
              )
          AND hierarchy_type = 'Support360 - Parent/Subsidiary'
          AND sysdate BETWEEN pp.effective_start_date AND pp.effective_end_date
          AND pp.child_id = party.party_id
          AND rownum      < 2
            )
            /*PARENT_PARTY_ID*/
            , party.party_number
            /*PARTY_NUMBER */
            , party.party_name
            /*PARTY_NAME */
            , party.party_type
            /*PARTY_TYPE */
            , party.jgzz_fiscal_code
            /*TAX_ID */
            , party.organization_name_phonetic
            /*TRANSLATED_NAME */
            , party.url
            /*URL */
            , hca.cust_account_id
            /*TCA_CUST_ACCOUNT_ID */
            , hca.account_number
            /*CUST_ACCOUNT_NUMBER */
            , NULL
            /*PARTY_SITE_ID */
            , NULL
            /*PARTY_SITE_NUMBER */
            , NULL
            /*CUST_ACCT_SITE_ID */
            , NULL
            /*LOCATION_ID */
            , NULL
            /*ADDRESS1 */
            , NULL
            /*ADDRESS2 */
            , NULL
            /*CITY */
            , NULL
            /*POSTAL_CODE */
            , NULL
            /*STATE */
            , NULL
            /*COUNTRY */
            , NULL
            /*SITE_USE_TYPE */
            , NULL
            /*SITE_USE_ID */
            , hcar.cust_account_role_id
            /*CONTACT_ID */
            , person.person_first_name
            /*CONTACT_FIRST_NAME */
            , person.person_last_name
            /*CONTACT_LAST_NAME */
            ,
            (SELECT email_address
            FROM hz_contact_points hcpe
            WHERE hcpe.owner_table_id = hcar.party_id
            AND hcpe.owner_table_name = 'HZ_PARTIES'
            AND contact_point_type    = 'EMAIL'
            AND hcpe.primary_flag     = 'Y'
            AND rownum                < 2
            )
            /*CONTACT_EMAIL */
            ,
            (SELECT
              /*Warning: Reverse() is an undocumented Oracle SQL function*/
              reverse(TO_CHAR(transposed_phone_number))
            FROM hz_contact_points hcpe
            WHERE hcpe.owner_table_id = hcar.party_id
            AND hcpe.owner_table_name = 'HZ_PARTIES'
            AND hcpe.primary_flag     = 'Y'
            AND contact_point_type    = 'PHONE'
            AND rownum                < 2
            )
            /*CONTACT_PHONE */
            , person.party_id
            /*CONTACT_PARTY_ID */
            , hcar.cust_account_role_id
            /*CONTACT_CUST_ACCT_ROLE_ID */
            , hcar.cust_acct_site_id
            /*CONTACT_CUST_ACCT_SITE_ID */
            , NULL
            /*BILL_TO_SITE_USE_ID */
            , NULL
            /*SHIP_TO_SITE_USE_ID */
            , NULL
            /*IS_PUBLIC_SECTOR */
            , NULL
            /*IS_CHAIN_CUSTOMER */
            , NULL
            /*CUSTOMER_CHAIN_TYPE */
            ), xmlformat.createformat ( 'MISIMD_SPM_CONTACT') ))),
            transaction_id
          FROM hz_parties person,
            hz_relationships hr,
            hz_parties rel,
            hz_parties party,
            hz_cust_account_roles hcar,
            hz_cust_accounts hca,
            OSS_INTF_USER.MISIMD_SPM_CUST_STG stage
          WHERE 1                                             =1
          AND person.party_type                               = 'PERSON'
          AND person.party_id                                 = hr.subject_id
          AND hr.subject_type                                 = 'PERSON'
          AND hr.relationship_code                            = 'CONTACT_OF'
          AND hr.object_id                                    = party.party_id
          AND hr.object_type                                  = 'ORGANIZATION'
          AND party.party_type                                = hr.object_type
          AND hcar.party_id                                   = hr.party_id
          AND hcar.cust_account_id                            = hca.cust_account_id
          AND NVL(p_gsi_entity_id, hcar.cust_account_role_id) = stage.gsi_entity_id
          AND stage.record_status                             = 'PRE_STAGE'
          AND stage.gsi_entity_id                             = hcar.cust_account_role_id
          AND stage.gsi_entity_type                           = 'HZ_CUST_ACCOUNT_ROLES'
          AND rel.party_id                                    = hcar.party_id
          AND rel.party_type                                  = 'PARTY_RELATIONSHIP'
          ORDER BY stage.transaction_date DESC ;
          v_entity_xml SYS.XMLSEQUENCETYPE;
          v_trxn_ids SYSTEM.NUMBER_TBL_TYPE;
          v_transaction_id NUMBER;
        BEGIN
          insert_log (p_module =>'CREATE_CONT_XML_PAYLOAD(+)', p_audit_message => 'Inserting the Contact XML(s)',
      p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
      p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
          OPEN c1;
          IF (p_gsi_entity_id IS NOT NULL) THEN --For Standalone procedure call
            FETCH c1 INTO x_entity_xml, v_transaction_id;
            UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
            SET entity_xml       = x_entity_xml,
              record_status      = 'AQ_STAGED'
            WHERE transaction_id = v_transaction_id
            AND record_status    = 'PRE_STAGE';
            COMMIT;
            CLOSE c1;
            RETURN;
          END IF;
          LOOP
            FETCH c1 BULK COLLECT INTO v_entity_xml, v_trxn_ids LIMIT 2000;
            EXIT
          WHEN v_trxn_ids.COUNT = 0;
            FORALL i IN 1..v_trxn_ids.COUNT
            UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
            SET entity_xml       = v_entity_xml(i),
              transaction_date   = sysdate
            WHERE transaction_id = v_trxn_ids(i)
            AND record_status    = 'PRE_STAGE';
            COMMIT;
            PUSH_TO_AQ('HZ_CUST_ACCOUNT_ROLES');
          END LOOP;
          CLOSE c1;
          insert_log (p_module =>'CREATE_CONT_XML_PAYLOAD(-)', p_audit_message => 'Inserting the Contact XML(s)',
      p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
      p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
        EXCEPTION
        WHEN OTHERS THEN
          CLOSE c1;
          x_entity_xml := NULL;
          insert_log (p_module =>'CREATE_CONT_XML_PAYLOAD(*)', p_audit_message => 'Error creating XML. Check misimd_intf_error', p_audit_level => 1);
          insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
      p_module => 'CREATE_CONT_XML_PAYLOAD', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
      p_context_id1 => SQLCODE);
        END CREATE_CONT_XML_PAYLOAD;
        PROCEDURE CREATE_ADDR_XML_PAYLOAD(
            p_gsi_entity_id NUMBER := NULL,
            x_entity_xml OUT NOCOPY XMLTYPE)
        IS
          PRAGMA AUTONOMOUS_TRANSACTION;
          CURSOR c1
          IS
            SELECT xmlelement("SPM_CUST_SYNC_PAYLOAD", xmlconcat( xmlelement("TRANSACTION_ID", stage.transaction_id),
      xmlelement("TRANSACTION_TYPE", transaction_type), xmlelement("SPM_ENTITY_TYPE", SPM_ENTITY_TYPE),
      xmlelement("SPM_ENTITY_ID", SPM_ENTITY_ID), xmlelement("GSI_ORG_ID", COALESCE(stage.org_id, 1001)),
      sys_xmlgen( OSS_INTF_USER.MISIMD_SPM_CUSTOMER( party.party_id
              /*PARTY_ID*/
              ,
              (SELECT parent_id
              FROM hz_hierarchy_nodes pp,
                hz_parties hp
              WHERE pp.parent_id = hp.party_id
              AND level_number   =
                (SELECT MAX (level_number)
                FROM hz_hierarchy_nodes cp
                WHERE cp.child_id = pp.child_id
                AND sysdate BETWEEN cp.effective_start_date AND cp.effective_end_date
                AND hierarchy_type = 'Support360 - Parent/Subsidiary'
                )
            AND hierarchy_type = 'Support360 - Parent/Subsidiary'
            AND sysdate BETWEEN pp.effective_start_date AND pp.effective_end_date
            AND pp.child_id = party.party_id
            AND rownum      < 2
              )
              /*PARENT_PARTY_ID*/
              , party.party_number
              /*PARTY_NUMBER */
              , party.party_name
              /*PARTY_NAME */
              , party.party_type
              /*PARTY_TYPE */
              , party.jgzz_fiscal_code
              /*TAX_ID */
              , party.organization_name_phonetic
              /*TRANSLATED_NAME */
              , party.url
              /*URL */
              , hca.cust_account_id
              /*TCA_CUST_ACCOUNT_ID */
              , hca.account_number
              /*CUST_ACCOUNT_NUMBER */
              , hps.party_site_id
              /*PARTY_SITE_ID */
              , hps.party_site_number
              /*PARTY_SITE_NUMBER */
              , hcas.cust_acct_Site_id
              /*CUST_ACCT_SITE_ID */
              , hl.location_id
              /*LOCATION_ID */
              , hl.address1
              /*ADDRESS1 */
              , hl.address2
              /*ADDRESS2 */
              , hl.city
              /*CITY */
              , hl.postal_code
              /*POSTAL_CODE */
              , COALESCE(hl.state, hl.province)
              /*STATE */
              , hl.country
              /*COUNTRY */
              , 'BILL_TO'
              /*SITE_USE_TYPE- DONT USE */
              , hcsua_bill.site_use_id
              /*SITE_USE_ID - DONT USE */
              , NULL
              /*CONTACT_ID */
              , NULL
              /*CONTACT_FIRST_NAME */
              , NULL
              /*CONTACT_LAST_NAME */
              , NULL
              /*CONTACT_EMAIL */
              , NULL
              /*CONTACT_PHONE */
              , NULL
              /*CONTACT_PARTY_ID */
              , NULL
              /*CONTACT_CUST_ACCT_ROLE_ID */
              , NULL
              /*CONTACT_CUST_ACCT_SITE_ID */
              , hcsua_bill.site_use_id
              /*BILL_TO_SITE_USE_ID */
              , hcsua_ship.site_use_id
              /*SHIP_TO_SITE_USE_ID */
              , NULL
              /*IS_PUBLIC_SECTOR */
              , NULL
              /*IS_CHAIN_CUSTOMER */
              , NULL
              /*CUSTOMER_CHAIN_TYPE */
              ), xmlformat.createformat ( 'MISIMD_SPM_ADDRESS') ))),
              transaction_id
            FROM hz_cust_acct_sites_all hcas
            LEFT OUTER JOIN hz_cust_site_uses_all hcsua_bill
            ON (hcsua_bill.cust_acct_site_id = hcas.cust_acct_site_id
            AND hcsua_bill.site_use_code     = 'BILL_TO')
            LEFT OUTER JOIN hz_cust_site_uses_all hcsua_ship
            ON (hcsua_ship.cust_acct_site_id = hcas.cust_acct_site_id
            AND hcsua_ship.site_use_code     = 'SHIP_TO'),
              hz_party_sites hps,
              hz_locations hl,
              hz_cust_accounts hca,
              hz_parties party,
              OSS_INTF_USER.MISIMD_SPM_CUST_STG stage
            WHERE 1                                          =1
            AND hca.cust_account_id                          = hcas.cust_account_id
            AND party.party_id                               = hca.party_id
            AND stage.gsi_entity_type                        = 'HZ_CUST_ACCT_SITES_ALL'
            AND NVL(p_gsi_entity_id, hcas.cust_acct_site_id) = stage.gsi_entity_id
            AND stage.record_status                          = 'PRE_STAGE'
            AND hcas.cust_acct_site_id                       = stage.gsi_entity_id
            AND hcas.party_site_id                           = hps.party_site_id
            AND hl.location_id                               = hps.location_id
            ORDER BY stage.transaction_date DESC;
            v_entity_xml SYS.XMLSEQUENCETYPE;
            v_trxn_ids SYSTEM.NUMBER_TBL_TYPE;
            v_transaction_id NUMBER;
          BEGIN
            insert_log (p_module =>'CREATE_ADDR_XML_PAYLOAD(+)', p_audit_message => 'Inserting the Contact XML(s)',
      p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
      p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
            OPEN c1;
            IF (p_gsi_entity_id IS NOT NULL) THEN --For Standalone procedure call
              FETCH c1 INTO x_entity_xml, v_transaction_id;
              UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
              SET entity_xml       = x_entity_xml,
                record_status      = 'AQ_STAGED'
              WHERE transaction_id = v_transaction_id
              AND record_status    = 'PRE_STAGE';
              COMMIT;
              CLOSE c1;
              RETURN;
            END IF;
            LOOP
              FETCH c1 BULK COLLECT INTO v_entity_xml, v_trxn_ids LIMIT 2000;
              EXIT
            WHEN v_trxn_ids.COUNT = 0;
              FORALL i IN 1..v_trxn_ids.COUNT
              UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG
              SET entity_xml       = v_entity_xml(i),
                transaction_date   = sysdate
              WHERE transaction_id = v_trxn_ids(i)
              AND record_status    = 'PRE_STAGE';
              COMMIT;
              PUSH_TO_AQ('HZ_CUST_ACCT_SITES_ALL');
            END LOOP;
            CLOSE c1;
            insert_log (p_module =>'CREATE_ADDR_XML_PAYLOAD(-)', p_audit_message => 'Inserting the Contact XML(s)',
      p_audit_level => 1, p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id,
      p_context_name2 => 'EntityId', p_context_id2 => p_gsi_entity_id);
          EXCEPTION
          WHEN OTHERS THEN
            CLOSE c1;
            x_entity_xml := NULL;
            insert_log (p_module =>'CREATE_ADDR_XML_PAYLOAD(*)', p_audit_message => 'Error creating XML. Check misimd_intf_error', p_audit_level => 1);
            insert_error (p_error_code => 'BACKTRACE:', p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
      p_module => 'CREATE_ADDR_XML_PAYLOAD', p_context_name1 => SUBSTR ('Error_Stack:' || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
      p_context_id1 => SQLCODE);
          END CREATE_ADDR_XML_PAYLOAD;
          PROCEDURE PUSH_TO_AQ(
              p_gsi_entity_type IN VARCHAR2 := NULL)
          IS
            CURSOR C_PAYLOADS(p_max_sync_count NUMBER)
            IS
              SELECT *
              FROM
                (SELECT MISIMD_WEBONE_Q_PAYLOAD_OBJ(wf_event_t(1,                                                                                                          -- priority
                  sysdate,                                                                                                                                                 -- send_date
                  NULL,                                                                                                                                                    -- receive_date
                  STG.TRANSACTION_ID,                                                                                                                                      -- correlation_id
                  NULL,                                                                                                                                                    -- parameter_list
                  NULL,                                                                                                                                                    -- event_name
                  DECODE(GSI_ENTITY_TYPE,
          'HZ_CUST_ACCOUNTS', 'GSI_CUSTOMER',
          'HZ_CUST_ACCT_SITES_ALL', 'GSI_ADDRESS',
          'HZ_CUST_ACCOUNT_ROLES', 'GSI_CONTACT',
          'UNKNOWN'), --event_key
                  STG.ENTITY_XML.getCLOBVAL(),                                                                                                                             -- event_data
                  NULL,                                                                                                                                                    -- from_agent
                  NULL,                                                                                                                                                    -- to_agent
                  NULL,                                                                                                                                                    -- error_subscription
                  NULL,                                                                                                                                                    -- error_message
                  NULL)),
                  transaction_id
                FROM OSS_INTF_USER.MISIMD_SPM_CUST_STG STG
                WHERE record_STATUS = 'PRE_STAGE'
                AND ENTITY_XML     IS NOT NULL
                AND GSI_ENTITY_TYPE = NVL(p_gsi_entity_type, GSI_ENTITY_TYPE)
                ORDER BY spm_entity_id DESC --pick entities without OSR first. These are likely to be the manual_sync entities
                )
            WHERE 1    =1
            AND rownum < p_max_sync_count ;
            v_trxn_ids SYSTEM.NUMBER_TBL_TYPE;
            v_payload_tbl MISIMD_WEBONE_Q_PAYLOAD_OBJ_TT ;
            v_enqueue_options DBMS_AQ.enqueue_options_t;
            v_msg_prop_array DBMS_AQ.message_properties_array_t :=DBMS_AQ.message_properties_array_t() ;
            v_msg_prop DBMS_AQ.message_properties_t;
            v_msgid_array DBMS_AQ.msgid_array_t;
            v_retval PLS_INTEGER;
            v_max_sync_count NUMBER;
          BEGIN
            insert_log (p_module =>'PUSH_TO_AQ(+)', p_audit_message => 'Pushing Entity Type: '|| p_gsi_entity_type, p_audit_level => 1,
      p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
            v_msg_prop.RECIPIENT_LIST(1) := sys.aq$_agent(COALESCE(misimd_hz_spm_sync.get_lookup('GSI-SPM CLOUD BRIDGE' ,
      'AQ_CONSUMER_NAME'), 'SPM_CUST_OUTBOUND_OSB'), NULL, NULL);
            v_max_sync_count             := COALESCE(to_number(misimd_hz_spm_sync.get_lookup('GSI-SPM CLOUD BRIDGE' , 'MAX_SYNC_ROWCOUNT')), 500);
            OPEN C_PAYLOADS(v_max_sync_count);
            LOOP
              v_msg_prop_array.extend();
              v_msg_prop_array(1) := v_msg_prop;
              FETCH C_PAYLOADS bulk collect INTO v_payload_tbl,v_trxn_ids LIMIT 2000;
              EXIT
            WHEN v_payload_tbl.count = 0;
              v_msg_prop_array.extend(v_payload_tbl.COUNT-1, 1);
              v_retval := DBMS_AQ.ENQUEUE_ARRAY( queue_name => 'APPS.MISIMD_WEBONE_Q', enqueue_options => v_enqueue_options,
        array_size => v_payload_tbl.COUNT, message_properties_array => v_msg_prop_array, payload_array => v_payload_tbl,
        msgid_array => v_msgid_array);
              FORALL i IN 1..v_payload_tbl.COUNT
              UPDATE OSS_INTF_USER.MISIMD_SPM_CUST_STG STG
              SET record_status    = nvl2(v_msgid_array(i),'AQ_STAGED', 'AQ_ERROR')
              WHERE transaction_id = v_trxn_ids(i);
              COMMIT;
              v_payload_tbl.delete();
              v_msg_prop_array.delete();
              v_msgid_array.delete();
            END LOOP;
            CLOSE C_PAYLOADS;
            insert_log (p_module =>'PUSH_TO_AQ(+)', p_audit_message => 'Pushing Entity Type: '|| p_gsi_entity_type, p_audit_level => 1,
      p_context_name1 => 'RequestId', p_context_id1 => fnd_global.conc_request_id);
          END PUSH_TO_AQ;
          FUNCTION FETCH_ENTITY_XML(
              p_spm_entity_type   VARCHAR2,
              p_account_number    VARCHAR2,
              p_party_site_number VARCHAR2 := NULL,
              p_org_id            NUMBER   := NULL,
              p_contact_number    VARCHAR2 := NULL,
              p_trxn_type         VARCHAR2 := 'INSERT',
              p_push_to_aq        VARCHAR2 := 'N' )
            RETURN CLOB
          IS
            v_gsi_entity_id NUMBER;
            v_entity_xml XMLTYPE;
            v_spm_id VARCHAR2(60) := NULL;
          BEGIN
            <<OPERATION_SELECTOR>>
            CASE p_spm_entity_type
            WHEN 'GSI_CUSTOMER' THEN
              IF (p_account_number IS NOT NULL) THEN
                --Add validations. Check for duplication if required
                NULL;
              ELSE
                RETURN NULL; --Error Function not called properly
              END IF;
              SELECT cust_account_id
              INTO v_gsi_entity_id
              FROM hz_cust_accounts
              WHERE account_number = p_account_number;
              INSERT_NEW_ENTITY('HZ_CUST_ACCOUNTS', v_gsi_entity_id, NULL, p_trxn_type );
              CREATE_CUST_XML_PAYLOAD(v_gsi_entity_id, v_entity_xml);
              IF v_entity_xml IS NOT NULL THEN
                RETURN v_entity_xml.getclobval();
              ELSE
                RETURN NULL;
              END IF;
            WHEN 'GSI_ADDRESS' THEN
              IF (p_account_number IS NOT NULL AND p_party_site_number IS NOT NULL AND p_org_id IS NOT NULL ) THEN
                --Add validations. Check for duplication if required
                NULL;
              ELSE
                RETURN NULL; --Error Function not called properly
              END IF;
              SELECT hcas.cust_acct_site_id,
                osr.orig_system_reference
              INTO v_gsi_entity_id,
                v_spm_id
              FROM hz_cust_acct_sites_all hcas
              LEFT OUTER JOIN hz_orig_sys_references osr
              ON (osr.orig_system     = 'SPM'
              AND osr.owner_Table_name='HZ_CUST_ACCT_SITES_ALL'
              AND osr.owner_Table_id  =hcas.cust_Acct_site_id
              AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
              AND osr.status = 'A' ),
                hz_party_sites hps,
                hz_cust_accounts hca
              WHERE 1                   =1
              AND hcas.cust_account_id  = hca.cust_account_id
              AND hps.party_site_id     = hcas.party_site_id
              AND hcas.org_id           = p_org_id
              AND hps.party_site_number = p_party_site_number
              AND hca.account_number    = p_account_number
              AND rownum                < 2;
              INSERT_NEW_ENTITY('HZ_CUST_ACCT_SITES_ALL', v_gsi_entity_id, v_spm_id, p_trxn_type);
              CREATE_ADDR_XML_PAYLOAD(v_gsi_entity_id, v_entity_xml);
              IF v_entity_xml IS NOT NULL THEN
                RETURN v_entity_xml.getclobval();
              ELSE
                RETURN NULL;
              END IF;
            WHEN 'GSI_CONTACT' THEN
              IF (p_account_number IS NOT NULL AND p_contact_number IS NOT NULL ) THEN
                --Add validations. Check for duplication if required
                NULL;
              ELSE
                RETURN NULL; --Error Function not called properly
              END IF;
              SELECT hcar.cust_account_role_id,
                osr.orig_system_reference
              INTO v_gsi_entity_id,
                v_spm_id
              FROM hz_org_contacts hoc,
                hz_relationships hr,
                hz_cust_account_roles hcar
              LEFT OUTER JOIN hz_orig_sys_references osr
              ON (osr.orig_system     = 'SPM'
              AND osr.owner_Table_name='HZ_CUST_ACCOUNT_ROLES'
              AND osr.owner_Table_id  =hcar.cust_account_role_id
              AND TRUNC(sysdate) BETWEEN COALESCE(TRUNC(osr.start_date_active), TRUNC(sysdate)) AND COALESCE(TRUNC(osr.end_date_active), TRUNC(sysdate))
              AND osr.status = 'A' )
              LEFT OUTER JOIN HZ_CUST_ACCT_SITES_ALL hcas
              ON(hcas.cust_acct_site_id = hcar.cust_acct_site_id)
              LEFT OUTER JOIN HZ_PARTY_SITES HPS
              ON(HPS.PARTY_SITE_ID = hcas.party_site_id),
                hz_cust_accounts hca
              WHERE 1                              =1
              AND contact_number                   = p_contact_number
              AND hr.relationship_id               = hoc.party_relationship_id
              AND hr.relationship_code             = 'CONTACT'
              AND hcar.party_id                    = hr.party_id
              AND hcar.role_type                   = 'CONTACT'
              AND hca.account_number               = p_account_number
              AND hca.cust_account_id              = hcar.cust_account_id
              AND NVL(hps.party_site_number, '-1') = NVL(p_party_site_number, '-1')
              AND rownum                           < 2 ;
              INSERT_NEW_ENTITY('HZ_CUST_ACCOUNT_ROLES', v_gsi_entity_id,v_spm_id, p_trxn_type);
              CREATE_CONT_XML_PAYLOAD(v_gsi_entity_id, v_entity_xml);
              IF v_entity_xml IS NOT NULL THEN
                RETURN v_entity_xml.getclobval();
              ELSE
                RETURN NULL;
              END IF;
            END CASE OPERATION_SELECTOR;
          END FETCH_ENTITY_XML;
        PROCEDURE INSERT_NEW_ENTITY(
            p_gsi_entity_type VARCHAR2 ,
            p_gsi_entity_id   NUMBER ,
            p_spm_entity_id   VARCHAR2 ,
            p_trxn_type       VARCHAR2)
        IS
          PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
          INSERT
          INTO OSS_INTF_USER.MISIMD_SPM_CUST_STG
            (
              TRANSACTION_ID,
              TRANSACTION_DATE,
              TRANSACTION_TYPE,
              SPM_ENTITY_TYPE,
              SPM_ENTITY_ID,
              GSI_ENTITY_TYPE,
              GSI_ENTITY_ID,
              record_status
            )
            VALUES
            (
              OSS_INTF_USER.MISIMD_SPM_CUST_STG_S.nextval,
              sysdate,
              p_trxn_type,
              DECODE(p_gsi_entity_type, 'HZ_CUST_ACCOUNT_ROLES', 'GSI_CONTACT',
        'HZ_CUST_ACCOUNTS', 'GSI_CUSTOMER', 'HZ_CUST_ACCT_SITES_ALL', 'GSI_ADDRESS', 'INVALID'),
              p_spm_entity_id,
              p_gsi_entity_type,
              p_gsi_entity_id,
              'PRE_STAGE'
            );
          COMMIT;
        END INSERT_NEW_ENTITY;
      PROCEDURE extend_CDC_window
        (
          p_subscription_type IN VARCHAR2
        )
      IS
        v_subscription_name VARCHAR2(50);
      BEGIN
        v_subscription_name := MISIMD_HZ_SPM_SYNC.get_lookup('GSI-SPM CLOUD BRIDGE','CDC_SPM_CUST_SUBSCRIPTION_NAME');
        CASE p_subscription_type
        WHEN 'SPM_CUST' THEN
          DBMS_CDC_SUBSCRIBE.EXTEND_WINDOW(subscription_name => v_subscription_name );
        ELSE
          NULL;
        END CASE;
      END extend_CDC_window;
    PROCEDURE purge_CDC_window
      (
        p_subscription_type IN VARCHAR2
      )
    IS
      v_subscription_name VARCHAR2(50);
    BEGIN
      v_subscription_name := MISIMD_HZ_SPM_SYNC.get_lookup('GSI-SPM CLOUD BRIDGE','CDC_SPM_CUST_SUBSCRIPTION_NAME');
      CASE p_subscription_type
      WHEN 'SPM_CUST' THEN
        DBMS_CDC_SUBSCRIBE.PURGE_WINDOW(subscription_name => v_subscription_name );
      ELSE
        NULL;
      END CASE;
    END purge_CDC_window;
  FUNCTION get_lookup
    (
      p_lookup_type IN VARCHAR2,
      p_lookup_code IN VARCHAR2
    )
    RETURN VARCHAR2
  IS
    v_meaning oss_intf_user.misimd_hz_cust_lookups.meaning%type;
  BEGIN
    SELECT MAX(meaning)
    INTO v_meaning
    FROM oss_intf_user.misimd_hz_cust_lookups
    WHERE lookup_type    = p_lookup_type
    AND lookup_code      = p_lookup_code
    AND enabled_flag     = 'Y'
    AND end_date_active IS NULL;
    RETURN v_meaning;
  END get_lookup;
END MISIMD_HZ_SPM_SYNC;
/
commit;
exit