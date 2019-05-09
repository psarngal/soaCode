rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb+91 \
rem dbdrv: checkfile:~PROD:~PATH:~FILE
rem 
rem Copyright (c) 2005, 2017 Oracle and/or its affiliates.
rem   All rights reserved.
rem Version 12.0.0
rem	Purpose:
rem
SET VERIFY OFF

WHENEVER SQLERROR EXIT FAILURE ROLLBACK

WHENEVER OSERROR

EXIT FAILURE ROLLBACK

create or replace PACKAGE BODY                     misimd_tas_cloud_wf AS
  -- $Header: MISIMD_TAS_CLOUD_WF.plb 120.156 2018/07/27 07:15:59 psarngal noship $
  -- ====================================================================================
  --
  --   Copyright (c) 2005,2017  Oracle and/or its affiliates.
  --   All rights reserved.
  --
  -- FILENAME
  --   MISIMD_TAS_CLOUD_WF.plb
  -- Incident Bug #:13521955
  --
  -- Purpose:
  --
  --   See package spec.
  --
  -- Notes:
  --
  --   o NA
  --
  --   o NA
  --
  -- Modifications:
  --
  --   File     Date in
  --   Version  Production  Author    Modification
  --   =======  ==========  ========  ===================================================
  --   120.0    2011-09-08  gnaha     Created
  --   120.1    2014-10-09  yuchandr  Currency conversion rate attribute added to the payload
  --   120.2    2014-10-09  yuchandr  Payload split fix
  --   120.3    2014-11-12  yuchandr  Payload split fix  Bug no 20017524
  --   120.50   2014-12-02  spamuru   Production Bug to Remove SITEMOCK
  --   120.51   2015-01-16  spamuru   14.12 Changes and SITEMOCK Logic and OAE logic
  --   120.55   2015-01-20  spamuru   14.12 Tenant_Provisioned Update
  --   120.57   2015-03-03  spamuru   15.3 Solar Changes
  --   120.61   2015-03-03  etrigos   Bug 21533262 - Duplicated Subscription ID sent in payload
  --   120.62   2015-03-03  etrigos   Unix Format
  --   120.63   2015-05-10  swaramac  Bug 21755374 - Code fix to include co-term sub id in TAS payload
  --   120.64   2015-15-10  spamuru   Project Changes for Licensed_TO,Dedicated Commute,Pilot Instance Type
  --   120.65   2015-28-10  spamuru   Project changes for 15.11
  --   120.66   2015-16-12  yuchandr  updated for CPQ grouping Logic.
  --   120.67   2015-17-12  yuchandr  updated for added additional signature for paygen support for getpayload.--
  --   120.69   2016-05-01  rdnagara  Changes to remove TAS_SUBSCRIPTIONS_IN_OM_ORDER Tag,
  --                                  added missing join condition,fix for Customer_Type:= NULL
  --   120.76   2016-07-01  spamuru   16.1 Changes Jan 2016 Go Live Changes and CPQ Grouping bug fixes
  --   120.79   2016-08-01  spamuru   16.2 Changes language pack Feb 2016 Go Live
  --   120.80   2016-08-01  vetsrini  16.2 Added new attribute LANGUAGE_CODES
  --   120.82   2016-15-02  spamuru   16.3 New Attributes,Pod Type
  --   120.84   2016-19-02  spamuru   16.3 Changes to overwrite isTASEnabled flag
  --   120.86   2016-19-02  vetsrini  16.3 Changes to skip consolidation logic for external sites
  --   120.87   2016-19-02  vetsrini  16.3 Changes
  --   120.88   2016-16-03  vetsrini  16.3 added external site case for IS SUBSCRIPTION Enabled
  --   120.89   2016-16-03  vetsrini  16.3
  --   120.90   2016-16-03  vetsrini  Mulit-group-rule,optional-includes features for consolidation rules
  --   120.91   2016-24-03  vetsrini
  --   120.92   2016-13-04  vetsrini  logic for split/consolidation rules,paygen-co-term,opc-removal
  --   120.93   2016-13-04  vetsrini  correcting gscc warning
  --   120.94   2016-13-04  vetsrini  correcting gscc warning
  --   120.97   2016-03-05  vetsrini  Bug# 22518475 - BPEL should not sent to TAS the coterm subscription ID
  --   120.98   2016-03-05  vetsrini  Bug# 22518475 - BPEL should not sent to TAS the coterm subscription ID
  --   120.99   2016-03-05  vetsrini  16.06 - SPM-4644 - single payload to TAS includes both metered and non-metered
  --   120.100  2016-05-23  vetsrini  Supplement Payload Functionality
  --   120.101  2016-05-23  vetsrini  update OPC Customer Name at line level change
  --   120.104  2016-07-25  vetsrini  16.7 release changes
  --   120.105  2016-07-25  vetsrini  GSCC warning fix
  --   120.106  2016-08-03  vetsrini  Bug 24402151 - WorkAround Fix : for JAVAMB FAILED TO AUTO-COMPLETE
  --   120.107  2016-09-09  vetsrini  Bug 24617551 - 16.09 release change for TAS Provisioning
  --   120.108  2016-09-19  vetsrini  Bug 24692360 - 16.09 release change for TAS Provisioning
  --   120.109  2016-09-21  vetsrini  Bug 24692394 - 16.10 release change for TAS Provisioning
  --                                  SPM-5446/SPM-4240/SPM-5368
  --   120.111  2016-10-06  swaramac  Bug 24798142 and Bug 23481512
  --   120.112  2016-11-06  swaramac  Bug 23481512
  --   120.113  2016-11-06  ravelard  24801585
  --   120.115  2016-10-17  vetsrini  Bug 24907893 - 16.10 release change for TAS Provisioning
  --                SPM-5446/SPM-4240/SPM-5368
  --   120.116  2016-10-20   Bug 24747686  Ramped Scenario Fix
  --   120.117  2016-11-23  kahirem   16.12 changes
  --   120.118  2017-01-06  vetsrini  17.1 changes
  --   120.119  2017-01-06  vetsrini  2016 copyright change
  --   120.120  2017-01-18  vetsrini  TAS Extra lines for IOT
  --   120.121  2017-01-19  vetsrini  GSI PODTYPE Fix,IOT headerid fix
  --   120.122  2017-01-23  swaramac  24798142,RCA MISIMD_TAS_CLOUD_WF.onboarding Error
  --   120.123  2017-01-23  vetsrini  merged code for 120.121 and 120.122
  --   120.124  2017-02-06  kahirem   Changes for TAS Extra lines for IOT
  --   120.126  2017-02-06  kahirem   Changes for Pod Type ,Changes for Pilot On boarding,Bug number: 25257594,25119996
  --   120.128  2017-02-10  rdnagara  Bug 25476997 - LANGUAGE_CODES missing for Taleo Business Edition payloads for Orders from CPQ
  --   120.129  2017-03-28  vetsrini  Bug 25797060 - 17:04 release change for TAS Provisioning
  --   120.130  2017-03-28  vetsrini  Bug fixes for cross-ruleset,associate_subid and user desc at line lvl
  --   120.134  2017-04-25  swaramac  Glob Lookup code for COMMITS Introduced
  --   120.135  2017-04-25  vetsrini  Glob Lookup code to intf lookup,update/extension transaction issue
  --   120.136  2017-05-31  vetsrini  IOT/operation Type changes
  --   120.137  2017-06-07  tayala    Service start and end dates moved before status update for non-CPQ
  --                                  and CPQ.non-onboarding
  --   120.138  2017-06-20  vetsrini  added master_switch for GSI_POD_TYPE
  --   120.139  2017-06-20  vetsrini  GSCC
  --   120.140  2017-06-21  joaqloza  Added function intended for Getting sub id information for termination flow
  --   120.141  2017-06-27  vetsrini  ORDER_CONTAINS_ERP flag
  --   120.142  2017-06-27  vetsrini  GSCC
  --   120.142  2017-08-15  vetsrini  Updates
  --   120.143  2017-08-23  vetsrini  Updates
  --   120.144  2017-09-18  vetsrini  C9QA:17.3.6upsize legacy schema hung in "GSI - Order Booked"
  --   120.145  2017-09-20  vetsrini  filter based on cloud credit list
  --   120.146  2017-09-29  rdnagara  Bug 26568736 - Promotion Intent to pay changes
  --   120.147  2017-10-10  rdnagara  Bug 26901179 - RCA - provisioning payload for sku B74155 is missing BOM component
  --   120.148  2017-10-19  vetsrini  17:10 new attributes textura,apiary
  --   120.149  2017-12-08  rdnagara  Not to add extra IOT lines when already present, and add IOT lines only for Onboarding payloads
  --   120.150  2018-02-22  vetsrini  programType,podType,addtl lines changes
  --   120.151  2018-03-01  vetsrini  Changes for addtl lines
  --   120.153  2018-03-02  srechand  Bug27524361 - RCA EXTSITE orders with no coter subid failing with PROV_PAYLOAD_PREP_ERROR
  --   120.154  2018-05-05  mohans    added CLOUD_PORTAL as order source
  --   120.155  2018-22-06  mohans    18.7 added 3 properties at line level
  --   120.157  2018-22-06  psarngal  CF 18.8 added 3 properties and procedure update_rebate_table
  -- =================================================================================================

    g_user_id                       NUMBER := fnd_global.user_id;
    g_org_id                        NUMBER := fnd_global.org_id;
    g_intf_run_key                  NUMBER := NULL;
    p_error_code                    NUMBER := NULL;
    p_error_flag                    VARCHAR2(2) := NULL;
    p_error_message                 VARCHAR2(1000) := NULL;
    g_module                        VARCHAR2(100) := NULL;
    g_start_date                    DATE := NULL;
    g_end_date                      DATE := NULL;
    g_trace_level                   NUMBER := NULL;
    g_log_level                     NUMBER := NULL;
    g_trace                         VARCHAR2(2) := NULL;
    g_tracefile_identifier          VARCHAR2(150) := NULL;
    g_audit_message                 VARCHAR2(1000) := NULL;
    g_audit_level                   NUMBER := NULL;
    g_context_name                  VARCHAR2(100) := NULL;
    g_context_name2                 VARCHAR2(100) := NULL;
    g_context_id                    NUMBER := NULL;
    g_context_id2                   NUMBER := NULL;
    g_context_id3                   NUMBER := NULL;
    g_line_count_apics              NUMBER := NULL;
    g_line_count_bdcsce             NUMBER := NULL;
    g_line_count_oehpcs             NUMBER := NULL;
    g_line_count_jaas               NUMBER := NULL;
    g_line_count_compute            NUMBER := NULL;
    g_line_count_storage            NUMBER := NULL;
    l_enabled_apics                 VARCHAR2(20) := NULL;
    l_enabled_bdcsce                VARCHAR2(20) := NULL;
    l_enabled_oehpcs                VARCHAR2(20) := NULL;
    errbuf                          VARCHAR2(1000) := NULL;
    global_entity                   VARCHAR2(100) := NULL;
  -- Split code Variables
    l_split_status_n                VARCHAR2(20) := 'NEW';
    l_split_status_r                VARCHAR2(20) := 'READY';
    l_split_status_s                VARCHAR2(20) := 'SENT';
    l_split_status_c                VARCHAR2(20) := 'COMPLETE';
    l_source_ss                     VARCHAR2(20) := 'SCHEDULED_SPLIT';
    l_source_ls                     VARCHAR2(20) := 'LINE_SPLIT';
    l_source_ms                     VARCHAR2(20) := 'MANUAL_SPLIT';
    l_dbms_flag                     VARCHAR2(1) := 'N';
  -- Split code Variables
	l_extsite_check        			VARCHAR2( 2000 ) := NULL;
	l_associate_sub_id_check   	    VARCHAR2( 240 ) := NULL;
	l_associate_needed  			VARCHAR2(1) := 'N';


    FUNCTION append_iot_lines (
        p_payload XMLTYPE
    ) RETURN XMLTYPE IS

        l_payload                     XMLTYPE;
        l_new_payload                 XMLTYPE;
        l_iot_part_exists             VARCHAR2(10) := NULL;
        l_new_subscription_id         NUMBER;
        l_new_line_id                 NUMBER;
        l_line_text                   XMLTYPE;
        l_line_text_clob              CLOB;
        l_new_sub_group               NUMBER;
        l_payload_parent_line_item    NUMBER :=-1;
        l_payload_line_item           NUMBER :=-1;
        l_payload_service_line_item   NUMBER;
        l_index                       NUMBER;
    -------------------------
        TYPE partnumber_table IS
            TABLE OF VARCHAR2(200) INDEX BY VARCHAR2(200);
        iot_parent_parts              partnumber_table;
  -------------------------
        TYPE t_iot IS RECORD ( parent_part_number            VARCHAR2(50),
        ordered_item                  VARCHAR2(50) );
        TYPE t_iot_items IS
            TABLE OF t_iot;
  -------------------------
        TYPE t_payload_record IS RECORD ( order_number                  VARCHAR2(100),
        orderheaderid                 VARCHAR2(100),
        lineid                        VARCHAR2(100),
        ordereditem                   VARCHAR2(100),
        fulfillment_set               VARCHAR2(100),
        startdate                     VARCHAR2(100),
        line_end_date                 VARCHAR2(100),
        subscriptionid                VARCHAR2(100),
        buyeremailid                  VARCHAR2(100),
        serviceadminemailid           VARCHAR2(100),
        overageopted                  VARCHAR2(100),
        datacenter                    VARCHAR2(100) );
        TYPE t_payload IS
            TABLE OF t_payload_record INDEX BY BINARY_INTEGER;
        t_payload_lines               t_payload;
  -------------------------
        c                             NUMBER := 0;

        FUNCTION is_item_exists (
            p_payload_ordereditem VARCHAR2
        ) RETURN NUMBER
            IS
        BEGIN
            FOR pay_i IN 1..t_payload_lines.count LOOP
                IF
                    ( t_payload_lines(pay_i).ordereditem = p_payload_ordereditem )
                THEN
                    RETURN pay_i;
                END IF;
            END LOOP;

            RETURN -1;
        END is_item_exists;

        FUNCTION is_service_exists (
            p_payload_fullfillment_set VARCHAR2
        ) RETURN NUMBER
            IS
        BEGIN
            FOR set_i IN 1..t_payload_lines.count LOOP
                IF
                    ( regexp_substr(t_payload_lines(set_i).fulfillment_set,'[^-]+',1,1) = p_payload_fullfillment_set )
                THEN
                    RETURN set_i;
                END IF;
            END LOOP;

            RETURN -1;
        END is_service_exists;

    BEGIN
        l_payload := p_payload;
  --- Get the Parent parts
        c := 0;
        FOR iot IN (
            SELECT DISTINCT
                part_number
            FROM
                apxiimd.misimd_tas_insert_line
            WHERE
                enabled = 'Y'
        ) LOOP
            c := c + 1;
            iot_parent_parts(c) := iot.part_number;
        END LOOP;
--- Get the payload list

        c := 0;
        FOR rec IN (
            SELECT
                xlinetbl.*,
                xhdrtbl.*
            FROM
                XMLTABLE ( '/OrderHeader/OrderLines/OrderLine' PASSING ( l_payload ) COLUMNS lineid VARCHAR2(200) PATH './@LINEID',ordereditem VARCHAR2(200) PATH './@ORDEREDITEM',fulfillment_set
VARCHAR2(200) PATH './@FULFILLMENT_SET',startdate VARCHAR2(200) PATH './@STARTDATE',line_end_date VARCHAR2(200) PATH './@LINE_END_DATE',subscriptionid VARCHAR2(
200) PATH './@SUBSCRIPTIONID',buyeremailid VARCHAR2(200) PATH './@BUYEREMAILID',serviceadminemailid VARCHAR2(200) PATH './@SERVICEADMINEMAILID',overageopted VARCHAR2
(200) PATH './@OVERAGEOPTED',datacenter VARCHAR2(200) PATH './@DATACENTER' ) xlinetbl,
                XMLTABLE ( '/OrderHeader' PASSING l_payload COLUMNS order_number VARCHAR2(200) PATH './column[@name="$$OM_ORDER_NUMBER$$"]',orderheaderid VARCHAR2(200) PATH './@HEADERID'
) xhdrtbl
        ) LOOP
            c := c + 1;
            t_payload_lines(c).order_number := rec.order_number;
            t_payload_lines(c).orderheaderid := rec.orderheaderid;
            t_payload_lines(c).lineid := rec.lineid;
            t_payload_lines(c).ordereditem := rec.ordereditem;
            t_payload_lines(c).fulfillment_set := rec.fulfillment_set;
            t_payload_lines(c).startdate := rec.startdate;
            t_payload_lines(c).line_end_date := rec.line_end_date;
            t_payload_lines(c).subscriptionid := rec.subscriptionid;
            t_payload_lines(c).buyeremailid := rec.buyeremailid;
            t_payload_lines(c).serviceadminemailid := rec.serviceadminemailid;
            t_payload_lines(c).overageopted := rec.overageopted;
            t_payload_lines(c).datacenter := rec.datacenter;
        END LOOP;

	 			-- Not to add extra JAAS line when order contains APICS and JAAS

        BEGIN
            SELECT
                code2
            INTO
                l_enabled_apics
            FROM
                glob_ref_codes_all
            WHERE
                domain = 'MISIMD_COMMIT_TAS_GRP'
                AND   code IN (
                    'APICS'
                );

            SELECT
                code2
            INTO
                l_enabled_oehpcs
            FROM
                glob_ref_codes_all
            WHERE
                domain = 'MISIMD_COMMIT_TAS_GRP'
                AND   code IN (
                    'OEHPCS'
                );

            SELECT
                code2
            INTO
                l_enabled_bdcsce
            FROM
                glob_ref_codes_all
            WHERE
                domain = 'MISIMD_COMMIT_TAS_GRP'
                AND   code IN (
                    'BDCSCE'
                );

			-- count number of lines of APICS, BDCSCE and OEHPCS

            SELECT
                COUNT(DECODE(substr(oes.set_name,1,instr(oes.set_name,'-') - 1),'APICS',2) ),
                COUNT(DECODE(substr(oes.set_name,1,instr(oes.set_name,'-') - 1),'BDCSCE',3) ),
                COUNT(DECODE(substr(oes.set_name,1,instr(oes.set_name,'-') - 1),'OEHPCS',4) )
            INTO
                g_line_count_apics,g_line_count_bdcsce,g_line_count_oehpcs
            FROM
                oe_order_lines_all ol,
                oe_order_price_attribs op,
                oe_sets oes,
                oe_line_sets sln,
                oe_order_headers_all oh
            WHERE
                1 = 1
                AND   oes.set_id = sln.set_id
                AND   oes.set_type = 'FULFILLMENT_SET'
                AND   sln.line_id = ol.service_reference_line_id
                AND   ol.header_id = oh.header_id
                AND   op.line_id = ol.service_reference_line_id
                AND   op.header_id = oh.header_id
                AND   oh.header_id = t_payload_lines(1).orderheaderid
                AND   substr(oes.set_name,1,instr(oes.set_name,'-') - 1) IN (
                    'APICS',
                    'OEHPCS',
                    'BDCSCE'
                )
                AND   ol.item_type_code = 'SERVICE';

            IF
                ( g_line_count_apics <> 0 AND l_enabled_apics = 'Y' )
            THEN
                SELECT
                    COUNT(oes.set_name)
                INTO
                    g_line_count_jaas
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs op,
                    oe_sets oes,
                    oe_line_sets sln,
                    oe_order_headers_all oh
                WHERE
                    1 = 1
                    AND   oes.set_id = sln.set_id
                    AND   oes.set_type = 'FULFILLMENT_SET'
                    AND   sln.line_id = ol.service_reference_line_id
                    AND   ol.header_id = oh.header_id
                    AND   op.line_id = ol.service_reference_line_id
                    AND   op.header_id = oh.header_id
                    AND   oh.header_id = t_payload_lines(1).orderheaderid
                    AND   substr(oes.set_name,1,instr(oes.set_name,'-') - 1) IN (
                        'JAAS'
                    )
                    AND   ol.item_type_code = 'SERVICE';

                IF
                    g_line_count_jaas <> 0
                THEN
                    RETURN p_payload;
                END IF;
            ELSIF ( g_line_count_bdcsce <> 0 AND l_enabled_bdcsce = 'Y' ) THEN
                SELECT
                    COUNT(oes.set_name)
                INTO
                    g_line_count_compute
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs op,
                    oe_sets oes,
                    oe_line_sets sln,
                    oe_order_headers_all oh
                WHERE
                    1 = 1
                    AND   oes.set_id = sln.set_id
                    AND   oes.set_type = 'FULFILLMENT_SET'
                    AND   sln.line_id = ol.service_reference_line_id
                    AND   ol.header_id = oh.header_id
                    AND   op.line_id = ol.service_reference_line_id
                    AND   op.header_id = oh.header_id
                    AND   oh.header_id = t_payload_lines(1).orderheaderid
                    AND   substr(oes.set_name,1,instr(oes.set_name,'-') - 1) IN (
                        'COMPUTE'
                    )
                    AND   ol.item_type_code = 'SERVICE';

                IF
                    g_line_count_compute <> 0
                THEN
                    RETURN p_payload;
                END IF;
            ELSIF ( g_line_count_oehpcs <> 0 AND l_enabled_oehpcs = 'Y' ) THEN
                SELECT
                    COUNT(oes.set_name)
                INTO
                    g_line_count_storage
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs op,
                    oe_sets oes,
                    oe_line_sets sln,
                    oe_order_headers_all oh
                WHERE
                    1 = 1
                    AND   oes.set_id = sln.set_id
                    AND   oes.set_type = 'FULFILLMENT_SET'
                    AND   sln.line_id = ol.service_reference_line_id
                    AND   ol.header_id = oh.header_id
                    AND   op.line_id = ol.service_reference_line_id
                    AND   op.header_id = oh.header_id
                    AND   oh.header_id = t_payload_lines(1).orderheaderid
                    AND   substr(oes.set_name,1,instr(oes.set_name,'-') - 1) IN (
                        'STORAGE'
                    )
                    AND   ol.item_type_code = 'SERVICE';

                IF
                    g_line_count_storage <> 0
                THEN
                    RETURN p_payload;
                END IF;
            ELSE
                NULL;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                g_context_name2 := 'Exception in IOT block';
                p_error_code := sqlcode;
                p_error_message := sqlerrm;
                insert_error(p_error_code,p_error_message,g_module,g_context_name2,g_context_id,errbuf);
        END;

        FOR i IN 1..iot_parent_parts.count LOOP
            l_payload_parent_line_item :=-1;
            l_payload_parent_line_item := is_item_exists(iot_parent_parts(i) );
            IF
                l_payload_parent_line_item <>-1
            THEN
                FOR each_sub_id IN (
                    SELECT DISTINCT
                        subid_group
                    FROM
                        apxiimd.misimd_tas_insert_line
                    WHERE
                        part_number = iot_parent_parts(i)
                        AND   enabled = 'Y'
                ) LOOP
                    l_new_sub_group := 1;
                    FOR each_line_id IN (
                        SELECT
                            ordered_item,
                            provisioning_group,
                            nvl(quantity,0) quantity,
                            line_text
                        FROM
                            apxiimd.misimd_tas_insert_line
                        WHERE
                            part_number = iot_parent_parts(i)
                            AND   subid_group = each_sub_id.subid_group
                            AND   enabled = 'Y'
                            AND   provisioning_group IS NOT NULL
                            AND   ordered_item IS NOT NULL
                    ) LOOP
                        l_payload_line_item := is_item_exists(each_line_id.ordered_item);
                        l_payload_service_line_item := is_service_exists(each_line_id.provisioning_group);
                        IF
                            l_payload_line_item <>-1
                        THEN
                            SELECT
                                updatexml(l_payload,'/OrderHeader/OrderLines/OrderLine[./@LINEID="'
                                || t_payload_lines(l_payload_line_item).lineid
                                || '"]/LicenseItem/column[(./column[@name="NAME"]="BLOCK_QUANTITY")]/column[@name="VALUE"]/text()', (extractvalue(l_payload,'/OrderHeader/OrderLines/OrderLine[./@LINEID="'
                                || t_payload_lines(l_payload_line_item).lineid
                                || '"]/LicenseItem/column[(./column[@name="NAME"]="BLOCK_QUANTITY")]/column[@name="VALUE"]/text()') + each_line_id.quantity) )
                            INTO
                                l_payload
                            FROM
                                dual;

                        ELSE
                            l_index :=-1;
                            IF
                                ( l_payload_line_item =-1 ) AND l_payload_service_line_item <>-1
                            THEN
            -- part doesn't exists,so check for service group
                                l_index := l_payload_service_line_item;
                                l_new_subscription_id := t_payload_lines(l_index).subscriptionid;
                            ELSE
            -- No Parts exists and No service group,just insert the line with new values
                                SELECT
                                    misont.misont_subscription_id_s1.nextval
                                INTO
                                    l_new_subscription_id
                                FROM
                                    dual;

                                l_index := l_payload_parent_line_item;
                            END IF;

                            SELECT
                                oe_order_lines_s.NEXTVAL
                            INTO
                                l_new_line_id
                            FROM
                                dual;

                            l_line_text_clob := each_line_id.line_text;
                            SELECT
                                replace(l_line_text_clob,'$ASSOCIATED_SUBSCRIPTION_ID$',t_payload_lines(l_index).subscriptionid)
                            INTO
                                l_line_text_clob
                            FROM
                                dual;

                            SELECT
                                replace(l_line_text_clob,'$STARTDATE$',t_payload_lines(l_index).startdate)
                            INTO
                                l_line_text_clob
                            FROM
                                dual;

                            SELECT
                                replace(l_line_text_clob,'$LINE_END_DATE$',t_payload_lines(l_index).line_end_date)
                            INTO
                                l_line_text_clob
                            FROM
                                dual;

                            SELECT
                                replace(l_line_text_clob,'$BUYEREMAILID$',t_payload_lines(l_index).buyeremailid)
                            INTO
                                l_line_text_clob
                            FROM
                                dual;

                            SELECT
                                replace(l_line_text_clob,'$SERVICEADMINEMAILID$',t_payload_lines(l_index).serviceadminemailid)
                            INTO
                                l_line_text_clob
                            FROM
                                dual;

                            SELECT
                                replace(l_line_text_clob,'$DATACENTER$',t_payload_lines(l_index).datacenter)
                            INTO
                                l_line_text_clob
                            FROM
                                dual;

                            l_line_text := xmltype(l_line_text_clob);
                            SELECT
                                updatexml(l_line_text,'/OrderLine/@LINEID',l_new_line_id)
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                updatexml(l_line_text,'/OrderLine/@SUBSCRIPTIONID',l_new_subscription_id)
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                updatexml(l_line_text,'/OrderLine/@BUYEREMAILID',t_payload_lines(l_index).buyeremailid)
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                updatexml(l_line_text,'/OrderLine/@SERVICEADMINEMAILID',t_payload_lines(l_index).serviceadminemailid)
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                updatexml(l_line_text,'/OrderLine/@STARTDATE',t_payload_lines(l_index).startdate)
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                updatexml(l_line_text,'/OrderLine/@LINE_END_DATE',t_payload_lines(l_index).line_end_date)
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                updatexml(l_line_text,'/OrderLine/@DATACENTER',t_payload_lines(l_index).datacenter)
                            INTO
                                l_line_text
                            FROM
                                dual;
							SELECT
                                updatexml(l_line_text,'/OrderLine/@FULFILLMENT_SET',regexp_substr( (extractvalue( (l_line_text),'/OrderLine/@FULFILLMENT_SET') ),'[^-]+',1,1)
                                || '-'
                                || regexp_substr(t_payload_lines(l_index).fulfillment_set,'[^-]+',1,2) )
                            INTO
                                l_line_text
                            FROM
                                dual;
							SELECT
                                updatexml(l_line_text,'/OrderLine/LicenseItem/@FULFILLMENT_SET',regexp_substr( (extractvalue( (l_line_text),'/OrderLine/LicenseItem/@FULFILLMENT_SET') ),'[^-]+',1,1)
                                || '-'
                                || regexp_substr(t_payload_lines(l_index).fulfillment_set,'[^-]+',1,2) )
                            INTO
                                l_line_text
                            FROM
                                dual;

                            SELECT
                                insertxmlafter(l_payload,'/OrderHeader/OrderLines/OrderLine[1]',l_line_text)
                            INTO
                                l_payload
                            FROM
                                dual;
          -- store the exrtra free lines ,so we can track it later from response

                            MERGE INTO apxiimd.misimd_tas_extra_free_line a USING ( SELECT
                                l_new_line_id order_line_id
                                                                                    FROM
                                dual
                            )
                            b ON ( a.order_line_id = b.order_line_id )
                            WHEN MATCHED THEN UPDATE SET a.updated = SYSDATE
                            WHEN NOT MATCHED THEN INSERT (
                                a.order_header_id,
                                                                a.order_line_id,
                                                            a.subscription_id,
                                                        a.line_text,
                                                    a.part_number,
                                                a.status,
                                            a.order_number,
                                        a.associated_subscription_id,
                                    a.created,
                                a.updated
                            ) VALUES (
                                t_payload_lines(l_payload_parent_line_item).orderheaderid,
                                                                l_new_line_id,
                                                            l_new_subscription_id,
                                                        l_payload.getclobval(),
                                                    t_payload_lines(l_payload_parent_line_item).ordereditem,
                                                'ADDED',
                                            t_payload_lines(l_payload_parent_line_item).order_number,
                                        t_payload_lines(l_payload_parent_line_item).subscriptionid,
                                    SYSDATE,
                                SYSDATE
                            );

                        END IF;

                    END LOOP;

                    l_new_sub_group := 0;
                END LOOP;
            END IF;

        END LOOP;

        RETURN l_payload;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN p_payload;
    END append_iot_lines;

    FUNCTION append_iot_lines_old (
        p_payload XMLTYPE
    ) RETURN XMLTYPE IS

        l_payload               XMLTYPE;
        l_new_payload           XMLTYPE;
        l_iot_part_exists       VARCHAR2(10) := NULL;
        l_new_subscription_id   NUMBER;
        l_new_line_id           NUMBER;
        l_line_text             XMLTYPE;
        l_line_text_clob        CLOB;
        TYPE partnumber_table IS
            TABLE OF VARCHAR2(200) INDEX BY VARCHAR2(200);
        iot_parts               partnumber_table;
        c                       NUMBER := 0;
    BEGIN
        l_payload := p_payload;
        FOR iot IN (
            SELECT DISTINCT
                part_number
            FROM
                apxiimd.misimd_tas_insert_line
            WHERE
                enabled = 'Y'
        ) LOOP
            iot_parts(iot.part_number) := iot.part_number;
            c := c + 1;
        END LOOP;

        FOR rec IN (
            SELECT
                xlinetbl.*,
                xhdrtbl.*
            FROM
                XMLTABLE ( '/OrderHeader/OrderLines/OrderLine' PASSING ( l_payload ) COLUMNS ordereditem VARCHAR2(200) PATH './@ORDEREDITEM',startdate VARCHAR2(200) PATH './@STARTDATE'
,line_end_date VARCHAR2(200) PATH './@LINE_END_DATE',subscriptionid VARCHAR2(200) PATH './@SUBSCRIPTIONID',buyeremailid VARCHAR2(200) PATH './@BUYEREMAILID',serviceadminemailid
VARCHAR2(200) PATH './@SERVICEADMINEMAILID',overageopted VARCHAR2(200) PATH './@OVERAGEOPTED',datacenter VARCHAR2(200) PATH './@DATACENTER' ) xlinetbl,
                XMLTABLE ( '/OrderHeader' PASSING l_payload COLUMNS order_number VARCHAR2(200) PATH './column[@name="$$OM_ORDER_NUMBER$$"]',orderheaderid VARCHAR2(200) PATH './@HEADERID'
) xhdrtbl
        ) LOOP
            IF
                iot_parts.EXISTS(rec.ordereditem)
            THEN
                FOR each_sub_id IN (
                    SELECT DISTINCT
                        subid_group
                    FROM
                        apxiimd.misimd_tas_insert_line
                    WHERE
                        part_number = rec.ordereditem
                        AND   enabled = 'Y'
                ) LOOP
                    SELECT
                        misont.misont_subscription_id_s1.nextval
                    INTO
                        l_new_subscription_id
                    FROM
                        dual;

                    FOR each_line_id IN (
                        SELECT
                            line_text
                        FROM
                            apxiimd.misimd_tas_insert_line
                        WHERE
                            part_number = rec.ordereditem
                            AND   subid_group = each_sub_id.subid_group
                            AND   enabled = 'Y'
                    ) LOOP
                        SELECT
                            oe_order_lines_s.NEXTVAL
                        INTO
                            l_new_line_id
                        FROM
                            dual;

                        l_line_text_clob := each_line_id.line_text;
                        SELECT
                            replace(l_line_text_clob,'$ASSOCIATED_SUBSCRIPTION_ID$',rec.subscriptionid)
                        INTO
                            l_line_text_clob
                        FROM
                            dual;

                        SELECT
                            replace(l_line_text_clob,'$STARTDATE$',rec.startdate)
                        INTO
                            l_line_text_clob
                        FROM
                            dual;

                        SELECT
                            replace(l_line_text_clob,'$LINE_END_DATE$',rec.line_end_date)
                        INTO
                            l_line_text_clob
                        FROM
                            dual;

                        SELECT
                            replace(l_line_text_clob,'$BUYEREMAILID$',rec.buyeremailid)
                        INTO
                            l_line_text_clob
                        FROM
                            dual;

                        SELECT
                            replace(l_line_text_clob,'$SERVICEADMINEMAILID$',rec.serviceadminemailid)
                        INTO
                            l_line_text_clob
                        FROM
                            dual;

                        SELECT
                            replace(l_line_text_clob,'$DATACENTER$',rec.datacenter)
                        INTO
                            l_line_text_clob
                        FROM
                            dual;

                        l_line_text := xmltype(l_line_text_clob);
                        SELECT
                            updatexml(l_line_text,'/OrderLine/@LINEID',l_new_line_id)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            updatexml(l_line_text,'/OrderLine/@SUBSCRIPTIONID',l_new_subscription_id)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            updatexml(l_line_text,'/OrderLine/@BUYEREMAILID',rec.buyeremailid)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            updatexml(l_line_text,'/OrderLine/@SERVICEADMINEMAILID',rec.serviceadminemailid)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            updatexml(l_line_text,'/OrderLine/@STARTDATE',rec.startdate)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            updatexml(l_line_text,'/OrderLine/@LINE_END_DATE',rec.line_end_date)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            updatexml(l_line_text,'/OrderLine/@DATACENTER',rec.datacenter)
                        INTO
                            l_line_text
                        FROM
                            dual;

                        SELECT
                            insertxmlafter(l_payload,'/OrderHeader/OrderLines/OrderLine[1]',l_line_text)
                        INTO
                            l_payload
                        FROM
                            dual;
          /* store the exrtra free lines ,so we can track it later from response*/
          /*merge INTO APXIIMD.MISIMD_TAS_EXTRA_FREE_LINE a USING
          (
          SELECT * FROM APXIIMD.MISIMD_TAS_EXTRA_FREE_LINE
          )
          b ON (a.ORDER_LINE_ID = b.ORDER_LINE_ID AND a.ORDER_LINE_ID = l_new_line_id)
          WHEN matched THEN
          UPDATE SET a.UPDATED = sysdate WHEN NOT matched THEN
          */

                        INSERT INTO apxiimd.misimd_tas_extra_free_line a (
                            a.order_header_id,
                            a.order_line_id,
                            a.subscription_id,
                            a.line_text,
                            a.part_number,
                            a.status,
                            a.order_number,
                            a.associated_subscription_id,
                            a.created,
                            a.updated
                        ) VALUES (
                            rec.orderheaderid,
                            l_new_line_id,
                            l_new_subscription_id,
                            l_payload.getclobval(),
                            rec.ordereditem,
                            'ADDED',
                            rec.order_number,
                            rec.subscriptionid,
                            SYSDATE,
                            SYSDATE
                        );

                    END LOOP;

                END LOOP;

            END IF;
        END LOOP;

        RETURN l_payload;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN p_payload;
    END append_iot_lines_old;

    FUNCTION return_parent_line_id (
        p_line_id   IN NUMBER,
        p_type      IN VARCHAR2
    ) RETURN NUMBER AS
        l_partno           VARCHAR2(100);
        l_parent_line_id   NUMBER;
        l_header_id        NUMBER;
    BEGIN
        IF
            ( p_type = 'P' )
        THEN
    /* return the parent line id*/
    /* this call will be made from BPEL post porivisoning when them come back and try to update the Promo SKU*/
            BEGIN
                SELECT
                    pricing_attribute29
                INTO
                    l_parent_line_id
                FROM
                    oe_order_price_attribs
                WHERE
                    line_id = p_line_id;

                IF
                    l_parent_line_id IS NULL
                THEN
                    RETURN -1;
                ELSE
                    RETURN l_parent_line_id;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN -1;
            END;

        ELSIF ( p_type = 'D' ) THEN
    /* Derive the Parent Line ID taking the Part # from the pricing_attribute29*/
    /* No Updates are required in this procedure - just return the value back.*/
            BEGIN
                SELECT
                    pricing_attribute29,
                    header_id
                INTO
                    l_partno,l_header_id
                FROM
                    oe_order_price_attribs
                WHERE
                    line_id = p_line_id;

                IF
                    ( TRIM(translate(l_partno,'0123456789',' ') ) ) IS NULL
                THEN
                    RETURN l_partno;
                END IF;

                IF
                    l_partno IS NULL
                THEN
                    RETURN -1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN -1;
            END;

            BEGIN
                SELECT
                    line_id,
                    header_id
                INTO
                    l_parent_line_id,l_header_id
                FROM
                    oe_order_lines_all
                WHERE
                    ordered_item = l_partno
                    AND   header_id = l_header_id;

                IF
                    l_parent_line_id IS NULL
                THEN
                    RETURN -1;
                ELSE
                    RETURN l_parent_line_id;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN -1;
            END;

        END IF;
    END return_parent_line_id;

    PROCEDURE onboarding (
        itemtype    IN VARCHAR2,
        itemkey     IN VARCHAR2,
        actid       IN NUMBER,
        funcmode    IN VARCHAR2,
        resultout   IN OUT NOCOPY
    /* file.sql.39 change */ VARCHAR2
    ) IS

        l_header_id            NUMBER;
        l_return_status        VARCHAR2(30);
        l_msg_count            NUMBER;
        l_msg_data             VARCHAR2(2000);
        l_line_rec             oe_order_pub.line_rec_type;
        l_old_line_rec         oe_order_pub.line_rec_type;
        p_line_rec             oe_order_pub.line_rec_type;
        l_call_appl_id         NUMBER;
        l_org_id               NUMBER;
        l_organization_id      NUMBER;
        l_result_out           VARCHAR2(100);
        l_top_model_line_id    NUMBER;
        l_dummy                VARCHAR2(2);
        l_line_price_att_rec   oe_order_pub.line_price_att_rec_type;
        x_result               VARCHAR2(100);
  /**/
        l_debug_level          CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  /**/
    BEGIN
  /**/
  /* RUN mode - normal process execution*/
  /**/
        IF
            ( funcmode = 'RUN' )
        THEN
    /*    select header_id into l_header_id from oe_order_lines_all where line_id = to_number ( itemkey ) ;*/
            oe_msg_pub.set_msg_context(p_entity_code => 'HEADER',p_entity_id => to_number(itemkey),p_header_id => to_number(itemkey) );

            IF
                l_debug_level > 0
            THEN
                oe_debug_pub.add('Cloud onboarding');
            END IF;
            IF
                l_debug_level > 0
            THEN
                oe_debug_pub.add('ITEM KEY IS '
                || itemkey);
            END IF;
            oe_standard_wf.set_msg_context(actid);
            SAVEPOINT before_lock;
    /* APPLY TAS INVOCING_HOLD */
    /*      insert into oss_intf_user.MISIMD_SVDEBUG ( msg ) values ('START : Inside onboarding') ;*/
            prepare_notify_payload(itemkey,x_result);
    /* RAISE CUSTOM EVENT  */
            IF
                x_result = 'SUCCESS'
            THEN
                resultout := 'NOTIFIED';
            ELSE
                resultout := x_result;
            END IF;

            oe_standard_wf.save_messages;
            oe_standard_wf.clear_msg_context;
            return;
        END IF;
  /* End for 'RUN' mode*/
  /**/
  /* CANCEL mode - activity 'compensation'*/
  /**/

        IF
            ( funcmode = 'CANCEL' )
        THEN
    /* your cancel code goes here*/
            NULL;
    /* no result needed*/
            resultout := 'COMPLETE';
            return;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
  /* The line below records this function call in the error system*/
  /* in the case of an exception.*/
            wf_core.context('MISIMD_TAS_CLOUD_WF','onboarding',itemtype,itemkey,TO_CHAR(actid),funcmode);
  /* start data fix project*/

            oe_standard_wf.add_error_activity_msg(p_actid => actid,p_itemtype => itemtype,p_itemkey => itemkey);

            oe_standard_wf.save_messages;
            oe_standard_wf.clear_msg_context;
  /* end data fix project*/
            RAISE;
    END onboarding;

    PROCEDURE tenant_activated (
        orderdetails   misimd_cloud_order_tab,
        resultout      OUT NOCOPY VARCHAR2
    ) IS

        l_debug_level      CONSTANT NUMBER := oe_debug_pub.g_debug_level;
        l_parent_line_id   NUMBER;
        l_header_id        NUMBER;
        x_result           VARCHAR2(100);
        l_line_count       NUMBER;
        l_order_status     VARCHAR2(100);
        l_sub_id           VARCHAR2(100);
    BEGIN
        init(p_errror_flag => p_error_flag);
        g_module := 'gsi_activation_update';
        g_context_name2 := 'Update Activation in GSI';
        g_context_id := orderdetails(1).order_header_id;
        resultout := 'SUCCESS';
        l_line_count := orderdetails(1).line_items.count;
        FOR i IN 1..l_line_count LOOP
            SELECT
                pricing_attribute93,
                pricing_attribute92
            INTO
                l_order_status,l_sub_id
            FROM
                oe_order_price_attribs
            WHERE
                line_id = orderdetails(1).line_items(i).line_id;

            IF
                l_order_status <> 'PROVISIONED'
            THEN
                IF
                    ( orderdetails(1).line_items(i).subscription_id IS NOT NULL AND l_sub_id IS NULL )
                THEN
                    UPDATE oe_order_price_attribs
                        SET
                            pricing_attribute92 = orderdetails(1).line_items(i).subscription_id,
                            pricing_attribute93 = orderdetails(1).line_items(i).status
                    WHERE
                        line_id IN (
                            SELECT
                                nonser.line_id
                            FROM
                                oe_order_lines_all nonser,
                                oe_order_lines_all ser
                            WHERE
                                ser.line_id = orderdetails(1).line_items(i).line_id
                                AND   ser.header_id = nonser.header_id
                                AND   ser.line_number = nonser.line_number
                        );

                ELSE
                    UPDATE oe_order_price_attribs
                        SET
                            pricing_attribute93 = orderdetails(1).line_items(i).status
                    WHERE
                        line_id IN (
                            SELECT
                                nonser.line_id
                            FROM
                                oe_order_lines_all nonser,
                                oe_order_lines_all ser
                            WHERE
                                ser.line_id = orderdetails(1).line_items(i).line_id
                                AND   ser.header_id = nonser.header_id
                                AND   ser.line_number = nonser.line_number
                        );

                END IF;

            END IF;

        END LOOP;

        g_audit_message := 'Update Activation in GSI';
        insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,NULL);
    EXCEPTION
        WHEN OTHERS THEN
            g_context_name2 := 'Update Activation in GSI Exception';
            p_error_code := sqlcode;
            p_error_message := sqlerrm;
            insert_log(g_audit_message,1,g_module,g_context_name2,NULL,NULL);
            insert_error(p_error_code,p_error_message,g_module,g_context_name2,g_context_id,errbuf);
            RAISE;
    END tenant_activated;

    PROCEDURE tenant_provisioned (
        orderdetails      misimd_cloud_order_tab,
        om_status_check   IN VARCHAR2,
        resultout         OUT NOCOPY VARCHAR2
    ) IS

        l_debug_level                  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
        l_parent_line_id               NUMBER;
        l_header_id                    NUMBER;
        x_result                       VARCHAR2(100);
        l_line_count                   NUMBER;
        l_line_activity_status         VARCHAR2(20);
        l_flag                         VARCHAR2(1);
        l_cloudorder_type              VARCHAR2(10);
        l_order_status                 VARCHAR2(100);
        l_sub_id                       VARCHAR2(100);
        l_status                       VARCHAR2(20);
        v_startdate                    VARCHAR2(1000);
  /*120.55*/
        v_subscription_id              VARCHAR2(1000);
        v_line_id                      NUMBER;
        l_event_name                   VARCHAR2(200) := 'oracle.apps.misecx.ont.statuschange.update';
        l_source_name                  VARCHAR2(100);
        l_cpq_optype                   VARCHAR2(100);
  /* Split engine variables*/
        l_sp_sengine_flag              VARCHAR2(1);
        l_sp_errbuf                    VARCHAR2(200);
        l_sp_retcode                   VARCHAR2(200);
        l_sp_x_err_msg                 VARCHAR2(200);
        l_sp_x_resultout               VARCHAR2(200);
        l_sp_line_id_list              VARCHAR2(2000);
        l_sp_msg_header_id             NUMBER;
        l_sp_msg_transaction_id        NUMBER;
        l_sp_order_flg                 NUMBER;
        l_sp_msg_transaction_id_list   VARCHAR2(2000);
        l_sp_om_call_api_flg           VARCHAR2(200) := 'N';
        l_sp_fullfillment_chg_flg      VARCHAR2(200) := 'N';
        l_upd_provision_status_flg     VARCHAR2(10) := 'Y';
        l_upd_split_line_confim_flg    VARCHAR2(10) := 'N';
        l_upd_split_waitingon_lines    VARCHAR2(2000) := NULL;
        l_upd_removed_line_list        VARCHAR2(2000) := NULL;
  /* Split engine variables*/
  /* supplement payload var*/
        l_supplement_pay_line_flg      NUMBER;
        l_skip_tas_extra_lines         VARCHAR2(10) := 'N';
        l_is_extra_line                VARCHAR2(10) := 'N';
  /*l_test_opc                varchar2(3000);*/
        l_parent_promo_line_id         NUMBER;
    BEGIN
  /*insert_log_temp ( '1',null);*/
        init(p_errror_flag => p_error_flag);
        g_module := 'gsi_provision_update';
        g_context_name2 := 'Update Provision in GSI';
        SELECT
            nvl(lookup_value,'Y')
        INTO
            l_sp_sengine_flag
        FROM
            oss_intf_user.misimd_intf_lookup
        WHERE
            application = 'GSI-TAS CLOUD BRIDGE'
            AND   component = 'MISIMD_TAS_CLOUD_WF'
            AND   upper(lookup_code) = 'SPLIT_ENGINE_ON_OFF'
            AND   enabled = 'Y';

        BEGIN
            SELECT
                header_id
            INTO
                l_header_id
            FROM
                (
                    SELECT
                        header_id header_id
                    FROM
                        oe_order_lines_all
                    WHERE
                        line_id = orderdetails(1).line_items(1).line_id
                    UNION
                    SELECT
                        order_header_id header_id
                    FROM
                        apxiimd.misimd_tas_extra_free_line
                    WHERE
                        order_line_id = orderdetails(1).line_items(1).line_id
                );

        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        BEGIN
            SELECT
                upper(oes.name)
            INTO
                l_source_name
            FROM
                oe_order_sources oes,
                oe_order_headers_all oh
            WHERE
                oh.order_source_id = oes.order_source_id
                AND   oh.header_id = l_header_id;

        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        g_context_id := l_header_id;
        resultout := 'SUCCESS';
        l_line_count := orderdetails(1).line_items.count;
        l_flag := om_status_check;
        l_status := orderdetails(1).status;
  /*INSERT INTO MISIMD_INTF_AUDIT (AUDIT_MESSAGE,APPLICATION,TIMESTAMP) VALUES (L_TEST_OPC,'OPC_TEST',SYSDATE);
  L_TEST_OPC := L_TEST_OPC||'-'||ORDERDETAILS(1).LINE_ITEMS(1).OPC_ACCOUNT_ID;
  INSERT INTO MISIMD_INTF_AUDIT (AUDIT_MESSAGE,APPLICATION,TIMESTAMP) VALUES (L_TEST_OPC,'OPC_TEST_1',SYSDATE); */
        IF
            l_status IN (
                'PROVISIONED',
                'MIGRATED'
            )
        THEN
            FOR i IN 1..l_line_count LOOP
                BEGIN
                    SELECT
                        pricing_attribute93,
                        pricing_attribute92,
                        header_id,
                        pricing_attribute94
                    INTO
                        l_order_status,l_sub_id,l_header_id,l_cpq_optype
                    FROM
                        oe_order_price_attribs
                    WHERE
                        line_id = orderdetails(1).line_items(i).line_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        l_is_extra_line := 'Y';
                END;

                BEGIN
                    SELECT
                        'Y'
                    INTO
                        l_skip_tas_extra_lines
                    FROM
                        dual
                    WHERE
                        EXISTS (
                            SELECT
                                1
                            FROM
                                apxiimd.misimd_tas_extra_free_line
                            WHERE
                                order_header_id = l_header_id
                                AND   order_line_id = orderdetails(1).line_items(i).line_id
                        );

                EXCEPTION
                    WHEN OTHERS THEN
                        l_skip_tas_extra_lines := 'N';
                END;
      /*-*/
      /**/
      /**/

                IF
                    l_skip_tas_extra_lines = 'Y'
                THEN
        /* Update the extra lines*/
                    UPDATE apxiimd.misimd_tas_extra_free_line
                        SET
                            opc_account_name = nvl(orderdetails(1).line_items(i).opc_account_id,orderdetails(1).opc_account_id),
                            provisioned_date = TO_DATE(orderdetails(1).line_items(i).startdate,'YYYY-MM-DD HH24:MI:SS'),
                            status = 'PROVISIONED',
                            updated = SYSDATE
                    WHERE
                        order_header_id = l_header_id
                        AND   order_line_id = orderdetails(1).line_items(i).line_id;

                ELSIF l_skip_tas_extra_lines = 'N' THEN
                    BEGIN
                        l_upd_removed_line_list := NULL;
                        SELECT
                            removed_line_list
                        INTO
                            l_upd_removed_line_list
                        FROM
                            "APXIIMD"."MISIMD_SKIP_TAS_PROV_LINES"
                        WHERE
                            line_id = orderdetails(1).line_items(i).line_id
                            AND   status = 'AWAIT_PROVISIONING';

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_upd_removed_line_list := NULL;
                    END;
        /**/

                    IF
                        ( l_source_name IN (
                            'CPQ',
                            'IEIGHT'
                        ) AND l_cpq_optype IN (
                            'ONBOARDING',
                            'PILOT_ONBOARDING'
                        ) )
                    THEN
                        UPDATE misont_order_line_attribs_ext
                            SET
                                opc_customer_name = nvl(orderdetails(1).line_items(i).opc_account_id,orderdetails(1).opc_account_id)
                        WHERE
                            header_id = l_header_id
                            AND   line_id IN (
                                ( SELECT
                                    nonser.line_id
                                  FROM
                                    oe_order_lines_all nonser,
                                    oe_order_lines_all ser
                                  WHERE
                                    ser.line_id = orderdetails(1).line_items(i).line_id
                                    AND   ser.header_id = nonser.header_id
                                    AND   ser.line_number = nonser.line_number
                                )
                                UNION
                                ( SELECT
                                    orderdetails(1).line_items(i).line_id
                                  FROM
                                    dual
                                )
                                UNION
                                ( SELECT
                                    to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                  FROM
                                    dual
                                CONNECT BY
                                    regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                )
                            )
                            AND   opc_customer_name IS NULL;
          /**/

                    END IF;
        /**/
        /*-*/

                    BEGIN
                        SELECT
                            COUNT(1)
                        INTO
                            l_supplement_pay_line_flg
                        FROM
                            apxiimd.misimd_supplement_payload
                        WHERE
                            header_id = l_header_id
                            AND   line_id = orderdetails(1).line_items(i).line_id;

                    END;
        /*-*/

                    IF
                        l_supplement_pay_line_flg = 0
                    THEN
                        IF
                            l_flag = 'N'
                        THEN
                            IF
                                l_order_status <> 'PROVISIONED'
                            THEN
              /**/
              /* Get the Split line staging record to get the fullfillemnt_flg*/
              /* default is Y,only when the flag is set to N in the staging table for the line,dont update the status and dates,*/
              /**/
                                BEGIN
                /* distinct is needed here,there could be multple lines*/
                                    SELECT DISTINCT
                                        nvl(fullfillment_chg,'Y')
                                    INTO
                                        l_upd_provision_status_flg
                                    FROM
                                        apxiimd.misimd_tas_split_stage
                                    WHERE
                                        instr(waiting_on,orderdetails(1).line_items(i).line_id) > 0
                                        AND   status = l_split_status_n;

                                EXCEPTION
                                    WHEN OTHERS THEN
                /* this is important*/
                                        l_upd_provision_status_flg := 'Y';
                                END;

                                BEGIN
                /*- Note: this check is on N,reason,the parent lines were not updated to provisioned earlier,*/
                /*- only on the split line confirmation,we are checking the flag to N,and get waiting_on line list*/
                /*-- then update split-line + waiting_on to provisioned with service dates*/
                /*-*/
                /* update the parent lines here,l_upd_split_waitingon_lines contains parent line id.*/
                /* update the parent lines service date,l_upd_split_waitingon_lines contains parent line id.*/
                /* only one line will be there for the given line id*/
                                    SELECT
                                        nvl(fullfillment_chg,'Y'),
                                        waiting_on
                                    INTO
                                        l_upd_split_line_confim_flg,l_upd_split_waitingon_lines
                                    FROM
                                        apxiimd.misimd_tas_split_stage
                                    WHERE
                                        line_id = orderdetails(1).line_items(i).line_id
                                        AND   status = l_split_status_s;
                /* make sure,the waiting on is empty. when the Fullfillment flag is Y,which mean,already provisioned has happened.*/

                                    IF
                                        l_upd_split_line_confim_flg = 'Y'
                                    THEN
                                        l_upd_split_waitingon_lines := orderdetails(1).line_items(i).line_id;
                                    ELSIF l_upd_split_line_confim_flg IS NOT NULL AND l_upd_split_line_confim_flg = 'N' THEN
                  /* Add the child line id also in this list,since the logic to update below is based on group_seq_id,which could be null in*/
                  /* certain*/
                  /* case*/
                  /* Adding here,will make sure,the union query will update these lines too*/
                                        IF
                                            l_upd_split_waitingon_lines IS NOT NULL
                                        THEN
                                            l_upd_split_waitingon_lines := l_upd_split_waitingon_lines
                                            || ','
                                            || orderdetails(1).line_items(i).line_id;

                                        ELSE
                                            l_upd_split_waitingon_lines := orderdetails(1).line_items(i).line_id;
                                        END IF;
                                    END IF;

                                EXCEPTION
                                    WHEN OTHERS THEN
                /* this is important*/
                                        l_upd_split_line_confim_flg := 'Y';
                                        l_upd_split_waitingon_lines := NULL;
                                END;

                                l_parent_promo_line_id := return_parent_line_id(orderdetails(1).line_items(i).line_id,'P');

                                IF
                                    ( l_source_name IN (
                                        'CPQ',
                                        'IEIGHT'
                                    ) AND l_cpq_optype IN (
                                        'ONBOARDING',
                                        'PILOT_ONBOARDING'
                                    ) )
                                THEN
                /**/
                /* Update lines in Pricing attribute as provisioned and Subscription (only if subid is missing - OAE conversion flow)*/
                /**/
                /* union added for the waitingion line id's*/
                /**/
                /*TODO: OPC Accnt name shd be updated irrespective of the flags.*/
                                    IF
                                        l_upd_provision_status_flg = 'Y' OR l_upd_split_line_confim_flg = 'N'
                                    THEN
                  /*log_errors (p_error_message => ' inside Yes ');*/
                  /*log_errors (p_error_message => ' l_upd_split_line_confim_flg  :  ' || l_upd_split_line_confim_flg);*/
                  /*log_errors (p_error_message => ' l_upd_provision_status_flg  :  ' || l_upd_provision_status_flg);*/
                  /*log_errors (p_error_message => ' l_upd_split_waitingon_lines  :  ' || l_upd_split_waitingon_lines);*/
                  /**/
                  /* Update Service date  for the Consolidated provisioned lines*/
                  /**/
                                        FOR cpq_upd IN (
                                            ( SELECT
                                                line_id AS line_id,
                                                orderdetails(1).line_items(i).startdate AS v_startdate
                                              FROM
                                                misimd_om_tas_groups_tbl
                                              WHERE
                                                group_sequence_id IN (
                                                    SELECT
                                                        group_sequence_id
                                                    FROM
                                                        misimd_om_tas_groups_tbl
                                                    WHERE
                                                        ( line_id = orderdetails(1).line_items(i).line_id )
                                                )
                                                OR   line_id IN (
                                                    SELECT
                                                        to_number(TRIM(regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) ) ) line_id
                                                    FROM
                                                        dual
                                                    CONNECT BY
                                                        regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) IS NOT NULL
                                                )
                                            )
                                            UNION
                                            ( SELECT
                                                to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id,
                                                orderdetails(1).line_items(i).startdate AS v_startdate
                                              FROM
                                                dual
                                            CONNECT BY
                                                regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                            )
                                        ) LOOP
                    /*log_errors (p_error_message => ' Updating Lines : '|| cpq_upd.line_id || ' for service start Dates : ' || cpq_upd.v_startdate*/
                    /* );*/
                                            misont_cloud_pub2.update_service_dates(cpq_upd.line_id,cpq_upd.v_startdate);
                                            misont_cloud_pub2.update_service_dates(return_parent_line_id(cpq_upd.line_id,'P'),cpq_upd.v_startdate);
                                        END LOOP;
                  /* update based on LINE_NUMBER*/

                                        UPDATE oe_order_price_attribs
                                            SET
                                                pricing_attribute92 = nvl(pricing_attribute92,orderdetails(1).line_items(i).subscription_id),
                                                pricing_attribute93 = 'PROVISIONED'
                                        WHERE
                                            line_id IN (
                                                (
                                                    SELECT DISTINCT
                                                        line_id line_id
                                                    FROM
                                                        oe_order_lines_all
                                                    WHERE
                                                        ( line_number,
                                                        header_id ) IN (
                                                            SELECT DISTINCT
                                                                line_number,
                                                                header_id
                                                            FROM
                                                                oe_order_lines_all
                                                            WHERE
                                                                ( line_id,
                                                                header_id ) IN (
                                                                    SELECT DISTINCT
                                                                        line_id,
                                                                        header_id
                                                                    FROM
                                                                        misimd_om_tas_groups_tbl
                                                                    WHERE
                                                                        ( group_sequence_id,
                                                                        header_id ) IN (
                                                                            SELECT DISTINCT
                                                                                group_sequence_id,
                                                                                header_id
                                                                            FROM
                                                                                misimd_om_tas_groups_tbl
                                                                            WHERE
                                                                                line_id = orderdetails(1).line_items(i).line_id
                                                                        )
                                                                )
                                                            UNION
                                                            SELECT DISTINCT
                                                                line_number,
                                                                header_id
                                                            FROM
                                                                oe_order_lines_all
                                                            WHERE
                                                                ( line_id ) IN (
                                                                    ( SELECT
                                                                        to_number(TRIM(regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) ) ) line_id
                                                                      FROM
                                                                        dual
                                                                    CONNECT BY
                                                                        regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) IS NOT NULL
                                                                    )
                                                                    UNION
                                                                    ( SELECT
                                                                        to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                                                      FROM
                                                                        dual
                                                                    CONNECT BY
                                                                        regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                                                    )
                                                                )
                                                        )
                                                )
                                            );

                                        UPDATE oe_order_price_attribs
                                            SET
                                                pricing_attribute93 = 'PROVISIONED'
                                        WHERE
                                            line_id IN (
                                                SELECT
                                                    nonser.line_id
                                                FROM
                                                    oe_order_lines_all nonser,
                                                    oe_order_lines_all ser
                                                WHERE
                                                    ser.line_id = l_parent_promo_line_id
                                                    AND   ser.header_id = nonser.header_id
                                                    AND   ser.line_number = nonser.line_number
                                                UNION
                                                SELECT
                                                    orderdetails(1).line_items(i).line_id
                                                FROM
                                                    dual
                                                UNION
                                                ( SELECT
                                                    to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                                  FROM
                                                    dual
                                                CONNECT BY
                                                    regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                                )
                                            );

                                    END IF;
                /* Update Consolidation staging table  as provisioned*/
                /**/

                                    UPDATE misimd_om_tas_groups_tbl
                                        SET
                                            status = 'PROVISIONED'
                                    WHERE
                                        ( line_id,
                                        header_id ) IN (
                                            SELECT DISTINCT
                                                line_id,
                                                header_id
                                            FROM
                                                misimd_om_tas_groups_tbl
                                            WHERE
                                                ( group_sequence_id,
                                                header_id ) IN (
                                                    SELECT DISTINCT
                                                        group_sequence_id,
                                                        header_id
                                                    FROM
                                                        misimd_om_tas_groups_tbl
                                                    WHERE
                                                        line_id = orderdetails(1).line_items(i).line_id
                                                )
                                                AND   header_id = l_header_id
                                        )
                                        OR    (
                                            line_id = orderdetails(1).line_items(i).line_id
                                            AND   group_sequence_id IS NULL
                                        )
                                        OR    ( line_id = l_parent_promo_line_id );

                                ELSE
                /*-*/
                /* For all non-CPQ and CPQ.non-onboarding*/
                                    IF
                                        l_upd_provision_status_flg = 'Y' OR l_upd_split_line_confim_flg = 'N'
                                    THEN
                  /*-TAYALA*/
                                        BEGIN
                                            misont_cloud_pub2.update_service_dates(orderdetails(1).line_items(i).line_id,orderdetails(1).line_items(i).startdate);

                                            misont_cloud_pub2.update_service_dates(return_parent_line_id(orderdetails(1).line_items(i).line_id,'P'),orderdetails(1).line_items(i).startdate);
                    /* Update the Dates for the Filtered Lines*/

                                            v_startdate := orderdetails(1).line_items(i).startdate;
                                            v_subscription_id := orderdetails(1).line_items(i).subscription_id;
                                            v_line_id := orderdetails(1).line_items(i).line_id;
                                            FOR i_line IN (
                                                SELECT
                                                    ol.line_id,
                                                    v_startdate
                                                FROM
                                                    oe_order_price_attribs op,
                                                    oe_order_lines_all ol
                                                WHERE
                                                    pricing_attribute92 = v_subscription_id
                                                    AND   ol.line_id = op.line_id
                                                    AND   op.header_id = l_header_id
                      /* Added for Tuning as per Bug  #20742009*/
                                                    AND   ol.line_id <> v_line_id
                      /* as v_line_id already got processed in above call*/
                                                    AND   op.header_id = l_header_id
                                                    AND   misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                                                        SELECT
                                                            lookup_value
                                                        FROM
                                                            misimd_intf_lookup
                                                        WHERE
                                                            lookup_code = 'PAYLOAD_GROUP'
                                                            AND   application = 'GSI-TAS CLOUD BRIDGE'
                                                            AND   enabled = 'Y'
                                                    )
                                                    AND   l_source_name NOT IN (
                                                        'CPQ',
                                                        'IEIGHT'
                                                    )
                    /* Added as part of 15.3 Solar*/
                                                UNION
                                                ( SELECT DISTINCT
                                                    line_id line_id,
                                                    v_startdate
                                                  FROM
                                                    oe_order_lines_all
                                                  WHERE
                                                    ( line_number,
                                                    header_id ) IN (
                                                        SELECT DISTINCT
                                                            line_number,
                                                            header_id
                                                        FROM
                                                            oe_order_lines_all
                                                        WHERE
                                                            ( line_id ) IN (
                                                                ( SELECT
                                                                    to_number(TRIM(regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) ) ) line_id
                                                                  FROM
                                                                    dual
                                                                CONNECT BY
                                                                    regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) IS NOT NULL
                                                                )
                                                                UNION
                                                                ( SELECT
                                                                    to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                                                  FROM
                                                                    dual
                                                                CONNECT BY
                                                                    regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                                                )
                                                            )
                                                    )
                                                )
                                            ) LOOP
                                                misont_cloud_pub2.update_service_dates(i_line.line_id,i_line.v_startdate);
                                                misont_cloud_pub2.update_service_dates(return_parent_line_id(i_line.line_id,'P'),i_line.v_startdate);
                                            END LOOP;
                    /*TAYALA end*/

                                            IF
                                                l_sub_id IS NULL
                                            THEN
                                                UPDATE oe_order_price_attribs
                                                    SET
                                                        pricing_attribute92 = orderdetails(1).line_items(i).subscription_id,
                                                        pricing_attribute93 = 'PROVISIONED'
                                                WHERE
                                                    line_id IN (
                        /* Added for 14.12 changes 120.52 version*/
                                                        SELECT
                                                            nonser.line_id
                                                        FROM
                                                            oe_order_lines_all nonser,
                                                            oe_order_lines_all ser
                                                        WHERE
                                                            ser.line_id = orderdetails(1).line_items(i).line_id
                                                            AND   ser.header_id = nonser.header_id
                                                            AND   ser.line_number = nonser.line_number
                                                        UNION

                        /* Added as part of 15.3 Solar*/
                                                        SELECT
                                                            ol.line_id
                                                        FROM
                                                            oe_order_lines_all ol,
                                                            oe_order_price_attribs op
                                                        WHERE
                                                            op.pricing_attribute92 = orderdetails(1).line_items(i).subscription_id
                                                            AND   op.header_id = l_header_id
                                                            AND   op.line_id = ol.line_id
                                                            AND   misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                                                                SELECT
                                                                    lookup_value
                                                                FROM
                                                                    misimd_intf_lookup
                                                                WHERE
                                                                    lookup_code = 'PAYLOAD_GROUP'
                                                                    AND   application = 'GSI-TAS CLOUD BRIDGE'
                                                                    AND   enabled = 'Y'
                                                            )
                                                            AND   l_source_name NOT IN (
                                                                'CPQ',
                                                                'IEIGHT'
                                                            )
                                                        UNION

                        /* parent Waiting on lineId*/
                                                        SELECT DISTINCT
                                                            line_id line_id
                                                        FROM
                                                            oe_order_lines_all
                                                        WHERE
                                                            ( line_number,
                                                            header_id ) IN (
                                                                SELECT DISTINCT
                                                                    line_number,
                                                                    header_id
                                                                FROM
                                                                    oe_order_lines_all
                                                                WHERE
                                                                    ( line_id ) IN (
                                                                        ( SELECT
                                                                            to_number(TRIM(regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) ) ) line_id
                                                                          FROM
                                                                            dual
                                                                        CONNECT BY
                                                                            regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) IS NOT NULL
                                                                        )
                                                                        UNION
                                                                        ( SELECT
                                                                            to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                                                          FROM
                                                                            dual
                                                                        CONNECT BY
                                                                            regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                                                        )
                                                                    )
                                                            )
                                                    );
                      /*    ELSIF     misont_cloud_pub2.get_payload_cloud_oper_type(l_header_id,l_sub_id) = 'RAMPED' THEN
                      UPDATE oe_order_price_attribs
                      SET  pricing_attribute93 = Orderdetails(1).line_items(i).status
                      WHERE header_id = l_header_id; */

                                            ELSE
                                                UPDATE oe_order_price_attribs
                                                    SET
                                                        pricing_attribute93 = 'PROVISIONED'
                                                WHERE
                                                    line_id IN (
                        /* Added for 14.12 changes 120.52 version*/
                                                        SELECT
                                                            nonser.line_id
                                                        FROM
                                                            oe_order_lines_all nonser,
                                                            oe_order_lines_all ser
                                                        WHERE
                                                            ser.line_id = orderdetails(1).line_items(i).line_id
                                                            AND   ser.header_id = nonser.header_id
                                                            AND   ser.line_number = nonser.line_number
                                                        UNION

                        /* Added as part of 15.3 Solar*/
                                                        SELECT
                                                            ol.line_id
                                                        FROM
                                                            oe_order_lines_all ol,
                                                            oe_order_price_attribs op
                                                        WHERE
                                                            op.pricing_attribute92 = l_sub_id
                                                            AND   op.header_id = l_header_id
                          /* Added for Tuning as per Bug  #20742009*/
                                                            AND   op.line_id = ol.line_id
                                                            AND   misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                                                                SELECT
                                                                    lookup_value
                                                                FROM
                                                                    misimd_intf_lookup
                                                                WHERE
                                                                    lookup_code = 'PAYLOAD_GROUP'
                                                                    AND   application = 'GSI-TAS CLOUD BRIDGE'
                                                                    AND   enabled = 'Y'
                                                            )
                                                            AND   l_source_name NOT IN (
                                                                'CPQ',
                                                                'IEIGHT'
                                                            )
                                                        UNION
                                                        SELECT DISTINCT
                                                            line_id line_id
                                                        FROM
                                                            oe_order_lines_all
                                                        WHERE
                                                            ( line_number,
                                                            header_id ) IN (
                                                                SELECT DISTINCT
                                                                    line_number,
                                                                    header_id
                                                                FROM
                                                                    oe_order_lines_all
                                                                WHERE
                                                                    ( line_id ) IN (
                                                                        ( SELECT
                                                                            to_number(TRIM(regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) ) ) line_id
                                                                          FROM
                                                                            dual
                                                                        CONNECT BY
                                                                            regexp_substr(l_upd_split_waitingon_lines,'[^,]+',1,level) IS NOT NULL
                                                                        )
                                                                        UNION
                                                                        ( SELECT
                                                                            to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                                                          FROM
                                                                            dual
                                                                        CONNECT BY
                                                                            regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                                                        )
                                                                    )
                                                            )
                                                        UNION
                                                        SELECT
                                                            nonser.line_id
                                                        FROM
                                                            oe_order_lines_all nonser,
                                                            oe_order_lines_all ser
                                                        WHERE
                                                            ser.line_id = l_parent_promo_line_id
                                                            AND   ser.header_id = nonser.header_id
                                                            AND   ser.line_number = nonser.line_number
                                                        UNION
                                                        SELECT
                                                            orderdetails(1).line_items(i).line_id
                                                        FROM
                                                            dual
                                                    );

                                            END IF;
                    /* sub id is null check*/

                                        END;
                  /*TAYALA*/
                                    END IF;
                /* upd_provision_status_flg check*/
                /*-*/
                /* Irrescpective of upd_provision_status_flg ,update OPC account for provisioned lines*/
                /*-*/

                                    UPDATE misont_order_line_attribs_ext
                                        SET
                                            opc_customer_name = nvl(orderdetails(1).line_items(i).opc_account_id,orderdetails(1).opc_account_id)
                                    WHERE
                                        header_id = l_header_id
                                        AND   line_id IN (
                                            SELECT
                                                nonser.line_id
                                            FROM
                                                oe_order_lines_all nonser,
                                                oe_order_lines_all ser
                                            WHERE
                                                ser.line_id = orderdetails(1).line_items(i).line_id
                                                AND   ser.header_id = nonser.header_id
                                                AND   ser.line_number = nonser.line_number
                  /* Added for 14.12 changes 120.52 version*/
                                            UNION
                                            SELECT
                                                ol.line_id
                                            FROM
                                                oe_order_lines_all ol,
                                                oe_order_price_attribs op
                                            WHERE
                                                op.pricing_attribute92 = nvl(l_sub_id,orderdetails(1).line_items(i).subscription_id)
                                                AND   op.header_id = l_header_id
                    /* Added for Tuning as per Bug  #20742009*/
                                                AND   op.line_id = ol.line_id
                                                AND   misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                                                    SELECT
                                                        lookup_value
                                                    FROM
                                                        misimd_intf_lookup
                                                    WHERE
                                                        lookup_code = 'PAYLOAD_GROUP'
                                                        AND   application = 'GSI-TAS CLOUD BRIDGE'
                                                        AND   enabled = 'Y'
                                                )
                                                AND   l_source_name NOT IN (
                                                    'CPQ',
                                                    'IEIGHT'
                                                )
                                            UNION
                                            ( SELECT
                                                to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                              FROM
                                                dual
                                            CONNECT BY
                                                regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                            )
                                        );

                                END IF;

                            END IF;
            /*-- Cloud Rebate Business Event Call -- Move to CC*/

                            IF
                                l_status = 'PROVISIONED' AND ( l_source_name NOT IN (
                                    'CPQ',
                                    'IEIGHT'
                                ) OR l_cpq_optype NOT IN (
                                    'ONBOARDING',
                                    'PILOT_ONBOARDING'
                                ) )
                            THEN
                                FOR cloud_rebate IN (
                                    SELECT
                                        op.line_id,
                                        op.pricing_attribute92,
                                        op.pricing_attribute94
                                    FROM
                                        oe_order_price_attribs op,
                                        oe_order_headers_all ooh
                                    WHERE
                                        pricing_attribute92 = orderdetails(1).line_items(i).subscription_id
                                        AND   op.header_id = l_header_id
                                        AND   op.header_id = ooh.header_id
                                        AND   (
                                            EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    fnd_lookup_values flv
                                                WHERE
                                                    flv.lookup_type = 'SALES_CHANNEL'
                                                    AND   flv.language = 'US'
                                                    AND   flv.attribute3 = 'Y'
                                                    AND   flv.lookup_code = ooh.sales_channel_code
                                            )
                                            OR    EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    oe_agreements_b a,
                                                    fnd_lookup_values c
                                                WHERE
                                                    a.agreement_id = ooh.agreement_id
                                                    AND   c.lookup_code = a.agreement_type_code
                                                    AND   c.lookup_type = 'QP_AGREEMENT_TYPE'
                                                    AND   c.language = 'US'
                                                    AND   c.attribute2 = 'Y'
                                            )
                                            OR    EXISTS
                /*16.12 MSP Changes */ (
                                                SELECT
                                                    1
                                                FROM
                                                    misont_order_line_attribs_ext ext
                                                WHERE
                                                    ext.header_id = l_header_id
                                                    AND   upper(ext.additional_column28) = 'MSP'
                  /*Partner Transaction Type*/
                                            )
                                        )
                                        AND   NOT EXISTS (
                                            SELECT
                                                1
                                            FROM
                                                misozf.misozf_cloud_interface mci
                                            WHERE
                                                mci.om_line_id = op.line_id
                                                AND   TO_CHAR(mci.subscription_id) = op.pricing_attribute92
                                        )
                                    UNION
                                    SELECT
                                        op.line_id,
                                        op.pricing_attribute92,
                                        op.pricing_attribute94
                                    FROM
                                        oe_order_price_attribs op,
                                        oe_order_headers_all ooh
                                    WHERE
                                        op.header_id = l_header_id
                                        AND   op.header_id = ooh.header_id
                                        AND   line_id IN (
                                            SELECT
                                                orderdetails(1).line_items(i).line_id
                                            FROM
                                                dual
                                            UNION
                                            ( SELECT
                                                to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                              FROM
                                                dual
                                            CONNECT BY
                                                regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                            )
                                        )
                                        AND   (
                                            EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    fnd_lookup_values flv
                                                WHERE
                                                    flv.lookup_type = 'SALES_CHANNEL'
                                                    AND   flv.language = 'US'
                                                    AND   flv.attribute3 = 'Y'
                                                    AND   flv.lookup_code = ooh.sales_channel_code
                                            )
                                            OR    EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    oe_agreements_b a,
                                                    fnd_lookup_values c
                                                WHERE
                                                    a.agreement_id = ooh.agreement_id
                                                    AND   c.lookup_code = a.agreement_type_code
                                                    AND   c.lookup_type = 'QP_AGREEMENT_TYPE'
                                                    AND   c.language = 'US'
                                                    AND   c.attribute2 = 'Y'
                                            )
                                            OR    EXISTS
                /*16.12 MSP Changes */ (
                                                SELECT
                                                    1
                                                FROM
                                                    misont_order_line_attribs_ext ext
                                                WHERE
                                                    ext.header_id = l_header_id
                                                    AND   upper(ext.additional_column28) = 'MSP'
                  /*Partner Transaction Type*/
                                            )
                                        )
                                        AND   NOT EXISTS (
                                            SELECT
                                                1
                                            FROM
                                                misozf.misozf_cloud_interface mci
                                            WHERE
                                                mci.om_line_id = op.line_id
                                                AND   TO_CHAR(mci.subscription_id) = op.pricing_attribute92
                                        )
                                ) LOOP
                                    oe_order_util.raise_business_event(p_header_id => l_header_id,p_line_id => cloud_rebate.line_id,p_status => l_status,p_event_name => l_event_name);

                                    INSERT INTO misozf.misozf_cloud_interface (
                                        source,
                                        om_line_id,
                                        subscription_id,
                                        provision_date,
                                        operation_type,
                                        creation_date
                                    ) VALUES (
                                        'OM',
                                        cloud_rebate.line_id,
                                        cloud_rebate.pricing_attribute92,
                                        TO_DATE(orderdetails(1).line_items(i).startdate,'YYYY-MM-DD hh24:mi:ss'),
                                        cloud_rebate.pricing_attribute94,
                                        SYSDATE
                                    );

                                END LOOP;

                            END IF;
            /*
            MISIMD_OM_TAS_GROUPS_TBL set STATUS = 'PROVISIONED'
            WHERE (line_id,header_id) IN
            (SELECT DISTINCT LINE_ID,header_id FROM MISIMD_OM_TAS_GROUPS_TBL WHERE (SERVICE_SEQ,Header_id) IN
            (SELECT DISTINCT SERVICE_SEQ,Header_id FROM MISIMD_OM_TAS_GROUPS_TBL WHERE
            LINE_ID=Orderdetails(1).line_items(i).line_id) and header_id = l_header_id);
            */

                            IF
                                ( l_status = 'PROVISIONED' AND l_source_name IN (
                                    'CPQ',
                                    'IEIGHT'
                                ) AND l_cpq_optype IN (
                                    'ONBOARDING',
                                    'PILOT_ONBOARDING'
                                ) )
                            THEN
                                FOR cloud_rebate IN (
                                    SELECT
                                        op.line_id,
                                        op.pricing_attribute92,
                                        op.pricing_attribute94
                                    FROM
                                        oe_order_price_attribs op,
                                        oe_order_headers_all ooh
                                    WHERE
                                        pricing_attribute92 = orderdetails(1).line_items(i).subscription_id
                                        AND   op.header_id = l_header_id
                                        AND   op.header_id = ooh.header_id
                                        AND   ( op.line_id,
                                        op.header_id ) IN (
                                            SELECT DISTINCT
                                                line_id,
                                                header_id
                                            FROM
                                                misimd_om_tas_groups_tbl
                                            WHERE
                                                ( group_sequence_id,
                                                header_id ) IN (
                                                    SELECT DISTINCT
                                                        group_sequence_id,
                                                        header_id
                                                    FROM
                                                        misimd_om_tas_groups_tbl
                                                    WHERE
                                                        subscription_id = orderdetails(1).line_items(i).subscription_id
                                                )
                                                AND   header_id = l_header_id
                                                AND   status = 'PROVISIONED'
                                        )
                                        AND   (
                                            EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    fnd_lookup_values flv
                                                WHERE
                                                    flv.lookup_type = 'SALES_CHANNEL'
                                                    AND   flv.language = 'US'
                                                    AND   flv.attribute3 = 'Y'
                                                    AND   flv.lookup_code = ooh.sales_channel_code
                                            )
                                            OR    EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    oe_agreements_b a,
                                                    fnd_lookup_values c
                                                WHERE
                                                    a.agreement_id = ooh.agreement_id
                                                    AND   c.lookup_code = a.agreement_type_code
                                                    AND   c.lookup_type = 'QP_AGREEMENT_TYPE'
                                                    AND   c.language = 'US'
                                                    AND   c.attribute2 = 'Y'
                                            )
                                            OR    EXISTS
                  /*16.12 MSP Changes */ (
                                                SELECT
                                                    1
                                                FROM
                                                    misont_order_line_attribs_ext ext
                                                WHERE
                                                    ext.header_id = l_header_id
                                                    AND   upper(ext.additional_column28) = 'MSP'
                    /*Partner Transaction Type*/
                                            )
                                        )
                                        AND   NOT EXISTS (
                                            SELECT
                                                1
                                            FROM
                                                misozf.misozf_cloud_interface mci
                                            WHERE
                                                mci.om_line_id = op.line_id
                                                AND   TO_CHAR(mci.subscription_id) = op.pricing_attribute92
                                        )
                                    UNION
                                    SELECT
                                        op.line_id,
                                        op.pricing_attribute92,
                                        op.pricing_attribute94
                                    FROM
                                        oe_order_price_attribs op,
                                        oe_order_headers_all ooh
                                    WHERE
                                        op.header_id = l_header_id
                                        AND   op.header_id = ooh.header_id
                                        AND   line_id IN (
                                            SELECT
                                                orderdetails(1).line_items(i).line_id
                                            FROM
                                                dual
                                            UNION
                                            ( SELECT
                                                to_number(TRIM(regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) ) ) line_id
                                              FROM
                                                dual
                                            CONNECT BY
                                                regexp_substr(l_upd_removed_line_list,'[^,]+',1,level) IS NOT NULL
                                            )
                                        )
                                        AND   ( op.line_id,
                                        op.header_id ) IN (
                                            SELECT DISTINCT
                                                line_id,
                                                header_id
                                            FROM
                                                misimd_om_tas_groups_tbl
                                            WHERE
                                                ( group_sequence_id,
                                                header_id ) IN (
                                                    SELECT DISTINCT
                                                        group_sequence_id,
                                                        header_id
                                                    FROM
                                                        misimd_om_tas_groups_tbl
                                                    WHERE
                                                        line_id = orderdetails(1).line_items(i).line_id
                                                )
                                                AND   header_id = l_header_id
                                                AND   status = 'PROVISIONED'
                                        )
                                        AND   (
                                            EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    fnd_lookup_values flv
                                                WHERE
                                                    flv.lookup_type = 'SALES_CHANNEL'
                                                    AND   flv.language = 'US'
                                                    AND   flv.attribute3 = 'Y'
                                                    AND   flv.lookup_code = ooh.sales_channel_code
                                            )
                                            OR    EXISTS (
                                                SELECT
                                                    1
                                                FROM
                                                    oe_agreements_b a,
                                                    fnd_lookup_values c
                                                WHERE
                                                    a.agreement_id = ooh.agreement_id
                                                    AND   c.lookup_code = a.agreement_type_code
                                                    AND   c.lookup_type = 'QP_AGREEMENT_TYPE'
                                                    AND   c.language = 'US'
                                                    AND   c.attribute2 = 'Y'
                                            )
                                            OR    EXISTS
                  /*16.12 MSP Changes */ (
                                                SELECT
                                                    1
                                                FROM
                                                    misont_order_line_attribs_ext ext
                                                WHERE
                                                    ext.header_id = l_header_id
                                                    AND   upper(ext.additional_column28) = 'MSP'
                    /*Partner Transaction Type*/
                                            )
                                        )
                                        AND   NOT EXISTS (
                                            SELECT
                                                1
                                            FROM
                                                misozf.misozf_cloud_interface mci
                                            WHERE
                                                mci.om_line_id = op.line_id
                                                AND   TO_CHAR(mci.subscription_id) = op.pricing_attribute92
                                        )
                                ) LOOP
                                    oe_order_util.raise_business_event(p_header_id => l_header_id,p_line_id => cloud_rebate.line_id,p_status => l_status,p_event_name => l_event_name);

                                    INSERT INTO misozf.misozf_cloud_interface (
                                        source,
                                        om_line_id,
                                        subscription_id,
                                        provision_date,
                                        operation_type,
                                        creation_date
                                    ) VALUES (
                                        'OM',
                                        cloud_rebate.line_id,
                                        cloud_rebate.pricing_attribute92,
                                        TO_DATE(orderdetails(1).line_items(i).startdate,'YYYY-MM-DD hh24:mi:ss'),
                                        cloud_rebate.pricing_attribute94,
                                        SYSDATE
                                    );

                                END LOOP;
                            END IF;
            /*delete MISIMD_OM_TAS_GROUPS_TBL where STATUS = 'PROVISIONED' and header_id = l_header_id and date_time < sysdate - 30;*/
            /*  commit;*/

                        END IF;
                    ELSIF l_supplement_pay_line_flg > 0 THEN
          /* handle supplement payload here*/
                        UPDATE apxiimd.misimd_supplement_payload
                            SET
                                status = 'TAS_PROVISIONED',
                                provisioned_sub_id = orderdetails(1).line_items(i).subscription_id,
                                provisioned_date = TO_DATE(orderdetails(1).line_items(i).startdate,'YYYY-MM-DD hh24:mi:ss'),
                                opc_account_name = orderdetails(1).opc_account_id,
                                last_updated_date = SYSDATE
                        WHERE
                            status = 'SENT'
                            AND   header_id = l_header_id
                            AND   line_id = orderdetails(1).line_items(i).line_id;

                    END IF;

                    UPDATE "APXIIMD"."MISIMD_SKIP_TAS_PROV_LINES"
                        SET
                            status = 'PROVISIONED',
                            provisioned_date = TO_DATE(orderdetails(1).line_items(i).startdate,'YYYY-MM-DD hh24:mi:ss'),
                            last_updated_date = SYSDATE
                    WHERE
                        line_id = orderdetails(1).line_items(i).line_id
                        AND   status = 'AWAIT_PROVISIONING';

                END IF;

            END LOOP;
    /*-- Move to CC end--*/
    /*    IF misont_cloud_pub2.get_payload_cloud_oper_type(l_header_id,l_sub_id) = 'RAMPED' THEN*/
    /* 120.65 15.11 Nov 2015 Changes*/
    /* split fullfillment check has not be done,need to the check the cases and code it*/

            IF
                misont_cloud_pub2.get_payload_cloud_oper_type(l_header_id,l_sub_id) IN (
                    'RAMPED',
                    'RAMPED_EXTENSION'
                )
            THEN
      /* Update provisioning status for ramped_update for the the sub_id,as as provisioning confirmation will not come back from SPS/TAS.*/
                UPDATE oe_order_price_attribs
                    SET
                        pricing_attribute93 = 'PROVISIONED'
                WHERE
                    header_id = l_header_id
                    AND   pricing_attribute94 = 'RAMPED_UPDATE'
                    AND   pricing_attribute92 = l_sub_id;
      /* Update OPC account*/

                UPDATE misont_order_line_attribs_ext
                    SET
                        opc_customer_name = orderdetails(1).opc_account_id
                WHERE
                    header_id = l_header_id
                    AND   line_id IN (
                        SELECT
                            line_id
                        FROM
                            oe_order_price_attribs
                        WHERE
                            header_id = l_header_id
                            AND   pricing_attribute94 = 'RAMPED_UPDATE'
                            AND   pricing_attribute92 = l_sub_id
                    );

            END IF;
    /* commented on 16.04,since we need line level opc update UPDATE misont_order_line_attribs_ext
    SET OPC_CUSTOMER_NAME = Orderdetails(1).opc_account_id
    WHERE header_id       = l_header_id;
    END IF; */

        END IF;

        g_audit_message := 'Update Provision in GSI';
        insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,NULL);
        IF
            l_status IN (
                'PROVISIONED',
                'MIGRATED'
            )
        THEN
    /*-*/
    /**/
            BEGIN
                SELECT
                    COUNT(1)
                INTO
                    l_sp_order_flg
                FROM
                    "APXIIMD"."MISIMD_TAS_SPLIT_STAGE"
                WHERE
                    header_id = l_header_id;

            END;
    /*-*/
    /* 16.4 Changes for Split Engine Logic <<<START>>>*/

            IF
                l_sp_sengine_flag = 'Y' AND l_sp_order_flg > 0
            THEN
                BEGIN
        /*log_errors (p_error_message => ' Split Order  :  ' || l_header_id);*/
                    l_sp_msg_transaction_id_list := NULL;
                    l_sp_msg_transaction_id := NULL;
                    l_line_count := orderdetails(1).line_items.count;
                    l_sp_line_id_list := NULL;
                    FOR i IN 1..l_line_count LOOP
          /* Update the Sent to Completed based each lines in the message*/
                        UPDATE apxiimd.misimd_tas_split_stage
                            SET
                                status = l_split_status_c,
                                last_updated_date = SYSDATE
                        WHERE
                            line_id = to_number(orderdetails(1).line_items(i).line_id)
                            AND   status = l_split_status_s;
          /* Update the New to Ready based each lines in the message*/

                        UPDATE apxiimd.misimd_tas_split_stage
                            SET
                                status = l_split_status_r,
                                last_updated_date = SYSDATE
                        WHERE
                            instr(waiting_on,orderdetails(1).line_items(i).line_id) > 0
                            AND   status = l_split_status_n;
          /* if there is any ready update above,get flag to call OM_CALL*/

                        BEGIN
                            SELECT DISTINCT
                                fullfillment_chg
                            INTO
                                l_sp_fullfillment_chg_flg
                            FROM
                                apxiimd.misimd_tas_split_stage
                            WHERE
                                instr(waiting_on,orderdetails(1).line_items(i).line_id) > 0
                                AND   status = l_split_status_r;

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_sp_fullfillment_chg_flg := NULL;
                        END;
          /* Set the OM_CALL flag based on (if any line updated + fullfillment flag )*/

                        IF
                            l_sp_om_call_api_flg = 'N' AND l_sp_fullfillment_chg_flg = 'Y'
                        THEN
                            l_sp_om_call_api_flg := 'Y';
                        END IF;
          /*- If the single msg contains mulitple transaction,need to handle it here*/
                        BEGIN
                            SELECT DISTINCT
                                transaction_id
                            INTO
                                l_sp_msg_transaction_id
                            FROM
                                apxiimd.misimd_tas_split_stage
                            WHERE
                                instr(waiting_on,orderdetails(1).line_items(i).line_id) > 0
                                AND   status = l_split_status_r;

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_sp_msg_transaction_id := NULL;
                        END;
          /* Form the Transaction list*/

                        IF
                            l_sp_msg_transaction_id IS NOT NULL
                        THEN
                            IF
                                l_sp_msg_transaction_id_list IS NULL
                            THEN
                                l_sp_msg_transaction_id_list := l_sp_msg_transaction_id;
                            ELSIF instr(l_sp_msg_transaction_id_list,l_sp_msg_transaction_id) = 0 THEN
                                l_sp_msg_transaction_id_list := l_sp_msg_transaction_id_list
                                || ','
                                || l_sp_msg_transaction_id;
                            END IF;
            /*log_errors (p_error_message => '   l_sp_msg_transaction_id  :  ' || l_sp_msg_transaction_id);*/
            /*log_errors (p_error_message => '   l_sp_msg_transaction_id_list  :  ' || l_sp_msg_transaction_id_list);*/
                        END IF;
          /* Form the lines list*/

                        IF
                            l_sp_line_id_list IS NULL
                        THEN
                            l_sp_line_id_list := orderdetails(1).line_items(i).line_id;
                        ELSE
                            l_sp_line_id_list := l_sp_line_id_list
                            || ','
                            || orderdetails(1).line_items(i).line_id;
                        END IF;

                    END LOOP;

                    BEGIN
          /* Call OM API*/
          /* send it only when the flag is Y*/
                        IF
                            l_sp_om_call_api_flg = 'Y'
                        THEN
            /* Loop misimd_cloud_order_tab and get Line_id csv and send it*/
            /*NULL;*/
                            misont_cloud_pub2.add_remove_lines_to_ffset(l_sp_line_id_list,l_sp_x_err_msg,l_sp_x_resultout);
                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            UPDATE apxiimd.misimd_tas_split_stage
                                SET
                                    comments = 'ERROR in OM FF update'
                            WHERE
                                transaction_id = l_sp_msg_transaction_id;
          /* Even if external call is erroring ,ignore and proceed.*/

                    END;

                    BEGIN
                        IF
                            l_sp_msg_transaction_id_list IS NOT NULL
                        THEN
                            FOR each_transaction IN (
                                WITH data AS (
                                    SELECT
                                        l_sp_msg_transaction_id_list str
                                    FROM
                                        dual
                                ) SELECT
                                    TRIM(regexp_substr(str,'[^,]+',1,level) ) stg_trans
                                  FROM
                                    data
                                CONNECT BY
                                    regexp_substr(str,'[^,]+',1,level) IS NOT NULL
                            ) LOOP
              /*insert into loglog values(sysdate,'each_transaction.stg_trans  ' || each_transaction.stg_trans);*/
              /**/
              /*log_errors (p_error_message => );*/
                                IF
                                    each_transaction.stg_trans IS NOT NULL
                                THEN
                /*log_errors (p_error_message => '   before calling Concrrent prm call for  :  ' || each_transaction.stg_trans);*/
                                    split_concurrent_pgm(to_number(each_transaction.stg_trans) );
                                END IF;
              /*insert into loglog values(sysdate,' @ last  ' || each_transaction.stg_trans);*/
                            END LOOP;

                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
          /* No transactionID handled*/
                    END;

                END;

            END IF;
    /* 16.4 Changes for Split Engine Logic <<<END>>>*/
    /*-*/
    /**/

        END IF;
  /*--*/

    EXCEPTION
        WHEN OTHERS THEN
            g_context_name2 := 'Update Provision in GSI Exception';
            p_error_code := sqlcode;
            p_error_message := sqlerrm;
            insert_log(g_audit_message,1,g_module,g_context_name2,NULL,NULL);
            insert_error(p_error_code,p_error_message,g_module,g_context_name2,g_context_id,errbuf);
            RAISE;
    END tenant_provisioned;

    PROCEDURE insert_log_temp (
        k1 VARCHAR2,
        val VARCHAR2
    )
        IS
    BEGIN
  /*insert into cloud_prov_log values (sysdate,k1 ,val  )*/
        NULL;
    END insert_log_temp;

    PROCEDURE updatetransaction (
        transaction_id_in   IN VARCHAR2,
        p_request_source    IN VARCHAR2 DEFAULT NULL
    ) IS

        l_dependency                VARCHAR2(500);
        l_primary_rule              VARCHAR2(500);
        l_line_id                   VARCHAR2(500);
        l_subscription_id           VARCHAR2(500);
        l_header_id                 VARCHAR2(500);
        l_fulfillment_set           VARCHAR2(500);
        l_validate_ordered_item     NUMBER;
        l_rule_group_id             NUMBER;
        l_service_seq               VARCHAR2(500);
        l_count_rule_group_id       NUMBER;
        l_invalid_seq_list          VARCHAR2(1500);
        l_group_line_found          NUMBER;
        l_non_combined_seq          NUMBER;
        l_new_group_sequence_id     NUMBER;
        l_data_center_region        VARCHAR2(1500);
        l_tas_condition             VARCHAR2(1500);
        l_send_to_tas_flg           VARCHAR2(10);
        l_optional_includes_count   NUMBER;
        l_temp_trans_id             NUMBER;
        l_hold_ord_on_payg_err      VARCHAR2(10) := 'N';
  /* Error Messages variables*/
        l_primary_attribute_flg     VARCHAR2(500);
        l_error_msg_on_extra        VARCHAR2(1500);
        l_error_attributes          VARCHAR2(1500);
        l_extra_line_error          VARCHAR2(500);
        l_error_msg                 VARCHAR2(1500) := 'PROV_PAYLOAD_PREP_ERROR : ';
        l_error_msg_1               VARCHAR2(500) := 'Missing dependency : ';
        l_error_msg_2               VARCHAR2(500) := 'Extra lines : ';
        l_error_msg_3               VARCHAR2(500) := 'Invalid Service Sequence : ';
  /* ravelard,Bug 23721476 begin Jul 15th,2016*/
        v_header_id                 NUMBER;
        l_commit                    VARCHAR2(1) := 'Y';
  /* ravelard,end Jul 15th,2016*/
        CURSOR c_get_service_line (
            cp_seq IN VARCHAR2
        ) IS SELECT
            ordered_item,
            service_grp,
            line_id,
            group_sequence_id,
            co_term_sub_id,
            subscription_id,
            header_id,
            fulfillment_set
             FROM
            misimd_om_tas_groups_tbl
             WHERE
            transaction_id = transaction_id_in
            AND   service_seq = cp_seq;

        CURSOR c_get_transaction_seq IS SELECT DISTINCT
            service_seq AS service_seq
                                        FROM
            misimd_om_tas_groups_tbl
                                        WHERE
            transaction_id = transaction_id_in
        ORDER BY
            service_seq;

        CURSOR c_get_dependency (
            cp_service_grp     IN VARCHAR2,
            cp_ordered_item    IN VARCHAR2,
            cp_rule_group_id   IN NUMBER
        ) IS SELECT
            dependency,
            primary_rule,
            rule_group_id
             FROM
            apxiimd.misimd_tas_consolidation_rules v
             WHERE
            v.enabled = 'Y'
            AND   (
                (
                    v.provisioning_group = cp_service_grp
                    AND   v.item_value IS NULL
                )
                OR    (
                    v.provisioning_group = cp_service_grp
                    AND   v.item_value = cp_ordered_item
                )
            )
            AND   v.rule_group_id = cp_rule_group_id
        ORDER BY
            v.rule_group_order;

    BEGIN
  /* ravelard,Bug 23721476 begin Jul 15th,2016*/
        SELECT DISTINCT
            header_id
        INTO
            v_header_id
        FROM
            misimd_om_tas_groups_tbl
        WHERE
            transaction_id = transaction_id_in;

        insert_log(g_audit_message => 'updatetransaction...begins',g_audit_level => 3,g_module => 'Prepare_Notify_Payload',g_context_name2 => 'transaction_id_in: '
        || transaction_id_in
        || ' p_request_source: '
        || p_request_source
        || ' v_header_id: '
        || v_header_id,g_context_id => v_header_id,g_audit_attachment => NULL);
  /* ravelard,end Jul 15th,2016*/

        l_invalid_seq_list := NULL;
        l_primary_attribute_flg := NULL;
        BEGIN
            SELECT
                lookup_value
            INTO
                l_hold_ord_on_payg_err
            FROM
                misimd_intf_lookup
            WHERE
                lookup_code = 'HOLD_ORD_ON_PAYG_ERR'
                AND   application = 'GSI-TAS CLOUD BRIDGE'
                AND   component = 'MISIMD_TAS_CLOUD_WF'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_hold_ord_on_payg_err := 'N';
        END;
  /*Commit Changes*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'PROCEDURE_UPDATE_TRANSACTION_COMMIT'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;
  /*End Commit Changes*/
  /*// Count -999 serive seq*/
  /*// if exists,mark the transaction as error ,other wise proceed to*/
  /* validate*/

        SELECT
            LISTAGG('For SUBID : '
            || subscription_id
            || ' | Line : '
            || line_id
            || ' | Fulfillment : '
            || fulfillment_set,
            ',') WITHIN GROUP(
            ORDER BY
                line_id
            )
        INTO
            l_invalid_seq_list
        FROM
            misimd_om_tas_groups_tbl
        WHERE
            transaction_id = transaction_id_in
            AND   service_seq = '-999';

        IF
            l_invalid_seq_list IS NOT NULL
        THEN
            l_error_msg := l_error_msg
            || l_error_msg_3
            || l_invalid_seq_list;
            UPDATE misimd_om_tas_groups_tbl
                SET
                    comments = l_error_msg,
                    status = 'ERROR'
            WHERE
                transaction_id = transaction_id_in;
    /* Commit changes*/

            IF
                l_commit = 'Y'
            THEN
                COMMIT;
            END IF;
        ELSE
            FOR seq_group IN c_get_transaction_seq LOOP
                l_rule_group_id := 0;
                l_service_seq := seq_group.service_seq;
                l_new_group_sequence_id := misimd_om_tas_grouping_trans.nextval;
      /* find group_sequence_id for this sequence*/
      /* if we get group_sequence_id proceed to validate the group */
      /*Exception 1 if these items does not exists in primary */
      /*---- check 1 if the other items belongs to lookup,
      if it belongs to the lookup then,mark the sequence as error
      else Skip the sequence*/
      /*-16:04,since multi group needs to find min rule group for the order*/
                SELECT
                    nvl(MIN(rule_group_id),0)
                INTO
                    l_rule_group_id
                FROM
                    misimd_om_tas_groups_tbl trans,
                    apxiimd.misimd_tas_consolidation_rules rul
                WHERE
                    trans.transaction_id = transaction_id_in
                    AND   trans.service_seq = seq_group.service_seq
                    AND   rul.primary_rule = 'Y'
                    AND   rul.enabled = 'Y'
                    AND   (
                        (
                            rul.provisioning_group = trans.service_grp
                            AND   rul.item_value IS NULL
                        )
                        OR    (
                            rul.provisioning_group = trans.service_grp
                            AND   rul.item_value = trans.ordered_item
                        )
                    );

                IF
                    l_rule_group_id > 0
                THEN
                    FOR seq_line IN c_get_service_line(seq_group.service_seq) LOOP
                        l_group_line_found := 0;
                        l_line_id := seq_line.line_id;
                        l_subscription_id := seq_line.subscription_id;
                        l_header_id := seq_line.header_id;
                        l_fulfillment_set := seq_line.fulfillment_set;
          /* find this service_grp or ordered_item belongs to l_rule_group_id*/
          /* if it is,then update the group_sequence for the line and its
          dependencies*/
                        BEGIN
                            SELECT
                                upper(nvl(TRIM(lookup_value),'N') )
                            INTO
                                l_send_to_tas_flg
                            FROM
                                misimd_intf_lookup
                            WHERE
                                application = 'GSI-TAS CLOUD BRIDGE'
                                AND   lookup_code = 'SEND_EXTSITE_TO_TAS';

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_send_to_tas_flg := 'N';
                        END;

                        BEGIN
            /*- Get lookup*/
                            SELECT
                                nvl(upper(TRIM(lookup_value) ),'X')
                            INTO
                                l_tas_condition
                            FROM
                                misimd_intf_lookup
                            WHERE
                                application = 'GSI-TAS CLOUD BRIDGE'
                                AND   lookup_code = 'TAS_ENABLED_CONDITION';
            /* get Data center region*/

                            SELECT
                                TRIM(op.pricing_attribute99)
                            INTO
                                l_data_center_region
                            FROM
                                oe_order_price_attribs op,
                                oe_order_headers_all oh
                            WHERE
                                op.header_id = l_header_id
                                AND   op.header_id = oh.header_id
                                AND   op.line_id = l_line_id
                                AND   ROWNUM = 1;

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_tas_condition := NULL;
                        END;

                        SELECT
                            COUNT(1)
                        INTO
                            l_group_line_found
                        FROM
                            apxiimd.misimd_tas_consolidation_rules v
                        WHERE
                            v.enabled = 'Y'
                            AND   v.rule_group_id = l_rule_group_id
                            AND   (
                                (
                                    v.provisioning_group = seq_line.service_grp
                                    AND   v.item_value IS NULL
                                )
                                OR    (
                                    v.provisioning_group = seq_line.service_grp
                                    AND   v.item_value = seq_line.ordered_item
                                )
                            );

                        IF
                            l_group_line_found > 0 AND ( upper(nvl(l_data_center_region,'-999') ) <> upper(nvl(l_tas_condition,'X') ) )
                        THEN
            /*update the line_id for the group_sequence_number */
                            UPDATE misimd_om_tas_groups_tbl
                                SET
                                    group_sequence_id = l_new_group_sequence_id
                            WHERE
                                transaction_id = transaction_id_in
                                AND   service_seq = seq_group.service_seq
                                AND   line_id = seq_line.line_id;
            /* commit changes*/

                            IF
                                l_commit = 'Y'
                            THEN
                                COMMIT;
                            END IF;
                            IF
                                ( seq_line.co_term_sub_id IS NOT NULL )
                            THEN
                                UPDATE misimd_om_tas_groups_tbl
                                    SET
                                        group_sequence_id = l_new_group_sequence_id
                                WHERE
                                    transaction_id = transaction_id_in
                                    AND   service_seq = seq_group.service_seq
                                    AND   service_grp = seq_line.service_grp
                                    AND   subscription_id = seq_line.subscription_id
                                    AND   co_term_sub_id IS NOT NULL;

                                FOR c1 IN (
                                    SELECT
                                        subscription_id,
                                        service_grp
                                    FROM
                                        misimd_om_tas_groups_tbl
                                    WHERE
                                        service_seq = seq_group.service_seq
                                        AND   transaction_id = transaction_id_in
                                        AND   group_sequence_id IS NULL
                                        AND   co_term_sub_id IS NOT NULL
                                    GROUP BY
                                        subscription_id,
                                        service_grp
                                ) LOOP
                                    l_temp_trans_id := misimd_om_tas_grouping_trans.nextval;
                                    UPDATE misimd_om_tas_groups_tbl
                                        SET
                                            group_sequence_id = l_temp_trans_id
                                    WHERE
                                        transaction_id = transaction_id_in
                                        AND   service_seq = seq_group.service_seq
                                        AND   service_grp = c1.service_grp
                                        AND   subscription_id = c1.subscription_id
                                        AND   group_sequence_id IS NULL
                                        AND   co_term_sub_id IS NOT NULL;

                                END LOOP;
              /* commit changes*/

                                IF
                                    l_commit = 'Y'
                                THEN
                                    COMMIT;
                                END IF;
                            END IF;
            /* check the dependencies and update them as well
            */

                            l_error_attributes := NULL;
                            FOR dependent_line IN c_get_dependency(seq_line.service_grp,seq_line.ordered_item,l_rule_group_id) LOOP
                                l_dependency := dependent_line.dependency;
                                l_primary_rule := dependent_line.primary_rule;

								/*SRECHAND Changes start for 27524361 */
                                BEGIN
									select pricing_attribute99 into l_extsite_check
									from oe_order_price_attribs
									where line_id=seq_line.line_id;

									EXCEPTION
									WHEN OTHERS THEN
									l_extsite_check   := NULL;
                                END;

                                BEGIN
                                  select code2
                                        INTO l_associate_needed
                                              FROM glob_ref_codes_all
                                              WHERE domain = 'MISIMD_COMMIT_TAS_GRP'
                                              AND code IN ('ASSOCIATE_CHECK');

                                  EXCEPTION
                                  WHEN OTHERS THEN
                                  l_associate_needed   := 'N';
                                END;

                                BEGIN

									IF (l_extsite_check = 'EXTSITE') THEN
									select get_associated_sub_id (seq_line.line_id) into l_associate_sub_id_check from dual;
									END IF;

									EXCEPTION
									WHEN OTHERS THEN
									l_associate_sub_id_check   := NULL;
								END;

                                IF
                                  l_dependency IS NOT NULL AND l_primary_rule = 'Y' AND  seq_line.co_term_sub_id IS NULL AND (l_associate_sub_id_check IS NULL AND l_associate_needed = 'Y') /*SRECHAND Changes end for 27524361 */

                                THEN
                                    l_primary_attribute_flg := 'N';
                                    FOR dependent_rec IN (
                                        WITH data AS (
                                            SELECT
                                                l_dependency str
                                            FROM
                                                dual
                                        ) SELECT
                                            TRIM(regexp_substr(str,'[^,]+',1,level) ) str
                                          FROM
                                            data
                                        CONNECT BY
                                            regexp_substr(str,'[^,]+',1,level) IS NOT NULL
                                    ) LOOP
                                        l_validate_ordered_item := 0;
                                        SELECT
                                            COUNT(*)
                                        INTO
                                            l_validate_ordered_item
                                        FROM
                                            misimd_om_tas_groups_tbl
                                        WHERE
                                            transaction_id = transaction_id_in
                                            AND   service_seq = seq_group.service_seq
                                            AND   (
                                                ( ordered_item = dependent_rec.str )
                                                OR    ( service_grp = dependent_rec.str )
                                            );

                                        IF
                                            nvl(l_validate_ordered_item,'0') < 1
                                        THEN
                                            l_primary_attribute_flg := 'Y';
                    /*dbms_output.put_line(' dependent does not exists  ' );*/
                                        ELSE
                                            NULL;
                    /*dbms_output.put_line(' dependent exists  ' );*/
                    /* dependent items 'Exists in transaction ordered_item'*/
                                        END IF;
                  /* whether item exists or not*/

                                        EXIT WHEN l_primary_attribute_flg = 'Y';
                                    END LOOP;

                                END IF;

                                IF
                                    nvl(l_primary_attribute_flg,'NULL') = 'Y'
                                THEN
                                    l_error_attributes := coalesce(nullif(l_error_attributes
                                    || ' or ',' or '),'')
                                    || l_dependency;
                                END IF;
              /* end of dependencies*/

                                EXIT WHEN l_primary_attribute_flg = 'N';
                            END LOOP;

                            IF
                                nvl(l_primary_attribute_flg,'NULL') = 'Y'
                            THEN
                                l_error_msg := l_error_msg
                                || l_error_msg_1
                                || 'For SUBID : '
                                || l_subscription_id
                                || ' | Line : '
                                || l_line_id
                                || ' | Fulfillment : '
                                || l_fulfillment_set;

                                l_error_msg := l_error_msg
                                || ' Validation error '
                                || 'Missing dependency '
                                || l_error_attributes;
                                UPDATE misimd_om_tas_groups_tbl
                                    SET
                                        comments = l_error_msg,
                                        status = 'ERROR'
                                WHERE
                                    transaction_id = transaction_id_in
                                    AND   service_seq = seq_group.service_seq;
              /*Commit Changes*/

                                IF
                                    l_commit = 'Y'
                                THEN
                                    COMMIT;
                                END IF;
                            END IF;

                        END IF;

                        EXIT WHEN l_primary_attribute_flg = 'Y';
                    END LOOP;
        /*-*/
        /* Before Extra line check*/
        /* get the list of null group seq*/
        /* check if item or servicegrp exists in rule table optional_includes*/
        /* if available update the group seq.*/
        /* loop thru the list and update group_sequence_id for all item's in the list with l_new_group_sequence_id*/
        /*-*/

                    FOR check_optional IN (
                        SELECT
                            ordered_item,
                            service_grp,
                            line_id
                        FROM
                            misimd_om_tas_groups_tbl
                        WHERE
                            transaction_id = transaction_id_in
                            AND   service_seq = l_service_seq
                            AND   (
                                group_sequence_id IS NULL
                                OR    group_sequence_id <> l_new_group_sequence_id
                            )
                    ) LOOP
                        SELECT
                            COUNT(1)
                        INTO
                            l_optional_includes_count
                        FROM
                            apxiimd.misimd_tas_consolidation_rules
                        WHERE
                            rule_group_id = l_rule_group_id
                            AND   (
                                instr(optional_includes,check_optional.ordered_item) > 0
                                OR    instr(optional_includes,check_optional.service_grp) > 0
                            );

                        IF
                            l_optional_includes_count > 0
                        THEN
            /*update the line_id for the group_sequence_number */
                            UPDATE misimd_om_tas_groups_tbl
                                SET
                                    group_sequence_id = l_new_group_sequence_id
                            WHERE
                                transaction_id = transaction_id_in
                                AND   service_seq = l_service_seq
                                AND   line_id = check_optional.line_id;
            /* commit changes*/

                            IF
                                l_commit = 'Y'
                            THEN
                                COMMIT;
                            END IF;
                        END IF;

                    END LOOP;

                    l_error_msg_on_extra := NULL;
                    IF
                        nvl(l_primary_attribute_flg,'NULL') <> 'Y' AND ( upper(l_data_center_region) <> upper(nvl(l_tas_condition,'X') ) )
                    THEN
          /* check extra lines error,only if its not already errored out*/
                        SELECT
                            LISTAGG('For SUBID : '
                            || subscription_id
                            || ' | Line : '
                            || line_id
                            || ' | Fulfillment : '
                            || fulfillment_set,
                            ',') WITHIN GROUP(
                            ORDER BY
                                line_id
                            )
                        INTO
                            l_error_msg_on_extra
                        FROM
                            misimd_om_tas_groups_tbl
                        WHERE
                            transaction_id = transaction_id_in
                            AND   service_seq = l_service_seq
                            AND   group_sequence_id IS NULL;

                        IF
                            l_error_msg_on_extra IS NOT NULL
                        THEN
                            l_error_msg := l_error_msg
                            || l_error_msg_2
                            || l_error_msg_on_extra;
                            l_primary_attribute_flg := 'Y';
            /* extra lines are available which does not belong to this group.*/
            /*so update as failed and exit this sequence*/
                            UPDATE misimd_om_tas_groups_tbl
                                SET
                                    comments = l_error_msg,
                                    status = 'ERROR'
                            WHERE
                                transaction_id = transaction_id_in
                                AND   service_seq = seq_group.service_seq;
            /* commit changes*/

                            IF
                                l_commit = 'Y'
                            THEN
                                COMMIT;
                            END IF;
                        END IF;
          /* check if extra lines*/

                    END IF;
        /* check if primary error flag*/

                END IF;
      /* seq_group > 0 check /* end group_sequence_id*/

                EXIT WHEN ( l_hold_ord_on_payg_err = 'Y' AND l_primary_attribute_flg = 'Y' );
            END LOOP;

            IF
                nvl(l_primary_attribute_flg,'NULL') = 'Y'
            THEN
                UPDATE misimd_om_tas_groups_tbl
                    SET
                        comments = l_error_msg,
                        status = 'ERROR'
                WHERE
                    transaction_id = transaction_id_in;

                IF
                    p_request_source <> 'PAYGEN'
                THEN
                    UPDATE oe_order_price_attribs
                        SET
                            pricing_attribute93 = substr(l_error_msg,1,230)
                    WHERE
                        header_id = l_header_id
                        AND   pricing_attribute93 = 'AWAIT PROVISIONING';

                END IF;
      /* commit changes*/

                IF
                    l_commit = 'Y'
                THEN
                    COMMIT;
                END IF;
            ELSE
      /* No error in grouping ,so check for non-combined lines*/
                FOR non_combined_rec IN (
                    SELECT DISTINCT
                        subscription_id,
                        fulfillment_set
                    FROM
                        misimd_om_tas_groups_tbl
                    WHERE
                        transaction_id = transaction_id_in
                        AND   group_sequence_id IS NULL
                ) LOOP
                    l_non_combined_seq := misimd_om_tas_grouping_trans.nextval;
                    UPDATE misimd_om_tas_groups_tbl
                        SET
                            group_sequence_id = l_non_combined_seq
                    WHERE
                        transaction_id = transaction_id_in
                        AND   subscription_id = non_combined_rec.subscription_id
                        AND   fulfillment_set = non_combined_rec.fulfillment_set;

                END LOOP;
      /* commit changes*/

                IF
                    l_commit = 'Y'
                THEN
                    COMMIT;
                END IF;
            END IF;

        END IF;
  /* // -999 Seq validation end if.*/

    EXCEPTION
        WHEN OTHERS THEN
            NULL;
  /*raise_application_error(-20001,'An error was encountered - '||SQLCODE||'*/
  /* -*/
  /* ERROR- '||sqlerrm);*/
    END;

    PROCEDURE ins_supplement_payload (
        p_header_id            IN NUMBER,
        p_line_id              IN NUMBER,
        p_provisioned_sub_id   IN NUMBER,
        p_associate_sub_id     IN NUMBER,
        p_status               IN VARCHAR2,
        g_xml                  IN CLOB
    ) IS
        l_commit   VARCHAR2(1) := 'Y';
    BEGIN
        INSERT INTO apxiimd.misimd_supplement_payload (
            transaction_id,
            header_id,
            line_id,
            provisioned_sub_id,
            associate_sub_id,
            status,
            sent_time
        ) VALUES (
            misimd_om_tas_grouping_trans.NEXTVAL,
            p_header_id,
            p_line_id,
            p_provisioned_sub_id,
            p_associate_sub_id,
            p_status,
            SYSDATE
        );
  /* commit changes*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'INSERT_MISIMD_SUPPLEMENT_PAYLOAD'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;

        IF
            l_commit = 'Y'
        THEN
            COMMIT;
        END IF;
    END ins_supplement_payload;

    PROCEDURE prepare_notify_payload (
        p_header_id   IN NUMBER,
        resultout     OUT NOCOPY VARCHAR2
    ) IS

        l_header_id                oe_order_headers_all.header_id%TYPE;
        l_order_number             oe_order_headers_all.order_number%TYPE;
        l_ordered_date             oe_order_headers_all.ordered_date%TYPE;
        l_party_name               hz_parties.party_name%TYPE;
        l_buyer_email_id           oe_order_price_attribs.pricing_attribute90%TYPE;
        l_service_admin_email_id   oe_order_price_attribs.pricing_attribute91%TYPE;
        l_line_id                  oe_order_lines_all.line_id%TYPE;
        l_inventory_item_id        oe_order_lines_all.inventory_item_id%TYPE;
        l_item_description         mtl_system_items_b.description%TYPE;
        l_ordered_item             oe_order_lines_all.ordered_item%TYPE;
        l_instance_id              csi_item_instances.instance_id%TYPE;
        l_service_start_date       oe_order_lines_all.service_start_date%TYPE;
        l_future_installments      oe_order_headers_all.attribute18%TYPE;
        l_invoicing_frequency      oe_order_headers_all.attribute19%TYPE;
        l_num_of_users             oe_order_price_attribs.pricing_attribute3%TYPE;
        l_subscription_id          oe_order_price_attribs.pricing_attribute92%TYPE;
        l_paramlist_t              wf_parameter_list_t := NULL;
        l_end_date                 DATE;
        l_order_str                XMLTYPE;
        l_order_data               CLOB;
        l_cursor_flag              VARCHAR2(1);
        l_store_flag               VARCHAR2(1);
        l_combined_grp             VARCHAR2(1);
        l_combined_grp_oper        VARCHAR2(1);
        l_oae_flag                 VARCHAR2(1);
  /*120.51*/
        l_source_name              VARCHAR2(40);
  /* CPQGRP Change*/
        l_onboarding_count         NUMBER;
  /* CPQGRP Change*/
        l_trx_id                   NUMBER;
  /* CPQGRP Change*/
        l_count                    NUMBER;
  /* CPQGRP Change*/
        l_line_ids                 VARCHAR2(32767);
  /* CPQGRP Change*/
  /* SUP PAYLOAD*/
        l_provisioned_sub_id       NUMBER;
        l_commit                   VARCHAR2(1) := 'Y';
        CURSOR c1 IS SELECT DISTINCT
            oep.pricing_attribute92 AS subscription_id
                     FROM
            oe_order_price_attribs oep
                     WHERE
            pricing_attribute92 IS NOT NULL
            AND   header_id = p_header_id
            AND   EXISTS (
                SELECT
                    1
                FROM
                    wf_item_activity_statuses s,
                    wf_process_activities p
                WHERE
                    s.process_activity = p.instance_id
                    AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                    AND   s.item_type = 'OEOL'
                    AND   s.item_key = TO_CHAR(oep.line_id)
            )
            AND   NOT EXISTS (
                SELECT
                    1
                FROM
                    oe_order_lines_all
                WHERE
                    line_id = oep.line_id
                    AND   flow_status_code IN (
                        'CLOSED',
                        'CANCELLED'
                    )
            );

        CURSOR c2 IS SELECT
            misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') AS service_group
                     FROM
            oe_order_lines_all ol
                     WHERE
            ol.header_id = p_header_id
            AND   ol.item_type_code = 'SERVICE';

        CURSOR c3 IS SELECT DISTINCT
            oep.pricing_attribute94 AS line_operation_type
                     FROM
            oe_order_price_attribs oep
                     WHERE
            oep.pricing_attribute94 IS NOT NULL
            AND   oep.header_id = p_header_id
            AND   EXISTS (
                SELECT
                    1
                FROM
                    wf_item_activity_statuses s,
                    wf_process_activities p
                WHERE
                    s.process_activity = p.instance_id
                    AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                    AND   s.item_type = 'OEOL'
                    AND   s.item_key = TO_CHAR(oep.line_id)
            )
            AND   NOT EXISTS (
                SELECT
                    1
                FROM
                    oe_order_lines_all
                WHERE
                    line_id = oep.line_id
                    AND   flow_status_code IN (
                        'CLOSED',
                        'CANCELLED'
                    )
            );

        CURSOR c4 IS
    /* select distinct oep.pricing_attribute92 as subscription_id*/ SELECT
            oep.pricing_attribute92 subscription_id,
            LISTAGG(oep.line_id,
            ',') WITHIN GROUP(
            ORDER BY
                oep.pricing_attribute92,
                oep.line_id
            ) line_ids
                     FROM
            oe_order_price_attribs oep
                     WHERE
            pricing_attribute92 IS NOT NULL
            AND   oep.pricing_attribute94 NOT IN (
                'ONBOARDING',
                'PILOT_ONBOARDING'
            )
            AND   header_id = p_header_id
            AND   EXISTS (
                SELECT
                    1
                FROM
                    wf_item_activity_statuses s,
                    wf_process_activities p
                WHERE
                    s.process_activity = p.instance_id
                    AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                    AND   s.item_type = 'OEOL'
                    AND   s.item_key = TO_CHAR(oep.line_id)
            )
            AND   NOT EXISTS (
                SELECT
                    1
                FROM
                    oe_order_lines_all
                WHERE
                    line_id = oep.line_id
                    AND   flow_status_code IN (
                        'CLOSED',
                        'CANCELLED'
                    )
            )
                     GROUP BY
            oep.pricing_attribute92,
            DECODE(oep.pricing_attribute94,'RAMPED_ONBOARDING','RAMPED','RAMPED_UPDATE','RAMPED','RAMPED_EXTENSION','RAMPED',oep.pricing_attribute94);
  /* to get all onboarding lines*/

        CURSOR csr_onboarding_planning_lines IS SELECT
            ol.line_id parent_item,
            pol.line_id planning_item_line_id,
            upper(mri.attr_char3) attr_char3,
            oep.pricing_attribute92
                                                FROM
            oe_order_price_attribs oep,
            oe_order_lines_all ol,
            ego_mtl_sy_items_ext_vl emi,
            oe_order_lines_all pol,
            mtl_related_items mri
                                                WHERE
            ol.header_id = p_header_id
            AND   ol.header_id = oep.header_id
            AND   ol.header_id = pol.header_id
            AND   ol.line_id = oep.line_id
            AND   oep.pricing_attribute94 IN (
                'ONBOARDING',
                'PILOT_ONBOARDING'
            )
            AND   emi.attr_group_id = (
                SELECT
                    attr_group_id
                FROM
                    ego_attr_groups_v
                WHERE
                    attr_group_name = 'MISEGO_UNIFIED_OFF_TYPE'
            )
            AND   ol.inventory_item_id = emi.inventory_item_id
            AND   emi.organization_id = 14354
            AND   emi.language = 'US'
            AND   upper(emi.c_ext_attr1) = 'UNIFIED PROVISION-ABLE'
            AND   mri.organization_id = 14354
            AND   mri.reciprocal_flag = 'N'
            AND   mri.inventory_item_id = ol.inventory_item_id
            AND   pol.inventory_item_id = mri.related_item_id
            AND   ( mri.attr_char3 ) IS NOT NULL
            AND   mri.relationship_type_id IN (
                SELECT
                    lookup_code
                FROM
                    fnd_lookup_values
                WHERE
                    language = userenv('LANG')
                    AND   lookup_type = 'MTL_RELATIONSHIP_TYPES'
                    AND   upper(meaning) LIKE 'UNIFIED%'
            )
            AND   EXISTS (
                SELECT
                    1
                FROM
                    wf_item_activity_statuses s,
                    wf_process_activities p
                WHERE
                    s.process_activity = p.instance_id
                    AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                    AND   s.item_type = 'OEOL'
                    AND   s.item_key = TO_CHAR(oep.line_id)
            )
            AND   NOT EXISTS (
                SELECT
                    1
                FROM
                    oe_order_lines_all
                WHERE
                    line_id = oep.line_id
                    AND   flow_status_code IN (
                        'CLOSED',
                        'CANCELLED'
                    )
            );

        l_validate_order           VARCHAR2(1000) := 'Y';
    BEGIN
  /*Necessary since BPEL can have other NLS Lang param(eg. BRITISH) */
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
        init(p_errror_flag => p_error_flag);
        g_intf_run_key := p_header_id;
        insert_log(g_audit_message => 'Payload for Provisioning Initialized',g_audit_level => 1,g_module => 'Prepare_Notify_Payload',g_context_name2 => NULL,g_context_id
=> p_header_id,g_audit_attachment => NULL);
  /*CPQ GRP Code CHANGE S.  <<<<<<add a lookup for cpq code change..>>>>*/
  /*IF p_header_id IS NOT NULL THEN*/

        SELECT
            DECODE(COUNT(1),0,'Y','N')
        INTO
            l_validate_order
        FROM
            misont_order_line_attribs_ext mole
        WHERE
            mole.header_id = p_header_id
            AND   (
                instr(mole.additional_column17,'-') > 0
                OR    instr(mole.additional_column17,'B') > 0
            );

        IF
            l_validate_order = 'N'
        THEN
            resultout := 'PROV_PAYLOAD_PREP_ERROR: ASSOCIATE SUB ID ISSUE';
            UPDATE oe_order_price_attribs
                SET
                    pricing_attribute93 = 'PROV_PAYLOAD_PREP_ERROR: ASSOCIATE SUB ID ISSUE'
            WHERE
                header_id = p_header_id
                AND   pricing_attribute93 = 'AWAIT PROVISIONING';
    /*commit changes*/

            BEGIN
                SELECT
                    lookup_value
                INTO
                    l_commit
                FROM
                    oss_intf_user.misimd_intf_lookup
                WHERE
                    application = 'MISIMD_TAS_CLOUD_WF'
                    AND   component = 'MISIMD_COMMIT_TAS_GRP'
                    AND   upper(lookup_code) = 'UPDATE_OE_ORDER_PRICE_ATTRIBS'
                    AND   enabled = 'Y';

            EXCEPTION
                WHEN OTHERS THEN
                    l_commit := 'Y';
            END;

            IF
                l_commit = 'Y'
            THEN
                COMMIT;
            END IF;
        ELSIF l_validate_order = 'Y' THEN
            SELECT
                upper(oes.name)
            INTO
                l_source_name
            FROM
                oe_order_sources oes,
                oe_order_headers_all oh
            WHERE
                oh.order_source_id = oes.order_source_id
                AND   oh.header_id = p_header_id;
    /* Onboarding count irrespective of CPQ/NON-CPQ/WEBQUOTE*/
    /* needed for Supplement Payload*/
    /* currently sending Supplement Payload only for onboarding*/

            SELECT
                COUNT(1)
            INTO
                l_onboarding_count
            FROM
                oe_order_price_attribs oep
            WHERE
                oep.pricing_attribute94 IN (
                    'ONBOARDING',
                    'PILOT_ONBOARDING'
                )
                AND   oep.header_id = p_header_id
                AND   EXISTS (
                    SELECT
                        1
                    FROM
                        wf_item_activity_statuses s,
                        wf_process_activities p
                    WHERE
                        s.process_activity = p.instance_id
                        AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                        AND   s.item_type = 'OEOL'
                        AND   s.item_key = TO_CHAR(oep.line_id)
                )
                AND   NOT EXISTS (
                    SELECT
                        1
                    FROM
                        oe_order_lines_all
                    WHERE
                        line_id = oep.line_id
                        AND   flow_status_code IN (
                            'CLOSED',
                            'CANCELLED'
                        )
                );

            BEGIN
      /*Bug 24825337 start,ravelard,populating l_oae_flag variable*/
                SELECT
                    misont_cloud_pub2.is_oae(p_header_id)
                INTO
                    l_oae_flag
                FROM
                    dual;

            EXCEPTION
                WHEN OTHERS THEN
                    l_oae_flag := 'N';
      /*Bug 24825337 end,ravelard,populating l_oae_flag variable*/
            END;

            IF
                l_source_name IN (
                    'CPQ',
                    'IEIGHT'
                ) AND l_oae_flag <> 'Y'
            THEN
      /* Added for bug# 22959449 to handle the OAE flow*/
                l_count := 1;
                IF
                    l_onboarding_count > 0
                THEN
                    tas_cpq_grp_process(p_header_id,'',l_trx_id);
        /* Populating the temp table for onboarding lines.*/
        /*Dbms_Output.put_line('inside CPQ Flow: Onboarding after tas cpq grp');*/
                    insert_log(g_audit_message => 'CPQ Grouping Call Successful',g_audit_level => 3,g_module => 'Prepare_Notify_Payload',g_context_name2 => NULL,g_context_id => p_header_id
,g_audit_attachment => NULL);
        /* Cursor for getting the unique header id and service seq # from the temp table for non errored seq's.*/
        /* l_trx_id should get populated from the previous call.*/

                    FOR csr_temptbl IN (
                        SELECT
                            header_id,
                            group_sequence_id
                        FROM
                            misimd_om_tas_groups_tbl
                        WHERE
                            group_sequence_id NOT IN (
                                SELECT
                                    group_sequence_id
                                FROM
                                    misimd_om_tas_groups_tbl
                                WHERE
                                    status = 'ERROR'
                                    AND   header_id = p_header_id
                                    AND   transaction_id = l_trx_id
                            )
                            AND   header_id = p_header_id
                            AND   transaction_id = l_trx_id
                        GROUP BY
                            group_sequence_id,
                            header_id
                    ) LOOP
                        l_line_ids := '';
                        insert_log(g_audit_message => 'In CSR_temptbl',g_audit_level => 3,g_module => 'Prepare_Notify_Payload',g_context_name2 => NULL,g_context_id => p_header_id,g_audit_attachment
=> NULL);
          /* Looping used for just concatinating the required line nos.*/

                        FOR csr IN (
                            SELECT
                                group_sequence_id,
                                line_id,
                                subscription_id
                            FROM
                                misimd_om_tas_groups_tbl
                            WHERE
                                group_sequence_id = csr_temptbl.group_sequence_id
                                AND   header_id = csr_temptbl.header_id
                                AND   transaction_id = l_trx_id
                            ORDER BY
                                line_id
                        ) LOOP
                            insert_log(g_audit_message => 'In CSR Loop - Line ID-'
                            || csr.line_id,g_audit_level => 1,g_module => 'Prepare_Notify_Payload',g_context_name2 => NULL,g_context_id => p_header_id,g_audit_attachment => NULL);

                            IF
                                l_count = 1
                            THEN
                                l_line_ids := csr.line_id;
                            ELSE
                                IF
                                    csr.line_id IS NOT NULL
                                THEN
                                    l_line_ids := l_line_ids
                                    || ','
                                    || csr.line_id;
                                END IF;
                            END IF;

                            l_count := l_count + 1;
                        END LOOP;
          /*     Dbms_Output.put_line('inside CPQ Flow: Before calling BE' || l_line_ids);*/

                        l_order_str := misimd_tas_cloud_wf.get_bus_event_xml(p_header_id,NULL,'TAS',l_line_ids);

          /*--    Dbms_Output.put_line('inside CPQ Flow: Called BE xml' || l_order_str);*/
          /*    Dbms_Output.put_line('inside CPQ Flow: Called BE xml 2');*/
                        SELECT
                            XMLROOT(l_order_str,
                            VERSION '1.0',STANDALONE YES) AS xmlroot
                        INTO
                            l_order_str
                        FROM
                            dual;

                        l_order_data := l_order_str.getclobval ();
                        wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);

                        g_audit_message := 'Business Event Raised';
                        insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,l_order_data);
                    END LOOP;

                END IF;
      /**/
      /* PROCESS NON ONBOARDING SUB ID'S/LINES.*/

                FOR l_sub_c4 IN c4 LOOP
                    l_line_ids := '';
        /*       Dbms_Output.put_line('inside CPQ Flow: Non-Onboarding Flow');*/
                    l_subscription_id := l_sub_c4.subscription_id;
                    l_line_ids := l_sub_c4.line_ids;
                    l_order_str := misimd_tas_cloud_wf.get_bus_event_xml(p_header_id,l_subscription_id,'TAS',l_line_ids);
        /*          Dbms_Output.put_line('inside CPQ Flow: Non-Onboarding Flow: BE Call');*/
                    SELECT
                        XMLROOT(l_order_str,
                        VERSION '1.0" encoding="UTF-8',STANDALONE YES) AS xmlroot
                    INTO
                        l_order_str
                    FROM
                        dual;

                    l_order_data := l_order_str.getclobval ();
                    wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);

                    g_audit_message := 'Business Event Raise';
                    insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,l_order_data);
                END LOOP;
      /*CPQ GRP Code CHANGE E.*/
      /* Non CPQ Changes*/

            ELSE
      /*    Dbms_Output.put_line('Else GSI Flow');*/
                g_context_id := NULL;
                resultout := 'SUCCESS';
                l_cursor_flag := 'N';
                l_combined_grp := 'N';
                l_combined_grp_oper := 'Y';
                g_module := 'raise_Order_Event';
                g_context_name2 := 'Raise Business Event';
                g_context_id := p_header_id;
                SELECT
                    pricing_attribute98
                INTO
                    l_store_flag
                FROM
                    oe_order_price_attribs
                WHERE
                    header_id = p_header_id
                    AND   ROWNUM = 1;

                SELECT
                    DECODE(COUNT(1),0,'N','Y')
                INTO
                    l_combined_grp
                FROM
                    oe_order_lines_all ol
                    JOIN oe_order_price_attribs oep ON ol.line_id = oep.line_id
                                                       AND ol.header_id = p_header_id
                                                       AND oep.pricing_attribute94 = 'ONBOARDING'
                                                       AND misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                        SELECT
                            lookup_value
                        FROM
                            misimd_intf_lookup
                        WHERE
                            lookup_code = 'PAYLOAD_GROUP'
                            AND   application = 'GSI-TAS CLOUD BRIDGE'
                            AND   enabled = 'Y'
                    )
                                                       AND oep.header_id = p_header_id
                                                       AND ol.flow_status_code NOT IN (
                        'CLOSED',
                        'CANCELLED'
                    )
                    JOIN wf_item_activity_statuses s ON s.item_key = TO_CHAR(ol.line_id)
                                                        AND s.item_type = 'OEOL'
                    JOIN wf_process_activities p ON s.process_activity = p.instance_id
                                                    AND p.activity_name = 'CLOUD_TAS_INTERFACE';
      /*120.4 Fix*/

                SELECT
                    misont_cloud_pub2.is_oae(p_header_id)
                INTO
                    l_oae_flag
                FROM
                    dual;
      /* Adding l_combined_grp condition as the Metered order will get fired more than once,without this condition*/

                IF
                    ( ( l_store_flag <> 'Y' OR l_store_flag IS NULL ) AND l_combined_grp = 'N' AND l_oae_flag <> 'Y' )
                THEN
                    FOR l_sub_c1 IN c1 LOOP
                        l_subscription_id := l_sub_c1.subscription_id;
                        SELECT
                            DECODE(COUNT(1),0,'N','Y')
                        INTO
                            l_combined_grp_oper
                        FROM
                            oe_order_lines_all ol
                            JOIN oe_order_price_attribs oep ON ol.line_id = oep.line_id
                                                               AND ol.header_id = p_header_id
                                                               AND oep.pricing_attribute94 = 'ONBOARDING'
                                                               AND misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                                SELECT
                                    lookup_value
                                FROM
                                    misimd_intf_lookup
                                WHERE
                                    lookup_code = 'PAYLOAD_GROUP'
                                    AND   application = 'GSI-TAS CLOUD BRIDGE'
                                    AND   enabled = 'Y'
                            )
                                                               AND oep.pricing_attribute92 = l_subscription_id;

                        IF
                            ( l_combined_grp_oper = 'N' )
                        THEN
                            l_order_str := misimd_tas_cloud_wf.get_bus_event_xml(p_header_id,l_subscription_id,'TAS');
                            SELECT
                                XMLROOT(l_order_str,
                                VERSION '1.0" encoding="UTF-8',STANDALONE YES) AS xmlroot
                            INTO
                                l_order_str
                            FROM
                                dual;

                            l_order_data := l_order_str.getclobval ();
                            wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);

                        END IF;

                        g_audit_message := 'Business Event Raise';
                        insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,l_order_data);
                    END LOOP;
                END IF;

                IF
                    ( l_combined_grp = 'Y' OR l_oae_flag = 'Y' )
                THEN
        /*120.51*/
                    l_order_str := misimd_tas_cloud_wf.get_bus_event_xml(p_header_id,NULL,'TAS');
                    SELECT
                        XMLROOT(l_order_str,
                        VERSION '1.0',STANDALONE YES) AS xmlroot
                    INTO
                        l_order_str
                    FROM
                        dual;

                    l_order_data := l_order_str.getclobval ();
                    wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);

                    g_audit_message := 'Business Event Raise';
                    insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,l_order_data);
                END IF;

            END IF;
    /* CPQ Check IF closed*/
    /* Supplement Payload*/
    /*          Onboarding Flow:*/

            IF
                l_onboarding_count > 0
            THEN
                FOR c_plan IN csr_onboarding_planning_lines LOOP
        /*--*/
                    l_line_ids := c_plan.planning_item_line_id;
                    ins_supplement_payload(p_header_id,l_line_ids,l_provisioned_sub_id,c_plan.pricing_attribute92,'SENT',NULL);
                    l_order_str := misimd_tas_cloud_wf.get_bus_event_xml(p_header_id,NULL,'SUP_PAY',l_line_ids);
                    SELECT
                        XMLROOT(l_order_str,
                        VERSION '1.0" encoding="UTF-8',STANDALONE YES) AS xmlroot
                    INTO
                        l_order_str
                    FROM
                        dual;

                    l_order_data := l_order_str.getclobval ();
                    wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);

                    g_audit_message := 'Business Event Raise';
                    insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,l_order_data);
        /*--*/
                END LOOP;
            END IF;

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            g_context_name2 := 'Raise Business Event Exception';
            p_error_code := sqlcode;
            p_error_message := sqlerrm;
            insert_log(g_audit_message,1,g_module,g_context_name2,NULL,l_order_data);
            insert_error(p_error_code,p_error_message,g_module,g_context_name2,g_context_id,errbuf);
            RAISE;
    END prepare_notify_payload;

    PROCEDURE contracts_migration (
        p_chr_id          IN NUMBER,
        p_service_group   IN VARCHAR2,
        resultout         OUT NOCOPY VARCHAR2
    ) IS
        l_paramlist_t   wf_parameter_list_t := NULL;
        l_order_str     XMLTYPE;
        l_order_data    CLOB;
    BEGIN
  /*   insert into oss_intf_user.MISIMD_SVDEBUG ( msg ) values ( 'order header id ' ||p_header_id) ;*/
        resultout := 'SUCCESS';
        SELECT
            XMLELEMENT(
                "OrderHeader",
                XMLATTRIBUTES(
                    okh.id AS "HEADERID",okh.org_id AS "ORGANIZATIONID", (
                        SELECT
                            round(SUM(TO_CHAR(SYSDATE,'DDDSSSSSSSSS') + dbms_random.value(1000000000,9999999999) ) )
                        FROM
                            dual
                    ) AS "ORDERNUMBER",sys_extract_utc(to_timestamp(TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "ORDERDATE",cust_party.party_name AS "CUSTNAME"
,cust_acct.account_number AS "CUSTACCTNUMBER",cust_party.party_id AS "PARTYID",'ONBOARDING' AS "OPERATIONTYPE", (
                        SELECT
                            name
                        FROM
                            csi_item_instances cii,
                            csi_systems_tl cst,
                            okc_k_items oki
                        WHERE
                            cii.instance_id = to_number(oki.object1_id1)
                            AND   oki.jtot_object1_code = 'OKX_CUSTPROD'
                            AND   cii.system_id = cst.system_id
                            AND   cst.language = 'US'
                            AND   okh.id = oki.dnz_chr_id
                            AND   ROWNUM = 1
                    ) AS "CSI"
                ),
                XMLCOLATTVAL('Y' AS "MIGRATE_SUBSCRIPTIONS"),
                (
                    SELECT
                        XMLELEMENT(
                            "OrderLines",
                            XMLAGG(XMLELEMENT(
                                "OrderLine",
                                XMLATTRIBUTES(
                                    okl.id AS "LINEID",'dummy' AS "LINE_OPERATION_TYPE",11 AS "LICENSE_LINE_ID",'dummy' AS "LICENSE_ITEM_ID",msi.segment1 AS "ORDEREDITEM",'dummy' AS "FULFILLMENT_SET"
,msi.inventory_item_id AS "ITEMID",DECODE(oki.jtot_object1_code,'OKX_CUSTPROD','LICENSE','OKX_SERVICE','SERVICE',oki.jtot_object1_code) AS "LINETYPE",'SaaS'
AS "CLOUDORDERTYPE",'oal_erp_initiatives_supp_sales_grp@oracle.com' AS "BUYEREMAILID",'oal_erp_initiatives_supp_sales_grp@oracle.com' AS "SERVICEADMINEMAILID"
,'N' AS "OVERAGEOPTED",'US001' AS "DATACENTER",utl_i18n.escape_reference(msi.description) AS "ITEMDESC",sys_extract_utc(to_timestamp(TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'
),'YYYY/MM/DD HH24:MI:SS') ) AS "STARTDATE",sys_extract_utc(to_timestamp(TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "LINE_END_DATE"
                                ),
                                (
                                    SELECT
                                        XMLAGG(XMLELEMENT(
                                            "LicenseItem",
                                            XMLATTRIBUTES(
                                                msii.segment1 AS "LICENSE_ITEM",'STANDARD' AS "LICENSE_LINE_TYPE", (substr(mct.description, (instr(mct.description,'-') + 1) )
                                                || '-'
                                                || okll.attribute5) AS "FULFILLMENT_SET"
                                            ),
                                            XMLCOLATTVAL(XMLCOLATTVAL('USERCOUNT' AS name,
                                            1 AS value) AS properties)
                                        ) )
                                    FROM
                                        okc_k_items okii,
                                        okc_k_lines_b okll,
                                        mtl_system_items_b msii
                                    WHERE
                                        msii.organization_id = 14354
                                        AND   msii.inventory_item_id = (
                                            SELECT
                                                k.inventory_item_id
                                            FROM
                                                csi_item_instances k
                                            WHERE
                                                to_number(okii.object1_id1) = k.instance_id
                                        )
                                        AND   okii.cle_id = okll.id
                                        AND   okll.cle_id = okl.id
                                        AND   okii.jtot_object1_code = 'OKX_CUSTPROD'
                                ),
                                (
                                    SELECT
                                        XMLAGG(XMLELEMENT(
                                            "LicenseItem",
                                            XMLATTRIBUTES(
                                                mtsiii.segment1 AS "LICENSE_ITEM",'INCLUDED' AS "LICENSE_LINE_TYPE",'DUMMY' AS "FULFILLMENT_SET"
                                            ),
                                            XMLCOLATTVAL(XMLCOLATTVAL('USERCOUNT' AS name,
                                            1 AS value) AS properties)
                                        ) )
                                    FROM
                                        bom_inventory_components_v bom_component,
                                        bom_bill_of_materials_v bom,
                                        mtl_system_items_b mtsiii,
                                        okc_k_items okiii,
                                        okc_k_lines_b oklll
                                    WHERE
                                        bom.bill_sequence_id = bom_component.bill_sequence_id
                                        AND   bom.assembly_item_id = (
                                            SELECT
                                                k.inventory_item_id
                                            FROM
                                                csi_item_instances k
                                            WHERE
                                                to_number(okiii.object1_id1) = k.instance_id
                                        )
                                        AND   mtsiii.inventory_item_id = bom_component.component_item_id
                                        AND   mtsiii.organization_id = bom.organization_id
                                        AND   mtsiii.organization_id = 14354
                                        AND   okiii.jtot_object1_code = 'OKX_CUSTPROD'
                                        AND   okiii.cle_id = oklll.id
                                        AND   oklll.cle_id = okl.id
                                ),
                                XMLCOLATTVAL(XMLCOLATTVAL('CONTRACT_SERVICE_LINE_ID' AS name,
                                okl.id AS value) AS properties,
                                XMLCOLATTVAL('CONTRACT_NUMBER' AS name,
                                okh.contract_number AS value) AS properties)
                            ) )
                        )
                    FROM
                        okc_k_lines_b okl,
                        okc_k_items oki,
                        mtl_system_items_b msi,
                        mtl_item_categories mic,
                        mtl_categories_b mc,
                        mtl_category_sets mcs,
                        mtl_categories_tl mct
                    WHERE
                        oki.dnz_chr_id = okl.dnz_chr_id
                        AND   okl.dnz_chr_id = okh.id
                        AND   okl.cle_id IS NULL
                        AND   oki.jtot_object1_code = 'OKX_SERVICE'
                        AND   oki.cle_id = okl.id
                        AND   msi.inventory_item_id = oki.object1_id1
                        AND   msi.organization_id = 14354
                        AND   msi.organization_id = mic.organization_id
                        AND   msi.inventory_item_id = mic.inventory_item_id
                        AND   mic.category_id = mc.category_id
                        AND   mic.category_set_id = mcs.category_set_id
                        AND   mcs.category_set_name = 'PROVISIONING_GROUP'
                        AND   mic.category_id = mct.category_id
                        AND   mct.language = 'US'
                )
            ) AS "Order_List"
        INTO
            l_order_str
        FROM
            okc_k_headers_all_b okh,
            hz_cust_accounts cust_acct,
            hz_parties cust_party,
            okc_k_party_roles_b okp
        WHERE
            okh.id = p_chr_id
            AND   okp.dnz_chr_id = okh.id
            AND   okp.rle_code = 'CUSTOMER'
            AND   okp.jtot_object1_code = 'OKX_PARTY'
            AND   okp.cle_id IS NULL
            AND   cust_party.party_id = okp.object1_id1
            AND   cust_acct.party_id = cust_party.party_id
            AND   ROWNUM = 1;

        SELECT
            XMLROOT(l_order_str,
            VERSION '1.0',STANDALONE YES) AS xmlroot
        INTO
            l_order_str
        FROM
            dual;

        l_order_data := l_order_str.getclobval ();
        wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);
  /*    insert into oss_intf_user.MISIMD_SVDEBUG ( msg ) values ('END : After raising BE') ;*/

    EXCEPTION
        WHEN OTHERS THEN
            oe_debug_pub.add('Exception in Prepare Notify Payload');
            resultout := 'Exception in MISIMD_TAS_CLOUD_WF.prepare_notify_payload: '
            || sqlcode
            || ' - '
            || sqlerrm;
            RAISE;
    END contracts_migration;

    PROCEDURE migrate_subscriptions (
        p_chr_id    IN NUMBER,
        resultout   OUT NOCOPY VARCHAR2
    ) IS
        l_paramlist_t   wf_parameter_list_t := NULL;
        l_order_str     XMLTYPE;
        l_order_data    CLOB;
        l_op_type       VARCHAR2(30);
    BEGIN
        resultout := 'SUCCESS';
  /*- l_subsgroups := '';*/
        BEGIN
            SELECT
                cip.pricing_attribute94
            INTO
                l_op_type
            FROM
                csi_i_pricing_attribs cip,
                okc_k_headers_all_b okh,
                okc_k_lines_b okl,
                csi_systems_tl cst,
                csi_item_instances cii,
                okc_k_items oki
            WHERE
                okh.id = okl.dnz_chr_id
                AND   okl.id = oki.cle_id
                AND   oki.object1_id1 = cii.instance_id
                AND   cii.instance_id = cip.instance_id
                AND   cii.system_id = cst.system_id
                AND   cst.language = 'US'
                AND   okh.id = p_chr_id
                AND   cip.pricing_attribute94 IS NOT NULL
                AND   cip.pricing_attribute94 = 'MIGRATION'
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
                l_op_type := 'MIGRATION';
        END;

        IF
            upper(l_op_type) <> 'MIGRATION'
        THEN
            SELECT
                XMLELEMENT(
                    "OrderHeader",
                    XMLATTRIBUTES(
                        oh.header_id AS "HEADERID",oh.org_id AS "ORGANIZATIONID",oh.order_number
                        || okh.id AS "ORDERNUMBER",sys_extract_utc(to_timestamp(TO_CHAR(oh.ordered_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "ORDERDATE",cust_party
.party_name AS "CUSTNAME",cust_acct.account_number AS "CUSTACCTNUMBER",cust_party.party_id AS "PARTYID",'ONBOARDING' AS "OPERATIONTYPE", (
                            SELECT
                                name
                            FROM
                                csi_item_instances cii,
                                csi_systems_tl cst,
                                okc_k_items oki
                            WHERE
                                cii.instance_id = to_number(oki.object1_id1)
                                AND   oki.jtot_object1_code = 'OKX_CUSTPROD'
                                AND   cii.system_id = cst.system_id
                                AND   cst.language = 'US'
                                AND   okh.id = oki.dnz_chr_id
                                AND   ROWNUM = 1
                        ) AS "CSI",NULL AS "COTERMSUBSID"
                    ),
                    XMLCOLATTVAL('Y' AS "MIGRATE_SUBSCRIPTIONS"),
                    XMLCOLATTVAL('oal_erp_initiatives_supp_sales_grp@oracle.com' AS "SALES_REPS"),
                    XMLCOLATTVAL(cust_party.party_id AS "TCA_PARTY_ID"),
                    XMLCOLATTVAL('oal_erp_initiatives_supp_sales_grp@oracle.com' AS "BUYER_SSO_USERNAME"),
                    XMLCOLATTVAL(nvl(cust_party.organization_name_phonetic,cust_party.party_name) AS "CUSTOMER_ENGLISH_NAME"),
                    XMLCOLATTVAL(NULL AS "SALES_CHANNEL"),
                    XMLCOLATTVAL(NULL AS "CUSTOMER_TYPE"),
                    XMLCOLATTVAL(cust_party.party_name AS "CUSTOMER_PRIMARY_NAME"),
                    XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_ADDRESS') AS "CUSTOMER_ADDRESS"),
                    XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_CITY') AS "CUSTOMER_CITY"),
                    XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_STATE') AS "CUSTOMER_STATE"),
                    XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_ZIP') AS "CUSTOMER_ZIP"),
                    XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_COUNTRY') AS "CUSTOMER_COUNTRY_CODE"),
                    (
                        SELECT
                            XMLELEMENT(
                                "OrderLines",
                                XMLAGG(XMLELEMENT(
                                    "OrderLine",
                                    XMLATTRIBUTES(
                                        ol.line_id AS "LINEID",'MIGRATE' AS "LINE_OPERATION_TYPE",ol.service_reference_line_id AS "LICENSE_LINE_ID",oll.inventory_item_id AS "LICENSE_ITEM_ID",ol.orig_sys_line_ref
AS "ORIGSYSLINEREF",ol.ordered_item AS "ORDEREDITEM",oes.set_name AS "FULFILLMENT_SET",ol.inventory_item_id AS "ITEMID",ol.item_type_code AS "LINETYPE",misont_cloud_pub2
.get_cloud_item_type(ol.ordered_item) AS "CLOUDORDERTYPE",op.pricing_attribute90 AS "BUYEREMAILID",op.pricing_attribute91 AS "SERVICEADMINEMAILID",op.pricing_attribute92
AS "SUBSCRIPTIONID",op.pricing_attribute96 AS "SYSTEMINTEGRATOREMAILID",'N' AS "STOREORDER",nvl(op.pricing_attribute89,'N') AS "OVERAGEOPTED",op.pricing_attribute99
AS "DATACENTER",utl_i18n.escape_reference(msi.description) AS "ITEMDESC",sys_extract_utc(to_timestamp(TO_CHAR(ol.service_start_date,'YYYY/MM/DD HH24:MI:SS'
),'YYYY/MM/DD HH24:MI:SS') ) AS "STARTDATE",sys_extract_utc(to_timestamp(TO_CHAR(ol.service_end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "LINE_END_DATE"
                                    ),
                                    (
                                        SELECT
                                            XMLAGG(XMLELEMENT(
                                                "LicenseItem",
                                                XMLATTRIBUTES(
                                                    oll.ordered_item AS "LICENSE_ITEM",oll.item_type_code AS "LICENSE_LINE_TYPE",oes.set_name AS "FULFILLMENT_SET"
                                                ),
                                                XMLCOLATTVAL(
                                                    CASE
                                                        WHEN 'EXTENSION' <> 'CHANGE OF SERVICE' THEN XMLCOLATTVAL(mc.segment1 AS name,
                                                        op.pricing_attribute3 AS value)
                                                    END
                                                AS properties,
                                                XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                                nvl(mc.attribute13,1) AS value) AS properties,
                                                XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                                substr(msi.description,1,100) AS value) AS properties)
                                            ) )
                                        FROM
                                            oe_order_lines_all oll,
                                            oe_order_price_attribs opp,
                                            oe_sets oes,
                                            oe_line_sets sln,
                                            mtl_categories mc,
                                            mtl_item_categories mic,
                                            mtl_system_items_b msi
                                        WHERE
                                            oll.line_id = ol.service_reference_line_id
                                            AND   oes.set_id = sln.set_id
                                            AND   oes.set_type = 'FULFILLMENT_SET'
                                            AND   sln.line_id = oll.line_id
                                            AND   oll.header_id = oh.header_id
                                            AND   opp.line_id = oll.line_id
                                            AND   mc.category_id = mic.category_id
                                            AND   mic.category_set_id = 1100026004
                                            AND   mic.organization_id = 14354
                                            AND   mic.inventory_item_id = oll.inventory_item_id
                                            AND   msi.inventory_item_id = oll.inventory_item_id
                                            AND   msi.organization_id = 14354
                                    ),
                                    (
                                        SELECT
                                            XMLAGG(XMLELEMENT(
                                                "LicenseItem",
                                                XMLATTRIBUTES(
                                                    mts.segment1 AS "LICENSE_ITEM",'INCLUDED' AS "LICENSE_LINE_TYPE",'DUMMY' AS "FULFILLMENT_SET"
                                                ),
                                                XMLCOLATTVAL(
                                                    CASE
                                                        WHEN(misont_cloud_pub2.get_hdr_cloud_operation_type(oll.header_id) <> 'CHANGE OF SERVICE') THEN XMLCOLATTVAL(mc.segment1 AS name,
                                                        misont_cloud_pub2.get_component_qty(oll.line_id,bom_component.component_item_id) AS value)
                                                    END
                                                AS properties,
                                                XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                                nvl(mc.attribute13,1) AS value) AS properties,
                                                XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                                substr(mts.description,1,100) AS value) AS properties)
                                            ) )
                                        FROM
                                            bom_inventory_components_v bom_component,
                                            bom_bill_of_materials_v bom,
                                            mtl_system_items_b mts,
                                            mtl_categories mc,
                                            mtl_item_categories mic
                                        WHERE
                                            bom.bill_sequence_id = bom_component.bill_sequence_id
                                            AND   bom.assembly_item_id = oll.inventory_item_id
                                            AND   mts.inventory_item_id = bom_component.component_item_id
                                            AND   mts.organization_id = bom.organization_id
                                            AND   mts.organization_id = 14354
                                            AND   mc.category_id = mic.category_id
                                            AND   mic.category_set_id = 1100026004
                                            AND   mic.organization_id = 14354
                                            AND   nvl(bom_component.disable_date,SYSDATE + 1) > SYSDATE
                                            AND   mic.inventory_item_id = mts.inventory_item_id
                                    ),
                                    XMLCOLATTVAL(
                                        CASE
                                            WHEN(
                                                misont_cloud_pub2.get_hdr_cloud_operation_type(ol.header_id) NOT IN(
                                                    'CHANGE OF SERVICE','CMRB','UPDATE'
                                                )
                                                AND op.pricing_attribute94 NOT IN(
                                                    'RAMPED_UPDATE'
                                                )
                                            ) THEN XMLCOLATTVAL('IS_BASE_SERVICE_COMPONENT' AS name,
                                            DECODE(upper(emsv.c_ext_attr1),'STANDALONE','Y','N') AS value)
                                        END
                                    AS properties,
                                        CASE
                                            WHEN(
                                                (upper(emsv.c_ext_attr1) = 'STANDALONE')
                                                AND misont_cloud_pub2.get_hdr_cloud_operation_type(ol.header_id) NOT IN(
                                                    'CHANGE OF SERVICE','CMRB','UPDATE'
                                                )
                                                AND op.pricing_attribute94 NOT IN(
                                                    'RAMPED_UPDATE'
                                                )
                                            ) THEN XMLCOLATTVAL('METRIC_NAME' AS name,
                                            mc.segment1 AS value)
                                        END
                                    AS properties,
                                        CASE
                                            WHEN(misont_cloud_pub2.get_hdr_cloud_operation_type(ol.header_id) <> 'CHANGE OF SERVICE') THEN XMLCOLATTVAL(mc.segment1 AS name,
                                            op.pricing_attribute3 AS value)
                                        END
                                    AS properties,
                                    XMLCOLATTVAL('SERVICE_PART_DESCRIPTION' AS name,
                                    substr(msi.description,1,100) AS value) AS properties,
                                    XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                    substr(msil.description,1,100) AS value) AS properties,
                                    XMLCOLATTVAL('CONTRACT_SERVICE_LINE_ID' AS name,
                                    okl.id AS value) AS properties,
                                    XMLCOLATTVAL('CONTRACT_NUMBER' AS name,
                                    okh.contract_number AS value) AS properties)
                                ) )
                            )
                        FROM
                            oe_order_lines_all ol,
                            oe_order_lines_all oll,
                            oe_order_price_attribs op,
                            mtl_system_items_b msi,
                            oe_sets oes,
                            oe_line_sets sln,
                            mtl_categories mc,
                            mtl_item_categories mic,
                            mtl_system_items_b msil,
                            okc_k_lines_b okl,
                            okc_k_items oki,
        /*    fnd_lookup_values flv*/
                            (
                                SELECT
                                    c_ext_attr1,
                                    inventory_item_id
                                FROM
                                    ego_mtl_sy_items_ext_vl
                                WHERE
                                    attr_group_id = 48084
                                    AND   organization_id = 14354
                            ) emsv
                        WHERE
                            ol.item_type_code = 'SERVICE'
                            AND   ol.header_id = oh.header_id
                            AND   op.line_id = ol.line_id
                            AND   msi.inventory_item_id = ol.inventory_item_id
                            AND   msi.organization_id = ol.ship_from_org_id
                            AND   EXISTS(
                                SELECT
                                    1
                                FROM
                                    mtl_item_categories mic
          /* Check if the line is CLOUDSUBS*/
                                WHERE
                                    category_set_id = 1
                                    AND   category_id = 859855
                                    AND   organization_id = 14354
                                    AND   inventory_item_id = ol.inventory_item_id
                            )
                            AND   oll.header_id = ol.header_id
                            AND   oll.line_id = ol.service_reference_line_id
                            AND   oes.set_id = sln.set_id
                            AND   oes.set_type = 'FULFILLMENT_SET'
                            AND   sln.line_id = ol.service_reference_line_id
                            AND   mc.category_id = mic.category_id
                            AND   mic.category_set_id = 1100026004
                            AND   mic.organization_id = 14354
                            AND   mic.inventory_item_id = ol.inventory_item_id
                            AND   msil.inventory_item_id = oll.inventory_item_id
                            AND   msil.organization_id = 14354
                            AND   okl.dnz_chr_id = okh.id
                            AND   okl.cle_id IS NULL
                            AND   oki.jtot_object1_code = 'OKX_SERVICE'
                            AND   oki.cle_id = okl.id
                            AND   msi.inventory_item_id = oki.object1_id1
                            AND   emsv.inventory_item_id(+) = msi.inventory_item_id
                    )
                ) AS "Order_List"
            INTO
                l_order_str
            FROM
                okc_k_headers_all_b okh,
                oe_order_headers_all oh,
                okc_k_rel_objs rel,
                hz_cust_accounts cust_acct,
                hz_parties cust_party
            WHERE
                okh.id = p_chr_id
                AND   rel.chr_id = okh.id
                AND   rel.jtot_object1_code = 'OKX_ORDERHEAD'
                AND   rel.object1_id1 = oh.header_id
                AND   nvl(to_number(oh.attribute8),oh.sold_to_org_id) = cust_acct.cust_account_id
                AND   cust_acct.party_id = cust_party.party_id;
    /*- select xmlroot(l_order_str,VERSION '1.0' ,STANDALONE YES) as xmlroot into l_order_str from dual;*/

            l_order_data := l_order_str.getclobval ();
            wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);
    /*--- --    Dbms_Output.put_line ('Event Raised');*/
    /*- END LOOP;*/

        ELSE
            SELECT
                XMLELEMENT(
                    "OrderHeader",
                    XMLATTRIBUTES(
                        okh.id AS "HEADERID",okh.org_id AS "ORGANIZATIONID", (
                            SELECT
                                round(SUM(TO_CHAR(SYSDATE,'DDDSSSSSSSSS') + dbms_random.value(1000000000,9999999999) ) )
                            FROM
                                dual
                        ) AS "ORDERNUMBER",sys_extract_utc(to_timestamp(TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "ORDERDATE",cust_party.party_name AS "CUSTNAME"
,cust_acct.account_number AS "CUSTACCTNUMBER",cust_party.party_id AS "PARTYID",'ONBOARDING' AS "OPERATIONTYPE", (
                            SELECT
                                name
                            FROM
                                csi_item_instances cii,
                                csi_systems_tl cst,
                                okc_k_items oki
                            WHERE
                                cii.instance_id = to_number(oki.object1_id1)
                                AND   oki.jtot_object1_code = 'OKX_CUSTPROD'
                                AND   cii.system_id = cst.system_id
                                AND   cst.language = 'US'
                                AND   okh.id = oki.dnz_chr_id
                                AND   ROWNUM = 1
                        ) AS "CSI"
                    ),
                    XMLCOLATTVAL('Y' AS "MIGRATE_SUBSCRIPTIONS"),
                    XMLCOLATTVAL(nvl(js.email_address,'oal_erp_initiatives_supp_sales_grp@oracle.com') AS "SALES_REPS"),
                    XMLCOLATTVAL(cust_party.party_id AS "TCA_PARTY_ID"),
                    XMLCOLATTVAL(buyer_sso.login AS "BUYER_SSO_USERNAME"),
                    XMLCOLATTVAL(nvl(cust_party.organization_name_phonetic,cust_party.party_name) AS "CUSTOMER_ENGLISH_NAME"),
                    XMLCOLATTVAL(NULL AS "SALES_CHANNEL"),
                    XMLCOLATTVAL(NULL AS "CUSTOMER_TYPE"),
                    XMLCOLATTVAL(cust_party.party_name AS "CUSTOMER_PRIMARY_NAME"),
                    XMLCOLATTVAL(substr(hl.address1
                    || ' '
                    || hl.address2
                    || ' '
                    || hl.address3
                    || ' '
                    || hl.address4,1,500) AS "CUSTOMER_ADDRESS"),
                    XMLCOLATTVAL(hl.city AS "CUSTOMER_CITY"),
                    XMLCOLATTVAL(hl.state AS "CUSTOMER_STATE"),
                    XMLCOLATTVAL(hl.postal_code AS "CUSTOMER_ZIP"),
                    XMLCOLATTVAL(hl.country AS "CUSTOMER_COUNTRY_CODE"),
                    XMLCOLATTVAL(misimd_tas_cloud_wf.get_incremental_properties(p_chr_id) AS "$$INCREMENTAL_PROPERTIES$$"),
                    XMLCOLATTVAL('|' AS "$$FS$$"),
                    XMLCOLATTVAL('Y' AS "IS_TAS_ENABLED"),
                    XMLCOLATTVAL('Y' AS "IS_SUBSCRIPTION_ENABLED"),
                    (
                        SELECT
                            XMLELEMENT(
                                "OrderLines",
                                XMLAGG(XMLELEMENT(
                                    "OrderLine",
                                    XMLATTRIBUTES(
                                        okl.id AS "LINEID",'MIGRATE' AS "LINE_OPERATION_TYPE",11 AS "LICENSE_LINE_ID",'dummy' AS "LICENSE_ITEM_ID",msi.segment1 AS "ORDEREDITEM", (substr(mct.description,
(instr(mct.description,'-') + 1) )
                                        || '-'
                                        || nvl(okl.attribute10,NULL) ) AS "FULFILLMENT_SET",msi.inventory_item_id AS "ITEMID",DECODE(oki.jtot_object1_code,'OKX_CUSTPROD','LICENSE','OKX_SERVICE','SERVICE'
,oki.jtot_object1_code) AS "LINETYPE",'SaaS' AS "CLOUDORDERTYPE", (
                                            SELECT
                                                nvl(okll.attribute2,'oal_erp_initiatives_supp_sales_grp@oracle.com')
                                            FROM
                                                okc_k_lines_b okll
                                            WHERE
                                                okll.cle_id = okl.id
                                                AND   ROWNUM = 1
                                        ) AS "BUYEREMAILID", (
                                            SELECT
                                                nvl(okll.attribute3,'oal_erp_initiatives_supp_sales_grp@oracle.com')
                                            FROM
                                                okc_k_lines_b okll
                                            WHERE
                                                okll.cle_id = okl.id
                                                AND   ROWNUM = 1
                                        ) AS "SERVICEADMINEMAILID", (
                                            SELECT
                                                okll.attribute10
                                            FROM
                                                okc_k_lines_b okll
                                            WHERE
                                                okll.cle_id = okl.id
                                                AND   ROWNUM = 1
                                        ) AS "SUBSCRIPTIONID",'N' AS "OVERAGEOPTED",nvl( (
                                            SELECT
                                                pricing_attribute99
                                            FROM
                                                csi_i_pricing_attribs cip,
                                                okc_k_lines_b okll
                                            WHERE
                                                cip.pricing_attribute92 = okll.attribute10
                                                AND   okll.cle_id = okl.id
                                                AND   ROWNUM = 1
                                        ),'US001') AS "DATACENTER",msi.description AS "ITEMDESC",sys_extract_utc(to_timestamp(TO_CHAR(okl.start_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS'
) ) AS "STARTDATE", (
                                            SELECT
                                                MIN(sys_extract_utc(to_timestamp(TO_CHAR(okls.start_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) )
                                            FROM
                                                okc_k_lines_b okls,
                                                okc_k_lines_b oklc
                                            WHERE
                                                oklc.dnz_chr_id = p_chr_id
                                                AND   oklc.attribute10 = (
                                                    SELECT
                                                        attribute10
                                                    FROM
                                                        okc_k_lines_b oklc
                                                    WHERE
                                                        oklc.cle_id = okl.id
                                                        AND   attribute10 IS NOT NULL
                                                        AND   ROWNUM = 1
                                                )
                                                AND   okls.dnz_chr_id = p_chr_id
                                                AND   okls.id = oklc.cle_id
                                                AND   okls.sts_code IN(
                                                    'ACTIVE','SIGNED'
                                                )
                                        ) AS "HDR_START_DATE", (
                                            SELECT
                                                MAX(sys_extract_utc(to_timestamp(TO_CHAR(okls.end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) )
                                            FROM
                                                okc_k_lines_b okls,
                                                okc_k_lines_b oklc
                                            WHERE
                                                oklc.dnz_chr_id = p_chr_id
                                                AND   oklc.attribute10 = (
                                                    SELECT
                                                        attribute10
                                                    FROM
                                                        okc_k_lines_b oklc
                                                    WHERE
                                                        oklc.cle_id = okl.id
                                                        AND   attribute10 IS NOT NULL
                                                        AND   ROWNUM = 1
                                                )
                                                AND   okls.dnz_chr_id = p_chr_id
                                                AND   okls.id = oklc.cle_id
                                                AND   okls.sts_code IN(
                                                    'ACTIVE','SIGNED'
                                                )
                                        ) AS "HDR_END_DATE",sys_extract_utc(to_timestamp(TO_CHAR(okl.end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "LINE_END_DATE"
                                    ),
                                    (
                                        SELECT
                                            XMLAGG(XMLELEMENT(
                                                "LicenseItem",
                                                XMLATTRIBUTES(
                                                    msii.segment1 AS "LICENSE_ITEM",'STANDARD' AS "LICENSE_LINE_TYPE", (misimd_tas_cloud_wf.get_migration_servicegroup(p_chr_id,nvl(okll.attribute10,okll.attribute5
) )
                                                    || '-'
                                                    || nvl(okll.attribute10,okll.attribute5) ) AS "FULFILLMENT_SET"
                                                ),
                                                XMLCOLATTVAL(XMLCOLATTVAL(mc.segment1 AS name,
                                                misimd_tas_cloud_wf.get_covered_line_metrics(okl.id,'METRIC_VALUE') AS value) AS properties)
                                            ) )
                                        FROM
                                            okc_k_items okii,
                                            okc_k_lines_b okll,
                                            mtl_system_items_b msii,
                                            mtl_categories mc,
                                            mtl_item_categories mic,
                                            csi_i_pricing_attribs cip,
                                            csi_item_instances cii
                                        WHERE
                                            msii.organization_id = 14354
                                            AND   msii.inventory_item_id = (
                                                SELECT
                                                    k.inventory_item_id
                                                FROM
                                                    csi_item_instances k
                                                WHERE
                                                    to_number(okii.object1_id1) = k.instance_id
                                            )
                                            AND   okii.cle_id = okll.id
                                            AND   okll.cle_id = okl.id
                                            AND   okii.jtot_object1_code = 'OKX_CUSTPROD'
                                            AND   mc.category_id = mic.category_id
                                            AND   mic.category_set_id = 1100026004
                                            AND   mic.organization_id = 14354
                                            AND   mic.inventory_item_id = msii.inventory_item_id
                                            AND   cii.instance_id = cip.instance_id
                                            AND   okii.object1_id1 = cii.instance_id
                                            AND   ROWNUM = 1
                                    ),
                                    (
                                        SELECT
                                            XMLAGG(XMLELEMENT(
                                                "LicenseItem",
                                                XMLATTRIBUTES(
                                                    mtsiii.segment1 AS "LICENSE_ITEM",'INCLUDED' AS "LICENSE_LINE_TYPE",'DUMMY' AS "FULFILLMENT_SET"
                                                ),
                                                XMLCOLATTVAL(XMLCOLATTVAL(mci.segment1 AS name,
                                                misimd_tas_cloud_wf.get_covered_line_metrics(okl.id,'METRIC_VALUE') AS value) AS properties,
                                                XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                                mtsiii.description AS value) AS properties)
                                            ) )
                                        FROM
                                            bom_inventory_components_v bom_component,
                                            bom_bill_of_materials_v bom,
                                            mtl_system_items_b mtsiii,
                                            okc_k_items okiii,
                                            (
                                                SELECT DISTINCT
                                                    cle_id,
                                                    id
                                                FROM
                                                    okc_k_lines_b
                                                WHERE
                                                    dnz_chr_id = p_chr_id
                                                    AND   cle_id IS NOT NULL
                                                    AND   sts_code IN(
                                                        'ACTIVE','SIGNED'
                                                    )
                                            ) oklll,
                                            mtl_categories mci,
                                            mtl_item_categories mici
                                        WHERE
                                            bom.bill_sequence_id = bom_component.bill_sequence_id
                                            AND   bom.assembly_item_id = (
                                                SELECT
                                                    k.inventory_item_id
                                                FROM
                                                    csi_item_instances k
                                                WHERE
                                                    to_number(okiii.object1_id1) = k.instance_id
                                            )
                                            AND   mtsiii.inventory_item_id = bom_component.component_item_id
                                            AND   mtsiii.organization_id = bom.organization_id
                                            AND   mtsiii.organization_id = 14354
                                            AND   okiii.jtot_object1_code = 'OKX_CUSTPROD'
                                            AND   okiii.cle_id = (
                                                SELECT
                                                    id
                                                FROM
                                                    okc_k_lines_b
                                                WHERE
                                                    cle_id = oklll.cle_id
                                                    AND   ROWNUM = 1
                                            )
                                            AND   oklll.cle_id = okl.id
                                            AND   mci.category_id = mici.category_id
                                            AND   mici.category_set_id = 1100026004
                                            AND   mici.organization_id = 14354
                                            AND   nvl(bom_component.disable_date,SYSDATE + 1) > SYSDATE
                                            AND   mici.inventory_item_id = mtsiii.inventory_item_id
                                            AND   okiii.object1_id1 = misimd_tas_cloud_wf.get_unique_instance_id(oklll.id)
                                    ),
                                    XMLCOLATTVAL(XMLCOLATTVAL('IS_ADDITIONAL_INSTANCE' AS name,
                                    DECODE(flv_item_exceptions.enabled_flag,'Y','Y','N') AS value) AS properties,
                                    XMLCOLATTVAL('IS_BASE_SERVICE_COMPONENT' AS name,
                                    DECODE(upper(emsv.c_ext_attr1),'STANDALONE','Y','N') AS value) AS properties,
                                    XMLCOLATTVAL('METRIC_NAME' AS name,
                                    misimd_tas_cloud_wf.get_covered_line_metrics(okl.id,'METRIC_NAME') AS value) AS properties,
                                    XMLCOLATTVAL(misimd_tas_cloud_wf.get_covered_line_metrics(okl.id,'METRIC_NAME') AS name,
                                    misimd_tas_cloud_wf.get_covered_line_metrics(okl.id,'METRIC_VALUE') AS value) AS properties,
                                    XMLCOLATTVAL('SERVICE_PART_DESCRIPTION' AS name,
                                    msi.description AS value) AS properties,
                                    XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                    misimd_tas_cloud_wf.get_covered_line_metrics(okl.id,'LICENSE_PART_DESCRIPTION') AS value) AS properties,
                                    XMLCOLATTVAL('CONTRACT_SERVICE_LINE_ID' AS name,
                                    okl.id AS value) AS properties,
                                    XMLCOLATTVAL('CONTRACT_NUMBER' AS name,
                                    okh.contract_number AS value) AS properties)
                                ) )
                            )
                        FROM
                            okc_k_lines_b okl,
                            okc_k_items oki,
                            mtl_system_items_b msi,
                            mtl_item_categories mic,
                            mtl_categories_b mc,
                            mtl_category_sets mcs,
                            mtl_categories_tl mct,
                            (
                                SELECT
                                    lookup_code,
                                    enabled_flag
                                FROM
                                    fnd_lookup_values flv
                                WHERE
                                    flv.lookup_type = 'MISONT_CLOUD_NOTIFY_CRITERIA'
                                    AND   flv.tag = 'ITEM'
                                    AND   flv.language = 'US'
                            ) flv_item_exceptions,
                            (
                                SELECT
                                    c_ext_attr1,
                                    inventory_item_id
                                FROM
                                    ego_mtl_sy_items_ext_vl
                                WHERE
                                    attr_group_id = 48084
                                    AND   organization_id = 14354
                            ) emsv
                        WHERE
                            oki.dnz_chr_id = okl.dnz_chr_id
                            AND   flv_item_exceptions.lookup_code(+) = msi.segment1
                            AND   okl.dnz_chr_id = okh.id
                            AND   okl.cle_id IS NULL
                            AND   oki.jtot_object1_code = 'OKX_SERVICE'
                            AND   oki.cle_id = okl.id
                            AND   msi.inventory_item_id = oki.object1_id1
                            AND   msi.organization_id = 14354
                            AND   msi.organization_id = mic.organization_id
                            AND   msi.inventory_item_id = mic.inventory_item_id
                            AND   mic.category_id = mc.category_id
                            AND   mic.category_set_id = mcs.category_set_id
                            AND   mcs.category_set_name = 'PROVISIONING_GROUP'
                            AND   mic.category_id = mct.category_id
                            AND   mct.language = 'US'
                            AND   okl.sts_code IN(
                                'ACTIVE','SIGNED'
                            )
                            AND   emsv.inventory_item_id(+) = msi.inventory_item_id
                    )
                ) AS "Order_List"
            INTO
                l_order_str
            FROM
                okc_k_headers_all_b okh,
                hz_cust_accounts cust_acct,
                hz_parties cust_party,
                okc_k_party_roles_b okp,
                hz_cust_site_uses_all hcs,
                hz_cust_acct_sites_all hca,
                hz_party_sites hps,
                hz_locations hl,
                okc_contacts oc,
                jtf_rs_salesreps js,
                (
                    SELECT
                        nvl(attribute2,'oal_erp_initiatives_supp_sales_grp@oracle.com') login
                    FROM
                        okc_k_lines_b
                    WHERE
                        dnz_chr_id = p_chr_id
                        AND   cle_id IS NOT NULL
                        AND   ROWNUM = 1
                ) buyer_sso
            WHERE
                okh.id = p_chr_id
                AND   okp.dnz_chr_id = okh.id
                AND   okp.cle_id IS NULL
                AND   okh.sts_code <> 'EXPIRED'
                AND   cust_party.party_id = okp.object1_id1
                AND   cust_acct.party_id = cust_party.party_id
                AND   cust_acct.cust_account_id = (
                    SELECT
                        cust_acct_id
                    FROM
                        okc_k_lines_b okl
                    WHERE
                        okl.dnz_chr_id = p_chr_id
                        AND   okl.cle_id IS NULL
                        AND   okl.cust_acct_id IS NOT NULL
                        AND   ROWNUM = 1
                )
                AND   okh.bill_to_site_use_id = hcs.site_use_id
                AND   hcs.cust_acct_site_id = hca.cust_acct_site_id
                AND   hca.party_site_id = hps.party_site_id
                AND   hps.location_id = hl.location_id
                AND   hcs.site_use_code = 'BILL_TO'
                AND   oc.object1_id1 = js.salesrep_id
                AND   oc.cro_code = 'SUP_SALES'
                AND   oc.dnz_chr_id = okh.id
                AND   ROWNUM = 1;

            SELECT
                XMLROOT(l_order_str,
                VERSION '1.0',STANDALONE YES) AS xmlroot
            INTO
                l_order_str
            FROM
                dual;

            l_order_data := l_order_str.getclobval ();
            wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);
    /*-- --    Dbms_Output.put_line ('Event Raised');*/
    /*- END LOOP;*/

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            oe_debug_pub.add('Exception in Prepare Notify Payload');
            resultout := 'Exception in MISIMD_TAS_CLOUD_WF.prepare_notify_payload: '
            || sqlcode
            || ' - '
            || sqlerrm;
  /*-    raise;*/
    END migrate_subscriptions;

    PROCEDURE testingharness (
        p_quote_number    IN NUMBER,
        p_quote_version   IN NUMBER,
        resultout         OUT NOCOPY VARCHAR2
    ) IS

        l_operation_type    VARCHAR2(50);
        l_quote_header_id   NUMBER;
        l_paramlist_t       wf_parameter_list_t := NULL;
        l_order_str         XMLTYPE;
        l_order_data        CLOB;
        l_subscription_id   VARCHAR2(40);
        l_public_sector     VARCHAR2(20);
  /* Public sector fix*/
    BEGIN
        resultout := 'SUCCESS';
  /*120.60 CY15 Sprint 4*/
        BEGIN
            SELECT
                pricing_attribute48
            INTO
                l_public_sector
            FROM
                oe_order_price_attribs opc,
                aso_quote_headers_all aso
            WHERE
                1 = 1
                AND   aso.order_id = opc.header_id
                AND   quote_number = p_quote_number
                AND   quote_version = p_quote_version
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                l_public_sector := NULL;
        END;

        SELECT
            quote_header_id
        INTO
            l_quote_header_id
        FROM
            aso_quote_headers_all
        WHERE
            quote_number = p_quote_number
            AND   quote_version = p_quote_version;

        SELECT
            misaso_supplement.header_supplement(l_quote_header_id,'Action')
        INTO
            l_operation_type
        FROM
            dual;

        IF
            l_operation_type = 'New Subscription'
        THEN
            l_operation_type := 'ONBOARDING';
        ELSIF l_operation_type = 'Pilot Onboarding' THEN
            l_operation_type := 'PILOT_ONBOARDING';
        ELSIF l_operation_type = 'Pilot Conversion' THEN
            l_operation_type := 'PILOT_CONVERSION';
        ELSIF l_operation_type = 'Update Subscription' THEN
            l_operation_type := 'UPDATE';
        ELSIF l_operation_type = 'Renew / Extend Subscription' THEN
            l_operation_type := 'EXTENSION';
        ELSIF l_operation_type = 'New Subscription with Phased Deployment' THEN
            l_operation_type := 'RAMPED';
        END IF;

        SELECT
            XMLELEMENT(
                "OrderHeader",
                XMLATTRIBUTES(
                    aqh.quote_header_id AS "HEADERID",aqh.org_id AS "ORGANIZATIONID",aqh.quote_number
                    || aqh.quote_version AS "ORDERNUMBER",sys_extract_utc(to_timestamp(TO_CHAR(aqh.creation_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "ORDERDATE"
,cust_party.party_name AS "CUSTNAME",cust_acct.account_number AS "CUSTACCTNUMBER",cust_party.party_id AS "PARTYID",NULL AS "PROCESSINGDATE",l_operation_type AS "OPERATIONTYPE"
,'12345' AS "CSI",NULL AS "COTERMSUBSID"
                ),
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(cust_party.party_id AS "TCA_PARTY_ID")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL( (
                            SELECT
                                misaso_supplement.header_supplement(aqh.quote_header_id,'Buyer email id')
                            FROM
                                dual
                        ) AS "BUYER_SSO_USERNAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(NULL AS "BUYER_FIRST_NAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(NULL AS "BUYER_LAST_NAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(NULL AS "AA_FIRST_NAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(NULL AS "AA_LAST_NAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(nvl(cust_party.organization_name_phonetic,cust_party.party_name) AS "CUSTOMER_ENGLISH_NAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(js.email_address AS "SALES_REPS")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(aqh.sales_channel_code AS "SALES_CHANNEL")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(NULL AS "CUSTOMER_TYPE")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(cust_party.party_name AS "CUSTOMER_PRIMARY_NAME")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(substr(hl.address1
                        || ' '
                        || hl.address2
                        || ' '
                        || hl.address3
                        || ' '
                        || hl.address4,1,500) AS "CUSTOMER_ADDRESS")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(hl.city AS "CUSTOMER_CITY")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(hl.state AS "CUSTOMER_STATE")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(hl.postal_code AS "CUSTOMER_ZIP")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL(hl.country AS "CUSTOMER_COUNTRY_CODE")
                    END,
                    CASE
                        WHEN l_operation_type = 'PILOT_ONBOARDING' THEN XMLCOLATTVAL('Y' AS "IS_PILOT")
                    END,
                    CASE
                        WHEN l_operation_type = 'PILOT_CONVERSION' THEN XMLCOLATTVAL('N' AS "IS_PILOT")
                    END,
                    CASE
                        WHEN l_operation_type = 'CMRB' THEN XMLCOLATTVAL('Y' AS "IS_CMRB")
                    END,
                    CASE
                        WHEN l_operation_type <> 'CMRB' THEN XMLCOLATTVAL(NULL AS "$$INCREMENTAL_PROPERTIES$$")
                    END,
                    CASE
                        WHEN l_operation_type <> 'CMRB' THEN XMLCOLATTVAL('|' AS "$$FS$$")
                    END,
                    CASE
                        WHEN l_operation_type IN(
                            'PILOT_ONBOARDING','ONBOARDING','RAMPED'
                        ) THEN XMLCOLATTVAL('Y' AS "IS_OAE")
                    END,
                XMLCOLATTVAL(NULL AS "PRODUCT_RELEASE_VERSION"),
                XMLCOLATTVAL(NULL AS "ADDITIONAL_INSTANCE_PRODUCT_RELEASE_VERSION"),
                XMLCOLATTVAL(NULL AS "ENVIRONMENT_LANGUAGES"),
                XMLCOLATTVAL(NULL AS "IDM_TYPE"),
                XMLCOLATTVAL(NULL AS "ENVIRONMENT_COUNTRY"),
                XMLCOLATTVAL('Y' AS "IS_TAS_ENABLED"),
                XMLCOLATTVAL('Y' AS "IS_SUBSCRIPTION_ENABLED"),
                (
                    SELECT
                        XMLELEMENT(
                            "OrderLines",
                            XMLAGG(XMLELEMENT(
                                "OrderLine",
                                XMLATTRIBUTES(
                                    aql.quote_line_id AS "LINEID",l_operation_type AS "LINE_OPERATION_TYPE",aqll.quote_line_id AS "LICENSE_LINE_ID",aqll.inventory_item_id AS "LICENSE_ITEM_ID",NULL
AS "ORIGSYSLINEREF",msi.segment1 AS "ORDEREDITEM",NULL AS "FULFILLMENT_SET",aql.inventory_item_id AS "ITEMID",DECODE(aql.item_type_code,'SRV','SERVICE','LICENSE'
) AS "LINETYPE",misont_cloud_pub2.get_cloud_item_type(msi.segment1) AS "CLOUDORDERTYPE", (
                                        SELECT
                                            misaso_supplement.header_supplement(aqh.quote_header_id,'Buyer email id')
                                        FROM
                                            dual
                                    ) AS "BUYEREMAILID", (
                                        SELECT
                                            misaso_supplement.header_supplement(aqh.quote_header_id,'Account Admin Email')
                                        FROM
                                            dual
                                    ) AS "SERVICEADMINEMAILID",nvl(aql.attribute8,DECODE(aql.attribute6,NULL,aql.quote_line_id,aql.attribute6) ) AS "SUBSCRIPTIONID",NULL AS "SYSTEMINTEGRATOREMAILID"
,'N' AS "STOREORDER",'N' AS "OVERAGEOPTED",aqh.attribute9 AS "DATACENTER",msi.description AS "ITEMDESC",sys_extract_utc(to_timestamp(TO_CHAR(aql.start_date_active
,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "STARTDATE",sys_extract_utc(to_timestamp(TO_CHAR(aql.end_date_active,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS'
) ) AS "LINE_END_DATE",sys_extract_utc(to_timestamp(TO_CHAR(aql.end_date_active,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "HDR_END_DATE"
                                ),
                                (
                                    SELECT
                                        XMLAGG(XMLELEMENT(
                                            "LicenseItem",
                                            XMLATTRIBUTES(
                                                msi.segment1 AS "LICENSE_ITEM",'STANDARD' AS "LICENSE_LINE_TYPE", (misimd_tas_cloud_wf.get_aso_servicegroup(aql.quote_line_id)
                                                || '-'
                                                || DECODE(aql.attribute6,NULL,aql.quote_line_id,aql.attribute6) ) AS "FULFILLMENT_SET"
                                            ),
                                            XMLCOLATTVAL(
                                                CASE
                                                    WHEN l_operation_type NOT IN(
                                                        'CHANGE OF SERVICE','CMRB'
                                                    ) THEN XMLCOLATTVAL(mc.segment1 AS name,
                                                    aqlll.quantity AS value)
                                                END
                                            AS properties,
                                            XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                            1 AS value) AS properties,
                                            XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                            msi.description AS value) AS properties)
                                        ) )
                                    FROM
                                        aso_quote_lines_all aqlll,
                                        mtl_categories mc,
                                        mtl_item_categories mic,
                                        mtl_system_items_b msi
                                    WHERE
                                        aqlll.line_number = aql.line_number
                                        AND   aqlll.item_type_code = 'SVA'
                                        AND   aqlll.quote_header_id = aql.quote_header_id
                                        AND   mc.category_id = mic.category_id
                                        AND   mic.category_set_id = 1100026004
                                        AND   mic.organization_id = 14354
                                        AND   mic.inventory_item_id = aqll.inventory_item_id
                                        AND   msi.inventory_item_id = aqll.inventory_item_id
                                        AND   msi.organization_id = 14354
                                ),
                                (
                                    SELECT
                                        XMLAGG(XMLELEMENT(
                                            "LicenseItem",
                                            XMLATTRIBUTES(
                                                mts.segment1 AS "LICENSE_ITEM",'INCLUDED' AS "LICENSE_LINE_TYPE",'DUMMY' AS "FULFILLMENT_SET"
                                            ),
                                            XMLCOLATTVAL(
                                                CASE
                                                    WHEN l_operation_type NOT IN(
                                                        'CHANGE OF SERVICE','CMRB'
                                                    ) THEN XMLCOLATTVAL(mc.segment1 AS name,
                                                    aqll.quantity AS value)
                                                END
                                            AS properties,
                                            XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                            1 AS value) AS properties,
                                            XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                            mts.description AS value) AS properties)
                                        ) )
                                    FROM
                                        bom_inventory_components_v bom_component,
                                        bom_bill_of_materials_v bom,
                                        mtl_system_items_b mts,
                                        mtl_categories mc,
                                        mtl_item_categories mic
                                    WHERE
                                        bom.bill_sequence_id = bom_component.bill_sequence_id
                                        AND   bom.assembly_item_id = aqll.inventory_item_id
                                        AND   mts.inventory_item_id = bom_component.component_item_id
                                        AND   mts.organization_id = bom.organization_id
                                        AND   mts.organization_id = 14354
                                        AND   mc.category_id = mic.category_id
                                        AND   mic.category_set_id = 1100026004
                                        AND   mic.organization_id = 14354
                                        AND   nvl(bom_component.disable_date,SYSDATE + 1) > SYSDATE
                                        AND   mic.inventory_item_id = mts.inventory_item_id
                                ),
                                XMLCOLATTVAL(XMLCOLATTVAL('IS_BASE_SERVICE_COMPONENT' AS name,
                                DECODE(upper(emsv.c_ext_attr1),'STANDALONE','Y','N') AS value) AS properties,
                                    CASE
                                        WHEN(upper(emsv.c_ext_attr1) = 'STANDALONE') THEN XMLCOLATTVAL('METRIC_NAME' AS name,
                                        mc.segment1 AS value)
                                    END
                                AS properties,
                                    CASE
                                        WHEN l_operation_type NOT IN(
                                            'CHANGE OF SERVICE','CMRB'
                                        ) THEN XMLCOLATTVAL(mc.segment1 AS name,
                                        aql.quantity AS value)
                                    END
                                AS properties,
                                XMLCOLATTVAL('SERVICE_PART_DESCRIPTION' AS name,
                                msi.description AS value) AS properties,
                                XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                msil.description AS value) AS properties)
                            ) )
                        )
                    FROM
                        aso_quote_lines_all aql,
                        aso_quote_lines_all aqll,
                        mtl_system_items_b msi,
                        mtl_categories mc,
                        mtl_item_categories mic,
                        mtl_system_items_b msil,
                        (
                            SELECT
                                c_ext_attr1,
                                inventory_item_id
                            FROM
                                ego_mtl_sy_items_ext_vl
                            WHERE
                                attr_group_id = 48084
                                AND   organization_id = 14354
                        ) emsv
                    WHERE
                        aql.item_type_code = 'SRV'
                        AND   aql.quote_header_id = aqh.quote_header_id
                        AND   msi.inventory_item_id = aql.inventory_item_id
                        AND   msi.organization_id = 14354
                        AND   EXISTS(
                            SELECT
                                1
                            FROM
                                mtl_item_categories mic
        /* Check if the line is CLOUDSUBS*/
                            WHERE
                                category_set_id = 1
                                AND   category_id = 859855
                                AND   organization_id = 14354
                                AND   inventory_item_id = aql.inventory_item_id
                        )
                        AND   aqll.line_number = aql.line_number
                        AND   aqll.item_type_code = 'SVA'
                        AND   aqll.quote_header_id = aql.quote_header_id
                        AND   mc.category_id = mic.category_id
                        AND   mic.category_set_id = 1100026004
                        AND   mic.organization_id = 14354
                        AND   mic.inventory_item_id = aql.inventory_item_id
                        AND   msil.inventory_item_id = aqll.inventory_item_id
                        AND   msil.organization_id = 14354
                        AND   emsv.inventory_item_id(+) = msi.inventory_item_id
                )
            ) AS "Order_List"
        INTO
            l_order_str
        FROM
            aso_quote_headers_all aqh,
            hz_cust_accounts cust_acct,
            hz_parties cust_party,
            hz_party_sites hps,
            hz_locations hl,
            jtf_rs_salesreps js
        WHERE
            aqh.quote_number = p_quote_number
            AND   aqh.quote_version = p_quote_version
            AND   aqh.cust_account_id = cust_acct.cust_account_id
            AND   cust_acct.party_id = aqh.cust_party_id
            AND   cust_party.party_id = cust_acct.party_id
            AND   aqh.invoice_to_party_site_id = hps.party_site_id
            AND   hps.location_id = hl.location_id
            AND   js.resource_id = aqh.resource_id
            AND   js.org_id = aqh.org_id;

        SELECT
            XMLROOT(l_order_str,
            VERSION '1.0',STANDALONE YES) AS xmlroot
        INTO
            l_order_str
        FROM
            dual;

        l_order_data := l_order_str.getclobval ();
  /* wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',
  p_event_key => systimestamp,
  p_event_data => l_order_data,
  p_parameters  => l_paramlist_t,
  p_send_date => sysdate   );    */
        resultout := l_order_str.getstringval ();
    EXCEPTION
        WHEN OTHERS THEN
            oe_debug_pub.add('Exception in Prepare Notify Payload');
            resultout := 'Exception in MISIMD_TAS_CLOUD_WF.prepare_notify_payload: '
            || sqlcode
            || ' - '
            || sqlerrm;
            RAISE;
    END testingharness;

    FUNCTION get_migration_servicegroup (
        p_hdr_id   IN NUMBER,
        p_sub_id   IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_service_group   VARCHAR2(50);
    BEGIN
        BEGIN
            SELECT
                substr(mctc.description,instr(mctc.description,'-') + 1)
            INTO
                l_service_group
            FROM
                okc_k_lines_b oklc,
                (
                    SELECT
                        *
                    FROM
                        okc_k_lines_b
                    WHERE
                        attribute10 = p_sub_id
                        AND   dnz_chr_id = p_hdr_id
                ) okllc,
                okc_k_items okic,
                mtl_system_items_b msic,
                mtl_item_categories micc,
                mtl_categories_b mcc,
                mtl_category_sets mcsc,
                mtl_categories_tl mctc,
                ego_mtl_sy_items_ext_vl emsie
            WHERE
                msic.organization_id = 14354
                AND   msic.inventory_item_id = okic.object1_id1
                AND   okic.cle_id = okllc.cle_id
                AND   msic.inventory_item_id = micc.inventory_item_id
                AND   micc.category_id = mcc.category_id
                AND   micc.category_set_id = mcsc.category_set_id
                AND   mcsc.category_set_name = 'PROVISIONING_GROUP'
                AND   micc.category_id = mctc.category_id
                AND   mctc.language = 'US'
                AND   micc.organization_id = 14354
                AND   oklc.dnz_chr_id = p_hdr_id
                AND   okllc.cle_id = oklc.id
                AND   upper(emsie.c_ext_attr1) = 'STANDALONE'
                AND   emsie.inventory_item_id = msic.inventory_item_id
                AND   emsie.attr_group_id = 48084
                AND   emsie.organization_id = 14354
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
                SELECT
                    substr(mctc.description,instr(mctc.description,'-') + 1)
                INTO
                    l_service_group
                FROM
                    okc_k_lines_b oklc,
                    (
                        SELECT
                            *
                        FROM
                            okc_k_lines_b
                        WHERE
                            attribute10 = p_sub_id
                            AND   dnz_chr_id = p_hdr_id
                    ) okllc,
                    okc_k_items okic,
                    mtl_system_items_b msic,
                    mtl_item_categories micc,
                    mtl_categories_b mcc,
                    mtl_category_sets mcsc,
                    mtl_categories_tl mctc
                WHERE
                    msic.organization_id = 14354
                    AND   msic.inventory_item_id = okic.object1_id1
                    AND   okic.cle_id = okllc.cle_id
                    AND   msic.inventory_item_id = micc.inventory_item_id
                    AND   micc.category_id = mcc.category_id
                    AND   micc.category_set_id = mcsc.category_set_id
                    AND   mcsc.category_set_name = 'PROVISIONING_GROUP'
                    AND   micc.category_id = mctc.category_id
                    AND   mctc.language = 'US'
                    AND   micc.organization_id = 14354
                    AND   oklc.dnz_chr_id = p_hdr_id
                    AND   okllc.cle_id = oklc.id
                    AND   ROWNUM = 1;

        END;

        return(l_service_group);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_migration_servicegroup;

    FUNCTION get_aso_servicegroup (
        p_line_id IN NUMBER
    ) RETURN VARCHAR2 AS
        l_service_group   VARCHAR2(10);
    BEGIN
        SELECT
            substr(mctc.description,instr(mctc.description,'-') + 1)
        INTO
            l_service_group
        FROM
            aso_quote_lines_all aqlc,
            mtl_system_items_b msic,
            mtl_item_categories micc,
            mtl_categories_b mcc,
            mtl_category_sets mcsc,
            mtl_categories_tl mctc,
            (
                SELECT
                    c_ext_attr1,
                    inventory_item_id
                FROM
                    ego_mtl_sy_items_ext_vl
                WHERE
                    attr_group_id = 48084
                    AND   organization_id = 14354
            ) emsv
        WHERE
            msic.organization_id = 14354
            AND   msic.inventory_item_id = (
                SELECT
                    inventory_item_id
                FROM
                    aso_quote_lines_all
                WHERE
                    quote_line_id = nvl(aqlc.attribute6,aqlc.quote_line_id)
            )
            AND   msic.inventory_item_id = micc.inventory_item_id
            AND   micc.category_id = mcc.category_id
            AND   micc.category_set_id = mcsc.category_set_id
            AND   mcsc.category_set_name = 'PROVISIONING_GROUP'
            AND   micc.category_id = mctc.category_id
            AND   mctc.language = 'US'
            AND   micc.organization_id = 14354
            AND   emsv.inventory_item_id (+) = msic.inventory_item_id
            AND   aqlc.quote_line_id = p_line_id
            AND   ROWNUM = 1;

        return(l_service_group);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_aso_servicegroup;

    FUNCTION get_incremental_properties (
        p_chr_id IN NUMBER
    ) RETURN VARCHAR2 AS

        CURSOR c_get_incre_properties IS SELECT DISTINCT
            mc.segment1 AS incremental_property
                                         FROM
            bom_inventory_components_v bom_component,
            bom_bill_of_materials_v bom,
            mtl_system_items_b mts,
            mtl_categories mc,
            mtl_item_categories mic,
            okc_k_headers_all_b okh,
            okc_k_lines_b okl,
            okc_k_items oki
                                         WHERE
            bom.bill_sequence_id = bom_component.bill_sequence_id
            AND   bom.assembly_item_id = (
                SELECT
                    k.inventory_item_id
                FROM
                    csi_item_instances k
                WHERE
                    to_number(oki.object1_id1) = k.instance_id
            )
            AND   oki.cle_id = okl.id
            AND   okl.cle_id IS NOT NULL
            AND   oki.jtot_object1_code = 'OKX_CUSTPROD'
            AND   okh.id = okl.dnz_chr_id
            AND   okh.id = p_chr_id
            AND   mts.inventory_item_id = bom_component.component_item_id
            AND   mts.organization_id = bom.organization_id
            AND   mic.organization_id = 14354
            AND   mts.organization_id = mic.organization_id
            AND   mc.category_id = mic.category_id
            AND   mic.category_set_id = 1100026004
            AND   mic.inventory_item_id = mts.inventory_item_id
            AND   mc.segment1 IS NOT NULL
            AND   nvl(bom_component.disable_date,SYSDATE + 1) > SYSDATE
        UNION
        SELECT DISTINCT
            mc.segment1 AS incremental_property
        FROM
            mtl_system_items_b mts,
            mtl_categories mc,
            mtl_item_categories mic,
            okc_k_headers_all_b okh,
            okc_k_lines_b okl,
            okc_k_items oki
        WHERE
            okh.id = okl.dnz_chr_id
            AND   okh.id = p_chr_id
            AND   okl.cle_id IS NULL
            AND   oki.cle_id = okl.id
            AND   oki.jtot_object1_code = 'OKX_SERVICE'
            AND   mts.inventory_item_id = oki.object1_id1
            AND   mic.organization_id = 14354
            AND   mts.organization_id = mic.organization_id
            AND   mc.category_id = mic.category_id
            AND   mic.category_set_id = 1100026004
            AND   mic.inventory_item_id = mts.inventory_item_id
            AND   mc.segment1 IS NOT NULL
        ORDER BY
            1;

        l_result   VARCHAR2(500);
    BEGIN
        FOR l_get_incre_properties IN c_get_incre_properties LOOP
            l_result := l_result
            || '|'
            || l_get_incre_properties.incremental_property;
        END LOOP;

        l_result := rtrim(ltrim(l_result,'|'),'|');
        return(l_result);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_incremental_properties;

    FUNCTION get_bus_event_xml (
        p_header_id      IN NUMBER,
        p_sub_id         IN VARCHAR2,
        p_tas_or_email   IN VARCHAR,
        p_line_ids       IN VARCHAR2 DEFAULT NULL
    ) RETURN XMLTYPE AS

        l_order_str              XMLTYPE;
        l_tas_or_email           VARCHAR2(10);
        l_order_number           VARCHAR2(200);
        l_seq_number             NUMBER;
        l_line_id                oe_order_lines_all.line_id%TYPE;
        l_source_name            VARCHAR2(300);
        l_onboarding_count       NUMBER;
        l_line_ids_changed_flg   VARCHAR2(10);
        l_split_line_ids         VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_final_line_ids         VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_final_sub_id           VARCHAR2(2000);
    BEGIN
        l_line_ids_changed_flg := 'N';
        BEGIN
    /* Bug 19582378 - No OPERATIONTYPE is defined for ORDERNUMBER: 122330*/
            SELECT
                ol.line_id
            INTO
                l_line_id
            FROM
                oe_order_lines_all ol,
                oe_order_price_attribs op
            WHERE
                ol.header_id = p_header_id
                AND   op.header_id = ol.header_id
                AND   op.line_id = ol.line_id
                AND   (
                    (
                        ( p_sub_id IS NOT NULL )
                        AND   ( op.pricing_attribute92 = p_sub_id )
                    )
                    OR    ( p_sub_id IS NULL )
                )
                AND   op.pricing_attribute92 IS NOT NULL
                AND   EXISTS (
                    SELECT
                        1
                    FROM
                        wf_item_activity_statuses s,
                        wf_process_activities p
                    WHERE
                        s.process_activity = p.instance_id
                        AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                        AND   s.item_type = 'OEOL'
                        AND   s.item_key = TO_CHAR(ol.line_id)
                )
                AND   NOT EXISTS (
                    SELECT
                        1
                    FROM
                        oe_order_lines_all
                    WHERE
                        line_id = ol.line_id
                        AND   flow_status_code IN (
                            'CLOSED',
                            'CANCELLED'
                        )
                )
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
    /* This exception block is to handle OAE Order whose Subscription ID is always NULL*/
    /*and op.pricing_attribute92 is NOT NULL      -- Bug 19582378 - No OPERATIONTYPE is defined for ORDERNUMBER: 122330*/
                SELECT
                    ol.line_id
                INTO
                    l_line_id
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs op
                WHERE
                    ol.header_id = p_header_id
                    AND   op.header_id = ol.header_id
                    AND   op.line_id = ol.line_id
                    AND   (
                        (
                            ( p_sub_id IS NOT NULL )
                            AND   ( op.pricing_attribute92 = p_sub_id )
                        )
                        OR    ( p_sub_id IS NULL )
                    )
                    AND   EXISTS (
                        SELECT
                            1
                        FROM
                            wf_item_activity_statuses s,
                            wf_process_activities p
                        WHERE
                            s.process_activity = p.instance_id
                            AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                            AND   s.item_type = 'OEOL'
                            AND   s.item_key = TO_CHAR(ol.line_id)
                    )
                    AND   NOT EXISTS (
                        SELECT
                            1
                        FROM
                            oe_order_lines_all
                        WHERE
                            line_id = ol.line_id
                            AND   flow_status_code IN (
                                'CLOSED',
                                'CANCELLED'
                            )
                    )
                    AND   ROWNUM = 1;

        END;
  /* Assign this to temp list*/

        l_split_line_ids := p_line_ids;
  /*- TODO*/
  /*--- Ident*/
  /*---*/
  /*---*/
  /* Split and get back the temp list*/
        split_prepare_split_lines(p_header_id,p_sub_id,l_split_line_ids,l_line_ids_changed_flg);
  /* if the line has been changed by split process ,then assign it back to final_list*/
        IF
            l_line_ids_changed_flg = 'Y'
        THEN
            l_final_line_ids := l_split_line_ids;
            l_final_sub_id := NULL;
            l_line_id := trim(substr(l_final_line_ids,1,instr(l_final_line_ids,',') - 1) );

        ELSE
            l_final_line_ids := p_line_ids;
            l_final_sub_id := p_sub_id;
        END IF;

        IF
            p_line_ids IS NOT NULL OR l_line_ids_changed_flg = 'Y'
        THEN
            l_order_str := get_payload(p_header_id => p_header_id,p_line_id => l_line_id,p_sub_id => l_final_sub_id,p_line_ids => l_final_line_ids,request_source => nvl(p_tas_or_email
,'GSI') );
        ELSE
            l_order_str := get_payload(p_header_id => p_header_id,p_line_id => l_line_id,p_sub_id => p_sub_id,request_source => nvl(p_tas_or_email,'GSI') );
        END IF;

        RETURN l_order_str;
  /*end if;*/
    EXCEPTION
        WHEN OTHERS THEN
  /* ravelarde*/
            g_context_name2 := 'Exception in get_bus_event_xml';
            g_context_id := p_header_id;
            p_error_code := sqlcode;
            p_error_message := sqlerrm;
  /*insert_log(g_audit_message,1,g_module,g_context_name2,NULL,l_order_data);*/
            insert_error(p_error_code,p_error_message,g_module,g_context_name2,g_context_id,errbuf);
  /* ravelarde*/
            RETURN NULL;
            RAISE;
    END get_bus_event_xml;

    PROCEDURE tas_cpq_grp_process (
        p_header_id        IN NUMBER,
        p_operation_type   IN VARCHAR2,
        p_trx_id           OUT NOCOPY NUMBER,
        p_request_source   IN VARCHAR2 DEFAULT 'GSI'
    ) IS

        CURSOR omtasgrp IS SELECT
            v.provisioning_group,
            v.item_value,
            v.dependency dependency,
            v.rule_group_id consolidated_grp
                           FROM
            apxiimd.misimd_tas_consolidation_rules v
                           WHERE
            v.enabled = 'Y';

        l_transaction_id   NUMBER;
        l_commit           VARCHAR2(1) := 'Y';
  /* swaramac introduced for bug# 24798142 */
    BEGIN
        SELECT
            misimd_om_tas_grouping_trans.NEXTVAL
        INTO
            l_transaction_id
        FROM
            dual;

        INSERT INTO misimd_om_tas_groups_tbl (
            transaction_id,
            header_id,
            line_id,
            ordered_item,
            subscription_id,
            fulfillment_set,
            service_grp,
            service_seq,
            status,
            date_time,
            co_term_sub_id
        )
            ( SELECT
                l_transaction_id,
                oh.header_id,
                ol.line_id,
                ol.ordered_item,
                op.pricing_attribute92,
                oes.set_name fulfillment_set,
                substr(oes.set_name,1,instr(oes.set_name,'-') - 1) service_group,
                DECODE(instr(oes.set_name,'-'),0,-999,substr(oes.set_name,instr(oes.set_name,'-') + 1) ),
                'AWAIT_PROVISIONING',
                SYSDATE,
                op.pricing_attribute85
              FROM
                oe_order_lines_all ol,
                oe_order_price_attribs op,
                oe_sets oes,
                oe_line_sets sln,
                oe_order_headers_all oh
              WHERE
                1 = 1
                AND   oes.set_id = sln.set_id
                AND   oes.set_type = 'FULFILLMENT_SET'
                AND   sln.line_id = ol.service_reference_line_id
                AND   ol.header_id = oh.header_id
                AND   op.line_id = ol.service_reference_line_id
                AND   op.header_id = oh.header_id
                AND   ol.item_type_code = 'SERVICE'
                AND   op.pricing_attribute94 IN (
                    'ONBOARDING',
                    'PILOT_ONBOARDING'
                )
                AND   oh.header_id = p_header_id
                AND   (
                    misont_cloud_pub2.is_oae(oh.header_id) <> 'Y'
                    AND   op.pricing_attribute92 IS NOT NULL
                )
                AND   (
                    p_request_source = 'GSI'
                    AND   EXISTS (
                        SELECT
                            1
                        FROM
                            wf_item_activity_statuses s,
                            wf_process_activities p
                        WHERE
                            s.process_activity = p.instance_id
                            AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                            AND   s.item_type = 'OEOL'
                            AND   s.item_key = TO_CHAR(ol.line_id)
                    )
                    AND   NOT EXISTS (
                        SELECT
                            1
                        FROM
                            oe_order_lines_all
                        WHERE
                            line_id = ol.line_id
                            AND   flow_status_code IN (
                                'CLOSED',
                                'CANCELLED'
                            )
                    )
                    OR    p_request_source <> 'GSI'
                )
            );
  /* ravelard,Bug 23721476 begin Jul 15th,2016*/
  /* swaramac enhanced for bug# 24798142,Jan 23 2017*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'INSERT_MISIMD_OM_TAS_GROUPS_TBL'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;

        IF
            l_commit = 'Y'
        THEN
            COMMIT;
        END IF;
  /* ravelard,end Jul 15th,2016*/
  /* end swaramac enhanced for bug# 24798142,Jan 23 2017*/
        UPDATE misimd_om_tas_groups_tbl
            SET
                co_term_sub_id = NULL
        WHERE
            (
                misont_cloud_pub2.is_subscription_tas_enabled(subscription_id) <> 'Y'
                OR    misont_cloud_pub2.get_order_line_info(line_id,'IS_SERVICE_TAS_ENABLED') <> 'Y'
            )
            AND   transaction_id = l_transaction_id;
  /* ravelard,Bug 23721476 begin Jul 15th,2016*/
  /* swaramac enhanced for bug# 24798142,Jan 23 2017*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'SET_COTERM_SUB_ID'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;

        IF
            l_commit = 'Y'
        THEN
            COMMIT;
        END IF;
  /* ravelard,end Jul 15th,2016*/
  /* end swaramac enhanced for bug# 24798142,Jan 23 2017*/
        updatetransaction(l_transaction_id,p_request_source);
        p_trx_id := l_transaction_id;
    END tas_cpq_grp_process;

    FUNCTION get_cd_rate (
        p_trans_curr_code IN VARCHAR2
    ) RETURN NUMBER IS
        l_conversion_rate   NUMBER;
    BEGIN
        SELECT
            conversion_rate
        INTO
            l_conversion_rate
        FROM
            gl_daily_rates
        WHERE
            conversion_type = '1022'
            AND   from_currency = p_trans_curr_code
            AND   to_currency = 'CD'
            AND   conversion_date = trunc(SYSDATE);

        return(l_conversion_rate);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_cd_rate;
-- This is common Function for CMRB,Payload Gen and OMNotify TAS/SPS

    FUNCTION get_payload (
        p_header_id        IN NUMBER,
        p_sub_id           IN VARCHAR2,
        p_line_id          IN NUMBER,
        request_source     IN VARCHAR2 DEFAULT 'GSI',
        p_operation_type   IN VARCHAR2 DEFAULT NULL,
        p_line_ids         IN VARCHAR2 DEFAULT NULL
    ) RETURN XMLTYPE IS

        l_order_str                     XMLTYPE;
        l_tas_or_email                  VARCHAR2(10);
        l_order_number                  VARCHAR2(200);
        l_seq_number                    NUMBER;
        l_line_id                       oe_order_lines_all.line_id%TYPE;
        l_sps_live                      VARCHAR2(10);
        l_store_flag                    VARCHAR2(5);
        l_sub_id                        VARCHAR2(100);
        l_opc_customer_name             VARCHAR2(500);
        l_is_metered                    VARCHAR2(2);
        l_metered_count                 NUMBER;
        l_is_tas_enabled                VARCHAR2(20);
        l_order_detail                  VARCHAR2(2000);
  --120.60 CY15 Sprint 4
        l_public_sector                 VARCHAR2(20);
        l_pilot_crp                     VARCHAR2(20);
        l_licensed_to                   VARCHAR2(20);
        l_dedicated_commute             VARCHAR2(300);
  --for cmrb flow
        l_ordernumber                   VARCHAR2(200);
        l_headerid                      NUMBER;
        l_coterm                        VARCHAR2(500);
  /*Bug 21755374 - Code fix to include co-term sub id in TAS payload*/
        l_order_type                    VARCHAR2(60);
        l_order_source                  VARCHAR2(100);
        l_customer_type                 VARCHAR2(20);
  -- 16.1 Changes Jan 2016 release
        l_pod_type                      VARCHAR2(20);
        l_reuse_gsi_pod                 VARCHAR2(2);
        l_hcm_flag                      VARCHAR2(1) := 'N';
        l_operation_type                VARCHAR2(200);
        l_customers_crm_choice          VARCHAR2(100);
        l_data_center_region            VARCHAR2(100);
        l_admin_first_name              VARCHAR2(100);
        l_admin_last_name               VARCHAR2(100);
        l_admin_email                   VARCHAR2(100);
  -- 16.1 Changes Jan 2016 Release
  --16.2 changes feb 2016 release
        l_language_pack                 VARCHAR2(300);
  --16.3 changes march 2016 release
        l_customer_code                 VARCHAR2(300);
        l_consulting_methodology        VARCHAR2(300);
        l_is_spm_enabled                VARCHAR2(2);
        l_tas_condition                 VARCHAR2(300);
        l_send_to_tas_flg               VARCHAR2(10);
  --16.4 changes
        l_data_center_country           VARCHAR2(100);
        l_source_name                   VARCHAR2(10);
        l_onboarding_count              NUMBER;
        lcpq_ordernumber                VARCHAR2(200);
        l_cpq_line_id                   NUMBER;
        l_cpq_flag                      VARCHAR2(10);
        l_sup_pay_flg                   VARCHAR2(10) := 'N';
        l_err                           VARCHAR2(3000);
  ----16.4
        l_split_line_id                 NUMBER;
        l_split_ordernumber             VARCHAR2(200);
        l_split_flag                    VARCHAR2(10);
  -- SUP_PAY
        l_sup_pay_ordernumber           VARCHAR2(200);
        l_sup_pay_ff_set                VARCHAR2(200);
        l_sup_pay_attr_char3            VARCHAR2(200);
        l_sup_pay_provisioned_sub_id    VARCHAR2(200);
  --- paygen co_term
        l_remove_paygen_co_term_flg     VARCHAR2(2) := 'N';
  /*Bug 22518475*/
        l_coterm_subscription_enabled   VARCHAR2(2);
        l_subs_tas_enabled              VARCHAR2(2);
  /*Bug 22518475*/
  /*16:07*/
        l_cloud_account_name            VARCHAR2(240);
        l_cloud_account_id              VARCHAR2(240);
        l_is_auto_close                 VARCHAR2(10);
        l_associate_sub_id              VARCHAR2(240);
  /*16:07*/
        l_test_opc                      VARCHAR2(3000);
        l_order_listpgroup              VARCHAR2(3000);
        l_subid_listpgroup              VARCHAR2(3000);
  /* PROMOTION_AMOUNT*/
        l_promotion_amount              VARCHAR2(240);
        l_promotion_duration            VARCHAR2(240);
        l_is_promotion                  VARCHAR2(1) := 'N';
        l_rate_card_id                  VARCHAR2(240);
        l_ravello_token_id              VARCHAR2(240);
        l_partner_id                    VARCHAR2(240);
        l_current_gsi_group             VARCHAR2(240);
        l_po_number                     NUMBER;
  /*16.12*/
        l_ncer_zone                     VARCHAR2(240);
        l_ncer_type                     VARCHAR2(240);
  --SPM-8834
        l_pricing_model                 VARCHAR2(240) := NULL;
        l_cloud_replacement_code        VARCHAR2(240) := NULL;
        l_replace_all_service           VARCHAR2(240) := NULL;
        l_tas_operationrule_flg         VARCHAR2(240) := NULL;
        l_partner_trxn_type             VARCHAR2(240);
        l_end_cust_acct_no              VARCHAR2(240);
        l_end_cust_pri_name             VARCHAR2(1000);
        l_end_cust_eng_name             VARCHAR2(1000);
        l_trx_partner_name              VARCHAR2(2000);
        l_provisioning_system           VARCHAR2(240);
        l_temp_prov_line_ids            VARCHAR2(32767) := NULL;
        l_gsi_pod_type_part_exists      NUMBER;
        l_gsi_pod_type_master_switch    VARCHAR2(20) := 'N';
  -- JULY2017
        l_order_contains_erp            VARCHAR2(240) := NULL;
    BEGIN
        l_order_detail := NULL;
        l_line_id := p_line_id;
        SELECT
            value
        INTO
            l_test_opc
        FROM
            nls_session_parameters
        WHERE
            parameter = 'NLS_NUMERIC_CHARACTERS';
  /*START - Bug 23481512 - RCA Midmarket HCM product required to be provisioned with ERP Pod Type
  BEGIN
  SELECT MISONT_CLOUD_PUB2.is_hcm_midmarket_line(p_line_id) INTO l_hcm_flag from dual;
  IF l_hcm_flag = 'Y' THEN
  l_pod_type := 'GSI';
  END IF;
  EXCEPTION
  WHEN OTHERS THEN
  l_pod_type := NULL;
  END;
  END - Bug 23481512 - RCA Midmarket HCM product required to be provisioned with ERP Pod Type*/

        BEGIN
            FOR i IN (
                SELECT DISTINCT
                    misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') service_group,
                    op.pricing_attribute92 sub_id
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs op
                WHERE
                    ol.header_id = p_header_id
                    AND   op.header_id = ol.header_id
                    AND   ol.item_type_code = 'SERVICE'
                    AND   op.line_id = ol.line_id
                    AND   misont_cloud_pub2.get_order_line_info(ol.line_id,'IS_SERVICE_TAS_ENABLED') = 'Y'
            ) LOOP
                IF
                    ( i.service_group IS NOT NULL AND i.sub_id IS NOT NULL )
                THEN
                    IF
                        l_order_detail IS NULL
                    THEN
                        l_order_detail := i.service_group
                        || '|'
                        || i.sub_id;
                    ELSE
                        l_order_detail := l_order_detail
                        || '|'
                        || i.service_group
                        || '|'
                        || i.sub_id;
                    END IF;

                END IF;
            END LOOP;
        END;
  --16.1 changes Jan 2016 release

        BEGIN
            SELECT
                additional_column3,
                additional_column5,
                additional_column6,
                additional_column7,
                additional_column9,
                additional_column14,
                additional_column15,
                nvl(additional_column16,'N'),
                additional_column27,
                additional_column28,
                additional_column35,
                additional_column37,
                additional_column42
            INTO
                l_customers_crm_choice,l_admin_first_name,l_admin_last_name,l_customer_code,l_consulting_methodology,l_cloud_account_name,l_cloud_account_id,l_is_auto_close
,l_ravello_token_id,l_partner_trxn_type,l_ncer_type,l_ncer_zone,l_pricing_model
            FROM
                (
                    SELECT
                        additional_column1,
                        additional_column2,
                        additional_column3,
                        additional_column5,
                        additional_column6,
                        additional_column7,
                        additional_column9,
                        additional_column14,
                        additional_column15,
                        additional_column16,
                        additional_column27,
                        additional_column28,
                        additional_column35,
                        additional_column37,
                        additional_column42
                    FROM
                        misont_order_line_attribs_ext
                    WHERE
                        header_id = p_header_id
                )
            WHERE
                ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                l_pod_type := NULL;
                l_reuse_gsi_pod := NULL;
                g_audit_message := 'exception in pod type'
                || sqlerrm;
                insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,NULL);
        END;

        BEGIN
            SELECT
                upper(ot.name)
            INTO
                l_order_type
            FROM
                oe_transaction_types_tl ot,
                oe_order_headers_all oh
            WHERE
                oh.order_type_id = ot.transaction_type_id
                AND   oh.header_id = p_header_id
                AND   ot.language = 'US';

            SELECT
                os.name
            INTO
                l_order_source
            FROM
                oe_order_sources os,
                oe_order_headers_all oh
            WHERE
                oh.order_source_id = os.order_source_id
                AND   oh.header_id = p_header_id;

            l_customer_type := NULL;
            IF
                ( instr(l_order_type,'CLOUD') > 0 AND upper(l_order_source) = 'INTERNAL' OR ( upper(l_ncer_type) LIKE '%INTERNAL%' AND upper(l_ncer_zone) LIKE '%INTERNAL%' ) )
      /*16.12 changes for NCER*/
            THEN
                l_customer_type := 'INTERNAL';
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                IF
                    ( upper(l_ncer_type) LIKE '%INTERNAL%' AND upper(l_ncer_zone) LIKE '%INTERNAL%' )
      /*16.12 changes for NCER*/
                THEN
                    l_customer_type := 'INTERNAL';
                ELSE
                    l_customer_type := NULL;
                END IF;
        END;
  ---
  --SPM_ENABLED_NEED_OR_NOT Lookup
  ---

        BEGIN
            SELECT
                lookup_value
            INTO
                l_is_spm_enabled
            FROM
                misimd_intf_lookup
            WHERE
                application = 'GSI-TAS CLOUD BRIDGE'
                AND   lookup_code = 'SPM_ENABLED_NEED_OR_NOT';

        EXCEPTION
            WHEN no_data_found THEN
                l_is_spm_enabled := 'N';
        END;
  ---
  --TAS_ENABLED_CONDITION Lookup
  ---

        BEGIN
            SELECT
                upper(nvl(TRIM(lookup_value),'N') )
            INTO
                l_send_to_tas_flg
            FROM
                misimd_intf_lookup
            WHERE
                application = 'GSI-TAS CLOUD BRIDGE'
                AND   lookup_code = 'SEND_EXTSITE_TO_TAS';

        EXCEPTION
            WHEN OTHERS THEN
                l_send_to_tas_flg := 'N';
        END;

        BEGIN
            SELECT
                nvl(upper(TRIM(lookup_value) ),'X')
            INTO
                l_tas_condition
            FROM
                misimd_intf_lookup
            WHERE
                application = 'GSI-TAS CLOUD BRIDGE'
                AND   lookup_code = 'TAS_ENABLED_CONDITION';

        EXCEPTION
            WHEN OTHERS THEN
                l_tas_condition := NULL;
        END;
  ---- Get Order Number

        IF
            p_line_ids IS NOT NULL
        THEN
            SELECT
                to_number(regexp_substr(p_line_ids,'[^,]+',1,level) )
            INTO
                l_line_id
            FROM
                dual
            CONNECT BY
                level <= 1;

        END IF;

        BEGIN
            l_cpq_flag := 'N';
    --IF  Upper(l_order_source)='CPQ' THEN
            IF
                upper(l_order_source) IN (
                    'CPQ',
                    'IEIGHT'
                ) AND p_line_ids IS NOT NULL
            THEN
                l_cpq_flag := 'Y';
                SELECT
                    misont_cloud_pub2.get_line_cloud_attr(l_line_id,'ORDER_SEQ_NUM')
                INTO
                    lcpq_ordernumber
                FROM
                    dual;

            END IF;
    ---------16.4 START

            IF
                request_source = 'SPLIT_SEND' AND p_line_ids IS NOT NULL
            THEN
                l_split_flag := 'Y';
                SELECT
                    misont_cloud_pub2.get_line_cloud_attr(l_line_id,'ORDER_SEQ_NUM')
                    || 's'
                    || line_number
                INTO
                    l_split_ordernumber
                FROM
                    oe_order_lines_all
                WHERE
                    instr(p_line_ids,line_id) > 0
                    AND   line_id = l_line_id;

            END IF;
    --- 16.4 END
    -- Supplement PayLoad

            IF
                request_source = 'SUP_PAY' AND p_line_id IS NOT NULL
            THEN
                l_sup_pay_flg := 'Y';
      -- get child provisioning group,by validating parent line
                SELECT
                    upper(nvl(mri.attr_char3,'SUP_PAY') )
                    || '-'
                    || pol.line_number,
                    upper(mri.attr_char3)
                INTO
                    l_sup_pay_ff_set,l_sup_pay_attr_char3
                FROM
                    oe_order_price_attribs oep,
                    oe_order_lines_all ol,
                    ego_mtl_sy_items_ext_vl emi,
                    oe_order_lines_all pol,
                    mtl_related_items mri
                WHERE
                    pol.line_id = l_line_id
                    AND   ol.header_id = oep.header_id
                    AND   ol.header_id = pol.header_id
                    AND   ol.line_id = oep.line_id
                    AND   oep.pricing_attribute94 IN (
                        'ONBOARDING',
                        'PILOT_ONBOARDING'
                    )
                    AND   emi.attr_group_id = (
                        SELECT
                            attr_group_id
                        FROM
                            ego_attr_groups_v
                        WHERE
                            attr_group_name = 'MISEGO_UNIFIED_OFF_TYPE'
                    )
                    AND   ol.inventory_item_id = emi.inventory_item_id
                    AND   emi.organization_id = 14354
                    AND   emi.language = 'US'
                    AND   upper(emi.c_ext_attr1) = 'UNIFIED PROVISION-ABLE'
                    AND   mri.organization_id = 14354
                    AND   mri.reciprocal_flag = 'N'
                    AND   mri.inventory_item_id = ol.inventory_item_id
                    AND   pol.inventory_item_id = mri.related_item_id
                    AND   ( mri.attr_char3 ) IS NOT NULL
                    AND   mri.relationship_type_id IN (
                        SELECT
                            lookup_code
                        FROM
                            fnd_lookup_values
                        WHERE
                            language = userenv('LANG')
                            AND   lookup_type = 'MTL_RELATIONSHIP_TYPES'
                            AND   upper(meaning) LIKE 'UNIFIED%'
                    )
                    AND   EXISTS (
                        SELECT
                            1
                        FROM
                            wf_item_activity_statuses s,
                            wf_process_activities p
                        WHERE
                            s.process_activity = p.instance_id
                            AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                            AND   s.item_type = 'OEOL'
                            AND   s.item_key = TO_CHAR(oep.line_id)
                    )
                    AND   NOT EXISTS (
                        SELECT
                            1
                        FROM
                            oe_order_lines_all
                        WHERE
                            line_id = oep.line_id
                            AND   flow_status_code IN (
                                'CLOSED',
                                'CANCELLED'
                            )
                    );

                SELECT
                    misont.misont_subscription_id_s1.nextval
                INTO
                    l_sup_pay_provisioned_sub_id
                FROM
                    dual;

                SELECT
                    misont_cloud_pub2.get_line_cloud_attr(l_line_id,'ORDER_SEQ_NUM')
                    || 'sup'
                    || ol.line_number
                    || 's'
                    || l_sup_pay_provisioned_sub_id,
                    oh.order_number
                INTO
                    l_sup_pay_ordernumber,l_ordernumber
                FROM
                    oe_order_lines_all ol,
                    oe_order_headers_all oh
                WHERE
                    ol.line_id = l_line_id
                    AND   ol.header_id = oh.header_id;

                UPDATE apxiimd.misimd_supplement_payload
                    SET
                        provisioned_sub_id = l_sup_pay_provisioned_sub_id,
                        order_number = l_ordernumber
                WHERE
                    line_id = l_line_id;

            END IF;
    ---- Get Order Number

        END;
  --for cmrb flow

        BEGIN
            SELECT
                oe_order_headers_s.NEXTVAL
            INTO
                l_headerid
            FROM
                dual;

            l_ordernumber := TO_CHAR(l_headerid);
        EXCEPTION
            WHEN no_data_found THEN
                l_ordernumber := p_header_id
                || p_header_id;
        END;

        BEGIN
            SELECT
                COUNT(*)
            INTO
                l_metered_count
            FROM
                oe_order_lines_all ol
            WHERE
                ol.header_id = p_header_id
                AND   ol.item_type_code = 'SERVICE'
                AND   misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                    SELECT
                        lookup_value
                    FROM
                        misimd_intf_lookup
                    WHERE
                        lookup_code = 'PAYLOAD_GROUP'
                        AND   application = 'GSI-TAS CLOUD BRIDGE'
                        AND   enabled = 'Y'
                )
      -- Added as part of 15.3 Solar
                ;

            IF
                l_metered_count > 0
            THEN
                l_is_metered := 'Y';
            ELSE
                l_is_metered := 'N';
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        SELECT
            upper(description)
        INTO
            l_sps_live
        FROM
            fnd_lookup_values
        WHERE
            lookup_type = 'MISONT_CLOUD_SPS_LIVE'
            AND   lookup_code = 'SPS_LIVE'
            AND   language = 'US';

        BEGIN
    --120.60 CY15 Sprint 4
            SELECT
                op.pricing_attribute98,
                op.pricing_attribute92,
                op.pricing_attribute48,
                op.pricing_attribute68,
                op.pricing_attribute91,
                op.pricing_attribute99,
                DECODE(instr(oh.sales_channel_code,'PARTNER'),0,'CUSTOMER','PARTNER'),
                upper(op.pricing_attribute50)
            INTO
                l_store_flag,l_sub_id,l_public_sector,l_pilot_crp,l_admin_email,l_data_center_region,l_licensed_to,l_cloud_replacement_code
            FROM
                oe_order_price_attribs op,
                oe_order_headers_all oh
            WHERE
                op.header_id = p_header_id
                AND   op.header_id = oh.header_id
                AND   op.line_id = l_line_id --for cpq changes p_line_id       --Bug 19263774
      --- and pricing_attribute98 is not null
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                NULL;
                RAISE;
        END;
  -- 2-JUL-2015 changes

        BEGIN
    /*Bug 22762417 */
            IF
                p_line_ids IS NOT NULL
            THEN
                SELECT DISTINCT
                    dedicated_compute_capacity,
                    additional_column26
                INTO
                    l_dedicated_commute,l_partner_id
                FROM
                    misont_order_line_attribs_ext
                WHERE
                    header_id = p_header_id
                    AND   dedicated_compute_capacity IS NOT NULL
                    AND   line_id IN (
                        SELECT
                            to_number(regexp_substr(p_line_ids,'[^,]+',1,level) ) AS lineid
                        FROM
                            dual
                        CONNECT BY
                            level <= regexp_count(p_line_ids,'[^,]+')
                    )
                    AND   ROWNUM = 1;

            ELSE
                SELECT DISTINCT
                    dedicated_compute_capacity,
                    additional_column26
                INTO
                    l_dedicated_commute,l_partner_id
                FROM
                    misont_order_line_attribs_ext
                WHERE
                    header_id = p_header_id
                    AND   dedicated_compute_capacity IS NOT NULL;

            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_dedicated_commute := NULL;
                l_partner_id := NULL;
        END;
  -- 2-JUL-2015 change ends
  /*Start Bug 21755374 - Code fix to include co-term sub id in TAS payload*/

        BEGIN
            IF
                p_line_ids IS NOT NULL
            THEN
                SELECT
                    pricing_attribute85
                INTO
                    l_coterm
                FROM
                    (
                        SELECT DISTINCT
                            pricing_attribute85
                        FROM
                            oe_order_price_attribs
                        WHERE
                            header_id = p_header_id
                            AND   line_id IN (
                                SELECT
                                    to_number(regexp_substr(p_line_ids,'[^,]+',1,level) ) AS lineid
                                FROM
                                    dual
                                CONNECT BY
                                    level <= regexp_count(p_line_ids,'[^,]+')
                            )
                    )
                WHERE
                    ROWNUM = 1;

            ELSE
                SELECT
                    pricing_attribute85
                INTO
                    l_coterm
                FROM
                    (
                        SELECT DISTINCT
                            pricing_attribute85
                        FROM
                            oe_order_price_attribs
                        WHERE
                            header_id = p_header_id
                    )
                WHERE
                    ROWNUM = 1;

            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_coterm := NULL;
        END;
  --- Paygen co-term removal
  -- for closed orders ,OM would have populated co_term
  ---while generating from paygen,remove the co_term if exists in same order
  --

        IF
            request_source = 'PAYGEN'
        THEN
            BEGIN
                SELECT
                    DECODE(COUNT(1),0,'N','Y')
                INTO
                    l_remove_paygen_co_term_flg
                FROM
                    oe_order_price_attribs
                WHERE
                    header_id = p_header_id
                    AND   pricing_attribute92 = l_coterm;

            EXCEPTION
                WHEN OTHERS THEN
                    l_remove_paygen_co_term_flg := 'N';
            END;
        END IF;
  /*Close Bug 21755374 - Code fix to include co-term sub id in TAS payload*/

        BEGIN
            IF
                l_sup_pay_flg = 'Y'
            THEN
                SELECT
                    nvl(misont_cloud_pub2.is_tas_live(l_sup_pay_attr_char3),'N')
                INTO
                    l_is_tas_enabled
                FROM
                    dual;

            ELSE
                SELECT
                    misont_cloud_pub2.get_order_line_info(l_line_id,'IS_SERVICE_TAS_ENABLED')
                INTO
                    l_is_tas_enabled
                FROM
                    dual;

            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_is_tas_enabled := NULL;
        END;
  --16.1 changes for Jan 2016 release

        BEGIN
            SELECT
                misont_cloud_pub2.get_payload_cloud_oper_type(p_header_id,l_sub_id)
            INTO
                l_operation_type
            FROM
                dual;

            IF
                ( l_operation_type IS NULL AND request_source = 'PAYGEN' )
            THEN
                SELECT
                    pricing_attribute94
                INTO
                    l_operation_type
                FROM
                    (
                        SELECT
                            pricing_attribute94
                        FROM
                            oe_order_price_attribs
                        WHERE
                            header_id = p_header_id
                            AND   line_id = p_line_id
                    )
                WHERE
                    ROWNUM = 1;

            END IF;
    --16.4 start
    -- Split package is sending the New operation type based on RULE

            IF
                l_split_flag = 'Y'
            THEN
                l_operation_type := p_operation_type;
            END IF;
    --16.4 start
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
  --SPM-8834

        BEGIN
            FOR cur_rec IN (
                SELECT
                    upper(tas_operation_type) tas_operation_type,
                    supersede
                FROM
                    apxiimd.misimd_tas_operation_rule
                WHERE
                    pricing_model = nvl2(l_pricing_model,'NOT NULL','NULL')
                    AND   gsi_operation_type = l_operation_type
                    AND   (
                        supersede = 'NA'
                        OR    supersede = DECODE(l_cloud_replacement_code,'SUPERSEDE','Y','N')
                    )
                    AND   SYSDATE BETWEEN nvl(effective_start_date,SYSDATE - 1) AND nvl(effective_end_date,SYSDATE + 1)
                    AND   enabled = 'Y'
            ) LOOP
      -- TAS OPERATIOn RULE
                l_operation_type := cur_rec.tas_operation_type;
                l_tas_operationrule_flg := 'Y';
                IF
                    cur_rec.supersede <> 'NA'
                THEN
                    l_replace_all_service := cur_rec.supersede;
                ELSE
                    l_replace_all_service := NULL;
                END IF;

            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
  -- New Requirement ,GSI/OM-TAS metered subscription payload changes discussed in 07/31/2014 meeting

        BEGIN
            SELECT
                opc_customer_name
            INTO
                l_opc_customer_name
            FROM
                misont_order_line_attribs_ext
            WHERE
                header_id = p_header_id
                AND   line_id = l_line_id
                AND   ROWNUM = 1;
    -- Paygen needs this to be nulled

            IF
                ( l_operation_type = 'ONBOARDING' AND request_source = 'PAYGEN' )
            THEN
                l_opc_customer_name := NULL;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                l_opc_customer_name := NULL;
        END;
  -- Bug 25476997 - LANGUAGE_CODES missing for Taleo Business Edition payloads for Orders from CPQ

        BEGIN
            SELECT
                additional_column8
            INTO
                l_language_pack
            FROM
                misont_order_line_attribs_ext
            WHERE
                header_id = p_header_id
                AND   subscription_id = l_sub_id
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                l_language_pack := NULL;
                g_audit_message := 'exception in l_language_pack '
                || sqlerrm;
                insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,NULL);
        END;
  --16.1 changes for Jan 2016 release
  --16.2 changes for Feb 2016 release,Pod Type addition 16.3 release

        BEGIN
    /*IF condition added for Bug 23481512*/
    -- IF l_hcm_flag <> 'Y' THEN
    --  SELECT ADDITIONAL_COLUMN8 ,
    --pod_type            ,
            SELECT
                reuse_existing
      --  INTO l_language_pack ,
      --l_pod_type     ,
            INTO
                l_reuse_gsi_pod
            FROM
                (
      --  SELECT ADDITIONAL_COLUMN8 ,
      --additional_column1 pod_type ,
                    SELECT
                        DECODE(upper(nvl(additional_column2,'NA') ),'YES','Y','Y','Y','NO','N','N','N',NULL) reuse_existing
                    FROM
                        misont_order_line_attribs_ext
                    WHERE
                        header_id = p_header_id
                        AND   subscription_id = l_sub_id
                )
            WHERE
                ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                l_reuse_gsi_pod := NULL;
        END;

        BEGIN
    -- END IF;
    /*END - IF condition added for Bug 23481512*/
    /*  1.    SET POD Type = GSI    --- Reuse Flag = Y when POD Type = GSI for all above cases.
    Onboarding Orders
    Either [ERP] or [HCM + CRM]
    2.      SET POD Type = NULL    ---- POD Type = NULL  Reuse Flag = Y
    Onboarding Orders
    Only HCM or CRM .
    3.  set POD Type = GSI and Reuse Flag = Y.
    Renewal Order HCM/CRM
    B85788 and B83865,+  [ CRM or ERP]
    */
            l_current_gsi_group := 'N';
            BEGIN
                SELECT
                    'Y'
                INTO
                    l_current_gsi_group
                FROM
                    dual
                WHERE
                    EXISTS (
                        SELECT
                            1
                        FROM
                            oe_order_lines_all ol,
                            oe_order_price_attribs op
                        WHERE
                            op.pricing_attribute92 = l_sub_id
                            AND   op.header_id = p_header_id
                            AND   op.line_id = ol.line_id
                            AND   misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') IN (
                                'HCM',
                                'ERP',
                                'CRM'
                            )
                    );

            EXCEPTION
                WHEN OTHERS THEN
                    l_current_gsi_group := 'N';
            END; --Need to clean this up to check only the Onboarding lines service group while setting Pod_type = GSI

            IF
                l_current_gsi_group = 'Y'
            THEN
                SELECT
                    LISTAGG(misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP'),
                    ',') WITHIN GROUP(
                    ORDER BY
                        ol.line_id
                    )
                INTO
                    l_order_listpgroup
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs oopa
                WHERE
                    ol.header_id = p_header_id
                    AND   ol.line_id = oopa.line_id
                    AND   ol.header_id = oopa.header_id
                    AND   pricing_attribute94 IN (
                        'ONBOARDING',
                        'RAMPED_ONBOARDING',
                        'RAMPED',
                        'PILOT_ONBOARDING'
                    );

                SELECT
                    LISTAGG(misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP'),
                    ',') WITHIN GROUP(
                    ORDER BY
                        ol.line_id
                    )
                INTO
                    l_subid_listpgroup
                FROM
                    oe_order_lines_all ol,
                    oe_order_price_attribs oopa
                WHERE
                    ol.header_id = p_header_id
                    AND   oopa.pricing_attribute92 = l_sub_id
                    AND   ol.line_id = oopa.line_id
                    AND   ol.header_id = oopa.header_id
                    AND   pricing_attribute94 IN (
                        'ONBOARDING',
                        'RAMPED_ONBOARDING',
                        'RAMPED',
                        'PILOT_ONBOARDING'
                    );
      --l_order_contains_erp

                BEGIN
                    IF
                        ( regexp_instr(l_subid_listpgroup,'HCM') > 0 OR regexp_instr(l_subid_listpgroup,'CRM') > 0 )
                    THEN
                        IF
                            ( regexp_instr(l_order_listpgroup,'ERP') > 0 )
                        THEN
                            l_order_contains_erp := 'Y';
                        END IF;

                    ELSE
                        l_order_contains_erp := NULL;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_order_contains_erp := NULL;
                END;

                BEGIN
                    SELECT
                        COUNT(1)
                    INTO
                        l_gsi_pod_type_part_exists
                    FROM
                        oe_order_lines_all ol
                    WHERE
                        ol.header_id = p_header_id
                        AND   ol.ordered_item IN (
                            SELECT
                                tab1.rule_value
                            FROM
                                apxiimd.misimd_om_tas_rule_values tab1,
                                apxiimd.misimd_om_tas_ruleset tab2
                            WHERE
                                tab1.ruleset_id = tab2.ruleset_id
                                AND   tab2.ruleset_name = 'POD_TYPE'
                                AND   tab1.enabled = 'Y'
                        );

                EXCEPTION
                    WHEN OTHERS THEN
                        l_gsi_pod_type_part_exists := 0;
                END;

                BEGIN
                    SELECT
                        lookup_value
                    INTO
                        l_gsi_pod_type_master_switch
                    FROM
                        oss_intf_user.misimd_intf_lookup
                    WHERE
                        application = 'MISIMD_TAS_CLOUD_WF'
                        AND   component = 'GSI_POD_TYPE_MASTER_SWITCH'
                        AND   upper(lookup_code) = 'GSI_POD_TYPE_MASTER_SWITCH'
                        AND   enabled = 'Y';

                EXCEPTION
                    WHEN OTHERS THEN
                        l_gsi_pod_type_master_switch := 'N';
                END;

                IF
                    l_operation_type IN (
                        'ONBOARDING',
                        'RAMPED_ONBOARDING',
                        'RAMPED',
                        'PILOT_ONBOARDING'
                    )
                THEN
                    IF
                        ( regexp_instr(l_order_listpgroup,'HCM') > 0 OR regexp_instr(l_order_listpgroup,'CRM') > 0 OR ( regexp_instr(l_order_listpgroup,'ERP') > 0 ) ) OR ( l_gsi_pod_type_part_exists
> 0 ) OR ( l_gsi_pod_type_master_switch = 'Y' )
                    THEN
                        l_pod_type := 'GSI';
                        l_reuse_gsi_pod := 'Y';
                    ELSIF ( ( regexp_instr(l_order_listpgroup,'HCM') > 0 AND regexp_instr(l_order_listpgroup,'ERP') = 0 AND regexp_instr(l_order_listpgroup,'CRM') = 0 ) OR ( regexp_instr(l_order_listpgroup
,'CRM') > 0 AND regexp_instr(l_order_listpgroup,'ERP') = 0 AND regexp_instr(l_order_listpgroup,'HCM') = 0 ) ) THEN
                        l_pod_type := NULL;
                        l_reuse_gsi_pod := 'Y';
                    END IF;
                END IF;

            ELSE
                l_pod_type := NULL;
                l_reuse_gsi_pod := NULL;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
    --  l_language_pack := NULL;
                l_pod_type := NULL;
                l_reuse_gsi_pod := NULL;
                g_audit_message := 'exception after l_language_pack '
                || sqlerrm;
                insert_log(g_audit_message,1,g_module,g_context_name2,g_context_id,NULL);
        END;
  --16.4 changes Split Data Center,as the values would be null prior 16.4 this can be allowed as null tags wont be sent

        IF
            l_data_center_region = 'OPC-GLOBAL'
        THEN
            l_data_center_country := NULL;
        ELSIF instr(l_data_center_region,'-') > 0 THEN
            l_data_center_country := trim(substr(l_data_center_region,instr(l_data_center_region,'-') + 1) );

            l_data_center_region := trim(substr(l_data_center_region,1,instr(l_data_center_region,'-') - 1) );

        ELSE
            l_data_center_country := NULL;
        END IF;
  --l_split_flag   := 'N'; -- use this to disbale the Split and test the Non-split
  /*Bug 22518475 - RCA:BPEL should not sent to TAS coterm subscription ID when this is not enabled  */

        BEGIN
            SELECT
                misont_cloud_pub2.is_subscription_tas_enabled(l_coterm)
            INTO
                l_coterm_subscription_enabled
            FROM
                dual;

            SELECT
                misont_cloud_pub2.is_subscription_tas_enabled(l_sub_id)
            INTO
                l_subs_tas_enabled
            FROM
                dual;

        EXCEPTION
            WHEN no_data_found THEN
                l_coterm_subscription_enabled := 'Y';
                l_subs_tas_enabled := 'Y';
        END;
  /*End Bug 22518475*/
  ---
  --PROMOTION_DURATION  -- PROMOTION_AMOUNT

        BEGIN
            IF
                p_line_ids IS NOT NULL
            THEN
                FOR c1 IN (
                    SELECT DISTINCT
                        la.additional_column20 promotion_amount,
                        ( trunc(ool.service_end_date) - trunc(ool.service_start_date) + 1 ) promotion_duration
                    FROM
                        oe_order_price_attribs pa,
                        misont_order_line_attribs_ext la,
                        oe_order_lines_all ool
                    WHERE
                        pa.header_id = p_header_id
                        AND   pa.line_id IN (
                            SELECT
                                to_number(regexp_substr(p_line_ids,'[^,]+',1,level) ) AS lineid
                            FROM
                                dual
                            CONNECT BY
                                level <= regexp_count(p_line_ids,'[^,]+')
                        )
                        AND   pa.pricing_attribute29 IS NOT NULL
                        AND   pa.pricing_attribute29 = la.line_id
                        AND   la.header_id = p_header_id
                        AND   item_type_code = 'SERVICE'
                        AND   ool.header_id = p_header_id
                        AND   ool.line_id = pa.pricing_attribute29
                ) LOOP
                    l_promotion_amount := c1.promotion_amount;
                    l_promotion_duration := c1.promotion_duration;
                    l_is_promotion := 'Y';
                END LOOP;

            ELSE
      -- do header level
                FOR c1 IN (
                    SELECT DISTINCT
                        la.additional_column20 promotion_amount,
                        ( trunc(ool.service_end_date) - trunc(ool.service_start_date) + 1 ) promotion_duration
                    FROM
                        oe_order_price_attribs pa,
                        misont_order_line_attribs_ext la,
                        oe_order_lines_all ool
                    WHERE
                        pa.header_id = p_header_id
                        AND   pa.pricing_attribute29 IS NOT NULL
                        AND   pa.pricing_attribute29 = la.line_id
                        AND   la.header_id = p_header_id
                        AND   item_type_code = 'SERVICE'
                        AND   ool.header_id = p_header_id
                        AND   ool.line_id = pa.pricing_attribute29
                ) LOOP
                    l_promotion_amount := c1.promotion_amount;
                    l_promotion_duration := c1.promotion_duration;
                    l_is_promotion := 'Y';
                END LOOP;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_is_promotion := '';
        END;
  --
  ---
  /*16.12 MSP Changes
  1. For MSP default the Sold To customer as Transacting Partner.
  2. For Reseller or VAD default the Bill To Customer as "Transacting Partner"
  WIP
  */

        IF
            ( l_partner_trxn_type IS NOT NULL AND upper(l_partner_trxn_type) = 'MSP' )
        THEN
            BEGIN
                SELECT
                    nvl(cust_party.organization_name_phonetic,cust_party.party_name) "ENG_PARTY_NAME"
                INTO
                    l_trx_partner_name
                FROM
                    oe_order_headers_all oh,
                    hz_cust_accounts cust_acct,
                    hz_parties cust_party
                WHERE
                    oh.header_id = p_header_id
                    AND   cust_acct.cust_account_id = sold_to_org_id
                    AND   cust_acct.party_id = cust_party.party_id;

            EXCEPTION
                WHEN OTHERS THEN
                    l_trx_partner_name := NULL;
            END;
        ELSIF ( l_partner_trxn_type IS NOT NULL AND upper(l_partner_trxn_type) IN (
            'RESELLER',
            'VAD'
        ) ) THEN
            BEGIN
                SELECT
                    nvl(cust_party.organization_name_phonetic,cust_party.party_name) "ENG_PARTY_NAME"
                INTO
                    l_trx_partner_name
                FROM
                    oe_order_headers_all oh,
                    hz_cust_accounts cust_acct,
                    hz_parties cust_party
                WHERE
                    oh.header_id = p_header_id
                    AND   cust_acct.cust_account_id = invoice_to_org_id
                    AND   cust_acct.party_id = cust_party.party_id;

            EXCEPTION
                WHEN OTHERS THEN
                    l_trx_partner_name := NULL;
            END;
        END IF;

        BEGIN
    -- misont_cloud_pub2.get_order_header_info will take 'CUST_ACC_NUM','CUST_NAME','CUST_ENG_NAME' as new parameter and return
    -- End Customer Account Number (New) ,End Customer Primary Name (New) ,End Customer English Name (New) respectively
            l_end_cust_acct_no := misont_cloud_pub2.get_order_header_info(p_header_id,'CUST_ACC_NUM');
            l_end_cust_pri_name := misont_cloud_pub2.get_order_header_info(p_header_id,'CUST_NAME');
            l_end_cust_eng_name := misont_cloud_pub2.get_order_header_info(p_header_id,'CUST_ENG_NAME');
        EXCEPTION
            WHEN OTHERS THEN
                l_end_cust_acct_no := NULL;
                l_end_cust_pri_name := NULL;
                l_end_cust_eng_name := NULL;
        END;
  /*16.12 MSP Changes END*/
  /*16.12 SPS Move Changes */

        BEGIN
            IF
                ( p_line_ids IS NOT NULL )
            THEN
                l_provisioning_system := get_provisioning_system(NULL,NULL,p_line_ids);
            ELSIF ( p_sub_id IS NOT NULL ) THEN
                SELECT
                    LISTAGG(oep.line_id,
                    ',') WITHIN GROUP(
                    ORDER BY
                        oep.pricing_attribute92,
                        oep.line_id
                    ) line_ids
                INTO
                    l_temp_prov_line_ids
                FROM
                    oe_order_price_attribs oep
                WHERE
                    pricing_attribute92 = p_sub_id
                    AND   header_id = p_header_id
                    AND   EXISTS (
                        SELECT
                            1
                        FROM
                            wf_item_activity_statuses s,
                            wf_process_activities p
                        WHERE
                            s.process_activity = p.instance_id
                            AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                            AND   s.item_type = 'OEOL'
                            AND   s.item_key = TO_CHAR(oep.line_id)
                    )
                    AND   oep.line_id NOT IN (
                        SELECT
                            line_id
                        FROM
                            oe_order_lines_all
                        WHERE
                            line_id = oep.line_id
                            AND   flow_status_code IN (
                                'CLOSED',
                                'CANCELLED'
                            )
                    )
                GROUP BY
                    oep.pricing_attribute92,
                    DECODE(oep.pricing_attribute94,'RAMPED_ONBOARDING','RAMPED','RAMPED_UPDATE','RAMPED','RAMPED_EXTENSION','RAMPED',oep.pricing_attribute94);

                IF
                    ( l_temp_prov_line_ids IS NOT NULL )
                THEN
                    l_provisioning_system := get_provisioning_system(NULL,NULL,l_temp_prov_line_ids);
                END IF;

            ELSIF ( p_header_id IS NOT NULL ) THEN
                SELECT
                    LISTAGG(oep.line_id,
                    ',') WITHIN GROUP(
                    ORDER BY
                        oep.pricing_attribute92,
                        oep.line_id
                    ) line_ids
                INTO
                    l_temp_prov_line_ids
                FROM
                    oe_order_price_attribs oep
                WHERE
                    header_id = p_header_id
                    AND   EXISTS (
                        SELECT
                            1
                        FROM
                            wf_item_activity_statuses s,
                            wf_process_activities p
                        WHERE
                            s.process_activity = p.instance_id
                            AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                            AND   s.item_type = 'OEOL'
          --- and s.end_date is not null
                            AND   s.item_key = TO_CHAR(oep.line_id)
                    )
                    AND   oep.line_id NOT IN (
                        SELECT
                            line_id
                        FROM
                            oe_order_lines_all
                        WHERE
                            line_id = oep.line_id
                            AND   flow_status_code IN (
                                'CLOSED',
                                'CANCELLED'
                            )
                    );
      /*GROUP BY oep.pricing_attribute92 ,
      DECODE(oep.pricing_attribute94,'RAMPED_ONBOARDING','RAMPED','RAMPED_UPDATE','RAMPED','RAMPED_EXTENSION','RAMPED',
      oep.pricing_attribute94);*/

                IF
                    ( l_temp_prov_line_ids IS NOT NULL )
                THEN
                    l_provisioning_system := get_provisioning_system(NULL,NULL,l_temp_prov_line_ids);
                END IF;

            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                    SELECT
                        lookup_value
                    INTO
                        l_provisioning_system
                    FROM
                        oss_intf_user.misimd_intf_lookup
                    WHERE
                        application = 'PROVISIONING_SYSTEM'
                        AND   component = 'PROVISIONING_SYSTEM'
                        AND   upper(lookup_code) = 'PROVISIONING_SYSTEM'
                        AND   enabled = 'Y';

                EXCEPTION
                    WHEN OTHERS THEN
                        l_provisioning_system := 'SPS';
                END;
        END;
  /*16.12 SPS Move Changes END*/

        SELECT
            XMLELEMENT(
                "OrderHeader",
                XMLATTRIBUTES(
                    oh.header_id AS "HEADERID",oh.org_id AS "ORGANIZATIONID",
                        CASE
                            WHEN request_source = 'SPM_CMRB_FLOW' THEN l_ordernumber
                            WHEN upper(l_order_source) IN(
                                'CPQ','IEIGHT'
                            )
                                 AND l_split_flag = 'N' THEN lcpq_ordernumber
                            WHEN l_sup_pay_flg = 'Y'              THEN l_sup_pay_ordernumber
                            WHEN l_split_flag = 'Y'               THEN l_split_ordernumber
                            WHEN(
                                (p_sub_id IS NOT NULL)
                                OR(p_sub_id <> '')
                                OR(p_line_ids IS NOT NULL)
                            ) THEN misont_cloud_pub2.get_line_cloud_attr(l_line_id,'ORDER_SEQ_NUM')
                            ELSE TO_CHAR(oh.order_number)
                        END
                    AS "ORDERNUMBER",sys_extract_utc(to_timestamp(TO_CHAR(oh.ordered_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "ORDERDATE",cust_party.party_name
AS "CUSTNAME",cust_acct.account_number AS "CUSTACCTNUMBER",cust_party.party_id AS "PARTYID",
                        CASE
                            WHEN trunc(SYSDATE) >= (
                                SELECT
                                    MIN(service_start_date) processing_date
                                FROM
                                    oe_order_lines_all
                                WHERE
                                    header_id = oh.header_id
                                    AND   service_start_date IS NOT NULL
                                    AND   flow_status_code NOT IN(
                                        'CLOSED','CANCELLED'
                                    )
                            ) THEN NULL
                            ELSE(
                                SELECT
                                    MIN(service_start_date) processing_date
                                FROM
                                    oe_order_lines_all
                                WHERE
                                    header_id = oh.header_id
                                    AND   service_start_date IS NOT NULL
                                    AND   flow_status_code NOT IN(
                                        'CLOSED','CANCELLED'
                                    )
                            )
                        END
                    AS "PROCESSINGDATE",misimd_tas_cloud_wf.is_metered_subscription(l_line_id) AS "METERED_SUBSCRIPTION", (
                        CASE
                            WHEN request_source = 'SPM_CMRB_FLOW'             THEN 'CMRB'
                            WHEN l_split_flag = 'Y'
                                 OR(misont_cloud_pub2.is_oae(oh.header_id) <> 'Y') THEN l_operation_type
                            WHEN misont_cloud_pub2.is_oae(oh.header_id) = 'Y' THEN 'EXTENSION'
                        END
                    ) AS "OPERATIONTYPE",nvl( (
                        SELECT
                            csn.name
                        FROM
                            csi_t_txn_line_details csi,
                            csi_t_transaction_lines csi2,
                            oe_order_lines_all sl,
                            csi_systems_tl csn
                        WHERE
                            nvl(sl.service_reference_line_id,sl.line_id) = csi2.source_transaction_id
                            AND   csi.transaction_line_id = csi2.transaction_line_id
                            AND   sl.header_id = oh.header_id
                            AND   csi.csi_system_id = csn.system_id
                            AND   csn.language = 'US'
                            AND   ROWNUM = 1
                    ), (
                        SELECT
                            op.pricing_attribute95
                        FROM
                            oe_order_price_attribs op
                        WHERE
                            op.header_id = oh.header_id
                            AND   op.pricing_attribute95 IS NOT NULL --BUG 19404116 - Taleo Business Edition | MSCIInc | Order #: 8832092 - NO CSI Number
                            AND   ROWNUM = 1
                    ) ) AS "CSI"

    /*Bug 21755374 - Code fix to include co-term sub id in TAS payload*/
    /*Bug 22518475 - RCA:BPEL should not sent to TAS coterm subscription ID when this is not enabled  */
                 /* , (
                        CASE
                            WHEN(l_operation_type = 'ONBOARDING'
                                AND l_remove_paygen_co_term_flg = 'N'
                                AND( (l_coterm_subscription_enabled = 'Y'
                                    ) OR(l_is_tas_enabled = 'N'
                                        OR     l_subs_tas_enabled = 'N'
                                    )
                                )
                            ) THEN l_coterm
                            WHEN l_operation_type = 'ONBOARDING'
                            AND l_remove_paygen_co_term_flg = 'Y'
                            THEN NULL
                        END
                    ) AS "COTERMSUBSID" */
                ),
    /*Bug 22518475 - RCA:BPEL should not sent to TAS coterm subscription ID when this is not enabled  */
    /*Bug 21755374 - Code fix to include co-term sub id in TAS payload*/
                XMLCOLATTVAL(oh.header_id AS "HEADERID"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'PARTY_ID') AS "TCA_PARTY_ID"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'BUYER_SSO_LOGIN') AS "BUYER_SSO_USERNAME"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'BUYER_FIRST_NAME') AS "BUYER_FIRST_NAME"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'BUYER_LAST_NAME') AS "BUYER_LAST_NAME"),
                XMLCOLATTVAL(nvl(l_admin_first_name,misont_cloud_pub2.get_order_header_info(oh.header_id,'ADMIN_FIRST_NAME') ) AS "AA_FIRST_NAME"),
                XMLCOLATTVAL(nvl(l_admin_last_name,misont_cloud_pub2.get_order_header_info(oh.header_id,'ADMIN_LAST_NAME') ) AS "AA_LAST_NAME"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'ENG_PARTY_NAME') AS "CUSTOMER_ENGLISH_NAME"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'SALESREPS') AS "SALES_REPS"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'SALES_CHANNEL') AS "SALES_CHANNEL"),
                XMLCOLATTVAL(l_customer_type AS "CUSTOMER_TYPE"),
                XMLCOLATTVAL(cust_party.party_name AS "CUSTOMER_PRIMARY_NAME"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_ADDRESS') AS "CUSTOMER_ADDRESS"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_CITY') AS "CUSTOMER_CITY"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_STATE') AS "CUSTOMER_STATE"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_ZIP') AS "CUSTOMER_ZIP"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'CUSTOMER_COUNTRY') AS "CUSTOMER_COUNTRY_CODE"),
                    CASE
                        WHEN l_operation_type = 'PILOT_ONBOARDING' THEN XMLCOLATTVAL('Y' AS "IS_PILOT")
                    END,
                    CASE
                        WHEN l_operation_type = 'PILOT_CONVERSION' THEN XMLCOLATTVAL('N' AS "IS_PILOT")
                    END,
                    CASE
                        WHEN(
                            l_operation_type = 'CMRB'
                            OR request_source = 'SPM_CMRB_FLOW'
                        ) THEN XMLCOLATTVAL('Y' AS "IS_CMRB")
                    END,
                    CASE
                        WHEN(
                            l_operation_type <> 'CMRB'
                            AND request_source <> 'SPM_CMRB_FLOW'
                        ) THEN XMLCOLATTVAL(misont_cloud_pub2.get_payload_info(oh.header_id,l_sub_id,'INCREMENTAL_PROPERTIES') AS "$$INCREMENTAL_PROPERTIES$$")
                    END,
                    CASE
                        WHEN(
                            l_operation_type <> 'CMRB'
                            AND request_source <> 'SPM_CMRB_FLOW'
                        ) THEN XMLCOLATTVAL('|' AS "$$FS$$")
                    END,
                    CASE
                        WHEN request_source = 'SPM_CMRB_FLOW' THEN XMLCOLATTVAL(l_ordernumber AS "$$OM_ORDER_NUMBER$$")
                        ELSE XMLCOLATTVAL(oh.order_number AS "$$OM_ORDER_NUMBER$$")
                    END,
                    CASE
                        WHEN request_source = 'SPM_CMRB_FLOW' THEN XMLCOLATTVAL('CMRB' AS "$$OM_OPERATION_TYPE$$")
                        ELSE XMLCOLATTVAL(l_operation_type AS "$$OM_OPERATION_TYPE$$")
                    END,
                    CASE
                        WHEN l_operation_type = 'MIGRATION' THEN XMLCOLATTVAL('Y' AS "MIGRATE_SUBSCRIPTIONS")
                    END,
                XMLCOLATTVAL(oh.attribute3 AS "REKEY_TYPE"),
                    CASE
                        WHEN(
                            l_operation_type = 'PILOT_ONBOARDING'
                            OR l_operation_type = 'ONBOARDING'
                            OR l_operation_type = 'RAMPED_ONBOARDING'
                            OR l_operation_type = 'RAMPED'
                        ) THEN XMLCOLATTVAL(misont_cloud_pub2.get_addi_line_info(l_line_id,'OVERAGE_FLAG') AS "OVERAGEOPTED")
                    END,
                XMLCOLATTVAL(misont_cloud_pub2.get_addi_line_info(l_line_id,'OVERAGE_THRESHOLD') AS "OVERAGE_THRESHOLD"),
                XMLCOLATTVAL(misont_cloud_pub2.get_addi_line_info(l_line_id,'OVERAGE_BILLING_TERM') AS "OVERAGE_BILLING_TERM"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'IS_AUTO_RENEW') AS "IS_AUTO_RENEWED"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_header_info(oh.header_id,'IS_CREATED_BY_AUTO_RENEW') AS "$$ORDER_CREATED_BY_AUTO_RENEWAL$$"),
                    CASE
                        WHEN l_tas_operationrule_flg = 'Y'
                             AND l_replace_all_service IS NOT NULL THEN XMLCOLATTVAL(l_replace_all_service AS "$$REPLACE_ALL_SERVICE_COMPONENTS$$")
                        WHEN(
                            (l_operation_type IN(
                                'EXTENSION','OAE_CONVERSION','PILOT_CONVERSION','RAMPED_EXTENSION','CHANGE OF SERVICE'
                            ) )
                            OR(misont_cloud_pub2.is_oae(oh.header_id) = 'Y')
                            AND(l_sps_live = 'YES')
                        ) THEN XMLCOLATTVAL('Y' AS "$$REPLACE_ALL_SERVICE_COMPONENTS$$")
                    END,
                    CASE
                        WHEN misont_cloud_pub2.is_oae(oh.header_id) = 'Y' THEN XMLCOLATTVAL('Y' AS "OAE_CONVERSION")
                    END,
                    CASE
                        WHEN l_sps_live = 'YES' THEN XMLCOLATTVAL(NULL AS "PRODUCT_RELEASE_VERSION")
                    END,
                    CASE
                        WHEN l_sps_live = 'YES' THEN XMLCOLATTVAL(NULL AS "ADDITIONAL_INSTANCE_PRODUCT_RELEASE_VERSION") -- Added as part of 15.3 Solar
                    END,
                    CASE
                        WHEN l_sps_live = 'YES' THEN XMLCOLATTVAL(NULL AS "ENVIRONMENT_LANGUAGES")
                    END,
                XMLCOLATTVAL(l_language_pack AS "LANGUAGE_CODES"),
                    CASE
                        WHEN l_sps_live = 'YES' THEN XMLCOLATTVAL(NULL AS "IDM_TYPE")
                    END,
                    CASE
                        WHEN l_sps_live = 'YES' THEN XMLCOLATTVAL(NULL AS "ENVIRONMENT_COUNTRY")
                    END,
                    CASE
                        WHEN l_sps_live = 'YES' THEN XMLCOLATTVAL(NULL AS "TAGS")
                    END,
                    CASE
                        WHEN l_sps_live = 'YES'
                             AND upper(l_data_center_region) <> nvl(l_tas_condition,'X') THEN XMLCOLATTVAL(l_is_tas_enabled AS "IS_TAS_ENABLED")
                        WHEN l_sps_live = 'YES'
                             AND upper(l_data_center_region) = upper(l_tas_condition)
                             AND l_send_to_tas_flg = 'Y' THEN XMLCOLATTVAL(l_is_tas_enabled AS "IS_TAS_ENABLED")
                        WHEN l_sps_live = 'YES'
                             AND upper(l_data_center_region) = upper(l_tas_condition)
                             AND l_send_to_tas_flg = 'N' THEN XMLCOLATTVAL('N' AS "IS_TAS_ENABLED")
                    END
              /* ,CASE
                    WHEN(l_sps_live = 'YES'
                        AND nvl(l_sup_pay_flg,'N') = 'Y'
                    ) THEN XMLCOLATTVAL(l_is_tas_enabled AS "IS_SUBSCRIPTION_ENABLED")
                    WHEN(l_sps_live = 'YES'
                        AND upper(l_data_center_region) = l_tas_condition
                        AND l_send_to_tas_flg = 'N'
                    ) THEN XMLCOLATTVAL('N' AS "IS_SUBSCRIPTION_ENABLED")
                    WHEN(l_sps_live = 'YES'
                        AND misont_cloud_pub2.is_oae(oh.header_id) = 'Y'
                    ) THEN XMLCOLATTVAL('Y' AS "IS_SUBSCRIPTION_ENABLED")
                    WHEN(l_sps_live = 'YES'
                        AND l_store_flag = 'Y'
                    ) THEN XMLCOLATTVAL(nvl(
                        misont_cloud_pub2.is_subscription_tas_enabled(l_sub_id)
                   ,'N'
                    ) AS "IS_SUBSCRIPTION_ENABLED")
                    WHEN(l_sps_live = 'YES'
                        AND(l_store_flag <> 'Y'
                            OR l_store_flag IS NULL
                        )
                    ) THEN XMLCOLATTVAL(nvl(
                        misont_cloud_pub2.is_subscription_tas_enabled(l_sub_id)
                   ,'N'
                    ) AS "IS_SUBSCRIPTION_ENABLED")
                END */,
                XMLCOLATTVAL(misont_cloud_pub2.get_order_line_info(l_line_id,'ACTIVATOR_EMAIL') AS "ACTIVATOR_EMAIL_ADDRESSES"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_line_info(l_line_id,'ACTIVATION_BY') AS "ACTIVATED_BY"),
                XMLCOLATTVAL(misont_cloud_pub2.get_order_line_info(l_line_id,'TAS_NOTIFICATION_RECIPIENT') AS "TAS_NOTIFICATION_RECIPIENTS"),
                    CASE
                        WHEN request_source = 'SPM_CMRB_FLOW' THEN XMLCOLATTVAL('SPM' AS "$$ORDER_SOURCE$$")
		    /* Added for CLOUD PORTAL ORDER */
			WHEN l_order_source = 'CLOUDPORTAL' THEN XMLCOLATTVAL('CLOUD_PORTAL' AS "$$ORDER_SOURCE$$")

                        ELSE XMLCOLATTVAL(DECODE(misont_cloud_pub2.get_order_header_info(oh.header_id,'ORDER_SOURCE'),'PARTNER_STORE','PARTNER_STORE',misont_cloud_pub2.get_order_header_info
(oh.header_id,'ORDER_SOURCE') ) AS "$$ORDER_SOURCE$$")
                    END,
                XMLCOLATTVAL(oh.transactional_curr_code AS "CLOUD_AMOUNT_CURRENCY"),
                    CASE
                        WHEN(
                            l_operation_type <> 'CMRB'
                            AND request_source <> 'SPM_CMRB_FLOW'
                        ) THEN XMLCOLATTVAL(misqp_cloud_prov_details.get_cd_rate(oh.transactional_curr_code) AS "CLOUD_AMOUNT_CURRENCY_TO_USD_MULTIPLIER")
                    END,
                XMLCOLATTVAL(l_opc_customer_name AS "OPC_ACCOUNT_NAME"),
                    CASE
                        WHEN(
                            l_is_metered = 'Y'
                            AND oh.attribute3 = 'MOCK'
                        ) THEN XMLCOLATTVAL('SITEMOCK' AS "SITE")
                    END,
                    CASE
                        WHEN(l_is_tas_enabled = 'Y') THEN XMLCOLATTVAL(l_order_detail AS "TAS_SUBSCRIPTIONS_IN_OM_ORDER")
                    END,
                    CASE
                        WHEN(l_dedicated_commute IS NOT NULL) THEN XMLCOLATTVAL(l_dedicated_commute AS "DEDICATED_COMPUTE_CAPACITY")
                    END,
                    CASE
                        WHEN l_operation_type = 'PILOT_ONBOARDING' THEN XMLCOLATTVAL(DECODE(l_pilot_crp,'N','PRODUCTION','CRP') AS "PILOT_TYPE")
                    END,
                    CASE
                        WHEN cust_party.attribute18 = 'Y' THEN XMLCOLATTVAL('PARTNER' AS "LICENSED_TO")
                    END,
                    CASE
                        WHEN nvl(cust_party.attribute18,'X') <> 'Y' THEN XMLCOLATTVAL('CUSTOMER' AS "LICENSED_TO")
                    END,
                    CASE
                        WHEN request_source = 'SPM_CMRB_FLOW' THEN XMLCOLATTVAL('SPM' AS "$$ORDER_PAYLOAD_SOURCE$$")
                    END,
                XMLCOLATTVAL(l_customers_crm_choice AS "CUSTOMERS_CRM_CHOICE"),
                    CASE
                        WHEN(l_pod_type IS NOT NULL) THEN XMLCOLATTVAL(l_pod_type AS "POD_TYPE")
                    END,
                    CASE
                        WHEN(l_reuse_gsi_pod IS NOT NULL) THEN XMLCOLATTVAL(l_reuse_gsi_pod AS "REUSE_EXISTING_GSI_POD")
                    END,
                    CASE
                        WHEN l_customer_code IS NOT NULL THEN XMLCOLATTVAL(l_customer_code AS customer_code)
                    END,
                    CASE
                        WHEN l_consulting_methodology IS NOT NULL THEN XMLCOLATTVAL(l_consulting_methodology AS consulting_methodology)
                    END,
                    CASE
                        WHEN l_data_center_country IS NOT NULL THEN XMLCOLATTVAL(l_data_center_country AS "DATA_CENTER_COUNTRY_ID")
                    END,
                  /*  CASE
                        WHEN l_cloud_account_name IS NOT NULL THEN XMLCOLATTVAL(l_cloud_account_name AS "CLOUD_ACCOUNT_NAME")
                    END,
                    CASE
                        WHEN l_cloud_account_id IS NOT NULL THEN XMLCOLATTVAL(l_cloud_account_id AS "CLOUD_ACCOUNT_ID")
                    END,*/
                    CASE
                        WHEN l_is_auto_close IS NOT NULL THEN XMLCOLATTVAL(l_is_auto_close AS "IS_AUTO_CLOSE")
                    END,
                    CASE
                        WHEN l_is_promotion = 'Y'
                             AND l_promotion_amount IS NOT NULL THEN XMLCOLATTVAL(l_promotion_amount AS "PROMOTION_AMOUNT")
                    END,
                    CASE
                        WHEN l_is_promotion = 'Y'
                             AND l_promotion_amount IS NOT NULL THEN XMLCOLATTVAL(l_promotion_duration AS "PROMOTION_DURATION")
                    END,
                    CASE
                        WHEN l_ravello_token_id IS NOT NULL THEN XMLCOLATTVAL(l_ravello_token_id AS "RAVELLO_TOKEN_ID")
                    END,
                    CASE
                        WHEN l_partner_id IS NOT NULL THEN XMLCOLATTVAL(l_partner_id AS "PARTNER_ID")
                    END,
                    CASE
                        WHEN oh.cust_po_number IS NOT NULL THEN XMLCOLATTVAL(oh.cust_po_number AS "PO_NUMBER")
                    END,
    /*16.12 changes*/
                    CASE
                        WHEN l_end_cust_acct_no IS NOT NULL THEN XMLCOLATTVAL(l_end_cust_acct_no AS "END_CUSTOMER_ACCOUNT_NUMBER")
                    END,
                    CASE
                        WHEN l_end_cust_pri_name IS NOT NULL THEN XMLCOLATTVAL(l_end_cust_pri_name AS "END_CUSTOMER_PRIMARY_NAME")
                    END,
                    CASE
                        WHEN l_end_cust_eng_name IS NOT NULL THEN XMLCOLATTVAL(l_end_cust_eng_name AS "END_CUSTOMER_ENGLISH_NAME")
                    END,
                    CASE
                        WHEN l_partner_trxn_type IS NOT NULL THEN XMLCOLATTVAL(upper(l_partner_trxn_type) AS "PARTNER_TRANSACTION_TYPE")
                    END,
                    CASE
                        WHEN l_trx_partner_name IS NOT NULL THEN XMLCOLATTVAL(l_trx_partner_name AS "TRANSACTING_PARTNER_NAME")
                    END,
                    CASE
                        WHEN l_provisioning_system IS NOT NULL THEN XMLCOLATTVAL(l_provisioning_system AS "PROVISIONING_SYSTEM")
                    END,
                    CASE
                        WHEN l_order_contains_erp IS NOT NULL THEN XMLCOLATTVAL(l_order_contains_erp AS "ORDER_CONTAINS_ERP")
                    END,
                (
                    SELECT
                        XMLELEMENT(
                            "OrderLines",
                            XMLAGG(XMLELEMENT(
                                "OrderLine",
                                XMLATTRIBUTES(
                                    ol.line_id AS "LINEID",
                                        CASE
                                            WHEN l_split_flag = 'Y' THEN l_operation_type
                                            ELSE DECODE(misont_cloud_pub2.is_oae(oh.header_id),'Y','EXTENSION',op.pricing_attribute94)
                                        END
                                    AS "LINE_OPERATION_TYPE",ol.service_reference_line_id AS "LICENSE_LINE_ID",oll.inventory_item_id AS "LICENSE_ITEM_ID",ol.orig_sys_line_ref AS "ORIGSYSLINEREF"
,ol.ordered_item AS "ORDEREDITEM",
                                        CASE
                                            WHEN nvl(l_sup_pay_flg,'N') = 'Y' THEN l_sup_pay_ff_set
                                            ELSE oes.set_name
                                        END
                                    AS "FULFILLMENT_SET",ol.inventory_item_id AS "ITEMID",ol.item_type_code AS "LINETYPE",misont_cloud_pub2.get_cloud_item_type(ol.ordered_item) AS "CLOUDORDERTYPE"
,
      /*16.1 changes sending null for @ mail ids*/DECODE(TRIM(op.pricing_attribute90),'@',NULL,TRIM(op.pricing_attribute90) ) AS "BUYEREMAILID",nvl(l_admin_email,DECODE(TRIM(op.pricing_attribute91),'@',NULL
,TRIM(op.pricing_attribute91) ) ) AS "SERVICEADMINEMAILID",
                                        CASE
                                            WHEN nvl(l_sup_pay_flg,'N') = 'Y' THEN l_sup_pay_provisioned_sub_id
                                            ELSE op.pricing_attribute92
                                        END
                                    AS "SUBSCRIPTIONID",DECODE(op.pricing_attribute96,'@',NULL,op.pricing_attribute96) AS "SYSTEMINTEGRATOREMAILID",op.pricing_attribute98 AS "STOREORDER",
      /*
      --16.1 changes sending null for @ mail ids
      -- Bug #19376501 Changes
      --nvl(op.pricing_attribute89,'N') AS "OVERAGE_ENABLED",
      */
                                        CASE
                                            WHEN l_operation_type LIKE '%ONBOARDING%'
                                                 OR op.pricing_attribute94 = 'RAMPED_ONBOARDING' THEN misont_cloud_pub2.get_addi_line_info(ol.line_id,'OVERAGE_FLAG')
                                            ELSE NULL
                                        END
                                    AS "OVERAGEOPTED",
      -- Bug #19376501 Changes
                                        CASE
                                            WHEN(op.pricing_attribute99 <> 'OPC-GLOBAL')
                                                 AND instr(op.pricing_attribute99,'-') > 0 THEN TRIM(substr(op.pricing_attribute99,1,instr(op.pricing_attribute99,'-') - 1) )
                                            ELSE op.pricing_attribute99
                                        END
                                    AS "DATACENTER",utl_i18n.escape_reference(regexp_replace(msi.description,'[^'
                                    || fnd_global.local_chr(32)
                                    || '-'
                                    || fnd_global.local_chr(127)
                                    || ']',' ') ) AS "ITEMDESC", (
                                        SELECT
                                            committed_quantity
                                        FROM
                                            misont_order_line_attribs_ext mole
                                        WHERE
                                            mole.line_id = ol.line_id
                                    ) AS "COMMITTED_QUANTITY", (
                                        SELECT
                                            committed_period
                                        FROM
                                            misont_order_line_attribs_ext mole
                                        WHERE
                                            mole.line_id = ol.line_id
                                    ) AS "COMMITTED_PERIOD", (
                                        SELECT
                                            committed_period_uom
                                        FROM
                                            misont_order_line_attribs_ext mole
                                        WHERE
                                            mole.line_id = ol.line_id
                                    ) AS "COMMITTED_PERIOD_UOM", (
                                        SELECT
                                            overage_policy_type
                                        FROM
                                            misont_order_line_attribs_ext mole
                                        WHERE
                                            mole.line_id = ol.line_id
                                    ) AS "OVERAGE_POLICY_TYPE",sys_extract_utc(to_timestamp(TO_CHAR(ol.service_start_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) AS "STARTDATE",
      /*  Release 16.03 - Mar 2016  for spm enabled flg*/
                                        CASE
                                            WHEN l_is_spm_enabled = 'Y' THEN misont_cloud_pub2.is_spm_eligible(to_number(ol.line_id) )
                                        END
                                    AS "IS_SPM_ENABLED",
                                        CASE
                                            WHEN
                                                CASE
                                                    WHEN l_split_flag = 'Y' THEN l_operation_type
                                                    ELSE op.pricing_attribute94
                                                END
                                            IN(
                                                'RAMPED_ONBOARDING','RAMPED_UPDATE','RAMPED_EXTENSION'
                                            ) THEN
          /* Bug fix for - 19604784 - Fusion HCM Order #: 8838021 - TAS Validation Failure ,End Dates issue at TAS*/ sys_extract_utc(to_timestamp(TO_CHAR(ol.service_end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') )
          /* Bug fix Ends for - 19604784 - Fusion HCM Order #: 8838021 - TAS Validation Failure ,End Dates issue at TAS*/
                                            WHEN(
                                                nvl(op.pricing_attribute97,'TERM') = 'M2M'
                                                AND
                                                CASE
                                                        WHEN l_split_flag = 'Y' THEN l_operation_type
                                                        ELSE op.pricing_attribute94
                                                    END
                                                IN(
                                                    'ONBOARDING','CHANGE OF SERVICE','UPDATE','PILOT_ONBOARDING','CMRB'
                                                )
                                            ) THEN NULL
                                            WHEN
                                                CASE
                                                    WHEN l_split_flag = 'Y' THEN l_operation_type
                                                    ELSE op.pricing_attribute94
                                                END
                                            IN(
                                                'ONBOARDING','EXTENSION','PILOT_CONVERSION','PILOT_ONBOARDING','INCONTRACT_EXTENSION','COMPLIANCE','MIGRATION','REPLENISH'
                                            ) THEN nvl(sys_extract_utc(to_timestamp(TO_CHAR(misont_cloud_pub2.get_subscription_enddate(ol.line_id),'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') )
,sys_extract_utc(to_timestamp(TO_CHAR(ol.service_end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') ) )
                                            WHEN
                                                CASE
                                                    WHEN l_split_flag = 'Y' THEN l_operation_type
                                                    ELSE op.pricing_attribute94
                                                END
                                            IN(
                                                'UPDATE','CHANGE OF SERVICE','CMRB','REFILL'
                                            ) THEN sys_extract_utc(to_timestamp(TO_CHAR(ol.service_end_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') )
                                        END
                                    AS "LINE_END_DATE",utl_i18n.escape_reference(regexp_replace(ol.user_item_description,'[^'
                                    || fnd_global.local_chr(32)
                                    || '-'
                                    || fnd_global.local_chr(127)
                                    || ']',' ') ) AS "USER_ITEM_DESCRIPTION",
                                        CASE
                                            WHEN(misont_cloud_pub2.get_hdr_cloud_operation_type(ol.header_id) LIKE '%RAMPED%')
                                                 OR(misont_cloud_pub2.get_payload_cloud_oper_type(ol.header_id,l_sub_id) LIKE '%RAMPED%')
                                                 OR(
                                                l_split_flag = 'Y'
                                                AND l_operation_type LIKE '%RAMPED%'
                                            ) THEN(
                                                SELECT
                                                    sys_extract_utc(to_timestamp(TO_CHAR(MAX(misont_cloud_pub2.get_subscription_enddate(rampon.line_id) ),'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') )
                                                FROM
                                                    oe_order_lines_all rampon,
                                                    oe_order_price_attribs rampattr
                                                WHERE
                                                    rampon.header_id = oh.header_id
                                                    AND   rampon.line_id = rampattr.line_id
                                                    AND   rampattr.pricing_attribute94 IN(
                                                        'RAMPED_ONBOARDING','RAMPED_EXTENSION',l_operation_type
                                                    )
                                                    AND   rampon.item_type_code = 'SERVICE'
                                            )
                                        END
                                    AS "HDR_END_DATE"
                                ),
                                (
                                    SELECT
                                        XMLAGG(XMLELEMENT(
                                            "LicenseItem",
                                            XMLATTRIBUTES(
                                                oll.ordered_item AS "LICENSE_ITEM",oll.item_type_code AS "LICENSE_LINE_TYPE",
                                                    CASE
                                                        WHEN nvl(l_sup_pay_flg,'N') = 'Y'
                                                             AND oll.item_type_code = 'STANDARD' THEN l_sup_pay_ff_set
                                                        ELSE oes.set_name
                                                    END
                                                AS "FULFILLMENT_SET"
                                            ),
                                                CASE
                                                    WHEN regexp_substr(get_provisioning_system(NULL,oll.line_id,NULL),'[^-]+',1,2) = 'M' THEN XMLCOLATTVAL(XMLCOLATTVAL(mc.segment1 AS name,
                                                    op.pricing_attribute3 AS value) AS properties,
                                                    XMLCOLATTVAL('PROVISIONED_PRODUCT' AS name,
                                                    misimd_tas_cloud_wf.check_provisioned_product(oll.inventory_item_id) AS value) AS properties,
                                                    XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                                    nvl(mc.attribute13,1) AS value) AS properties,
                                                    XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                                    utl_i18n.escape_reference(msi.description) AS value) AS properties,
                                                    XMLCOLATTVAL('IS_MANUAL' AS name,
                                                        CASE
                                                            WHEN regexp_substr(get_provisioning_system(NULL,oll.line_id,NULL),'[^-]+',1,2) = 'M' THEN 'Y'
                                                            ELSE 'N'
                                                        END
                                                    AS value) AS properties)
                                                    ELSE XMLCOLATTVAL(XMLCOLATTVAL(mc.segment1 AS name,
                                                    op.pricing_attribute3 AS value) AS properties,
                                                    XMLCOLATTVAL('PROVISIONED_PRODUCT' AS name,
                                                    misimd_tas_cloud_wf.check_provisioned_product(oll.inventory_item_id) AS value) AS properties,
                                                    XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                                    nvl(mc.attribute13,1) AS value) AS properties,
                                                    XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                                    utl_i18n.escape_reference(msi.description) AS value) AS properties)
                                                END
                                        ) )
                                    FROM
                                        oe_order_lines_all oll,
                                        oe_order_price_attribs opp,
                                        oe_sets oes,
                                        oe_line_sets sln,
                                        mtl_categories mc,
                                        mtl_item_categories mic,
                                        mtl_system_items_b msi
                                    WHERE
                                        oll.line_id = ol.service_reference_line_id
                                        AND   oes.set_id = sln.set_id
                                        AND   oes.set_type = 'FULFILLMENT_SET'
                                        AND   sln.line_id = oll.line_id
                                        AND   oll.header_id = oh.header_id
                                        AND   opp.line_id = oll.line_id
                                        AND   DECODE(request_source,'PAYGEN',opp.pricing_attribute94,'SPLIT_SEND',l_operation_type,1) = DECODE(request_source,'PAYGEN',nvl(p_operation_type,opp.pricing_attribute94
),'SPLIT_SEND',l_operation_type,1)
                                        AND   mc.category_id = mic.category_id
                                        AND   mic.category_set_id = 1100026004
                                        AND   mic.organization_id = 14354
                                        AND   mic.inventory_item_id = oll.inventory_item_id
                                        AND   msi.inventory_item_id = oll.inventory_item_id
                                        AND   msi.organization_id = 14354
                                ),
                                (
                                    SELECT
                                        XMLAGG(XMLELEMENT(
                                            "LicenseItem",
                                            XMLATTRIBUTES(
                                                mts.segment1 AS "LICENSE_ITEM",'INCLUDED' AS "LICENSE_LINE_TYPE",'DUMMY' AS "FULFILLMENT_SET"
                                            ),
                                            XMLCOLATTVAL(XMLCOLATTVAL(mc.segment1 AS name,
                                            misont_cloud_pub2.get_component_qty(oll.line_id,bom_component.component_item_id) AS value) AS properties,
                                            XMLCOLATTVAL('PROVISIONED_PRODUCT' AS name,
                                            misimd_tas_cloud_wf.check_provisioned_product(bom_component.component_item_id) AS value) AS properties,
                                            XMLCOLATTVAL('BLOCK_QUANTITY' AS name,
                                            nvl(mc.attribute13,1) AS value) AS properties,
                                            XMLCOLATTVAL('SERVICE_PART_ID' AS name,
                                            misont_cloud_pub2.get_b_part(mts.inventory_item_id,'ITEM_NUMBER') AS value) AS properties,
                                            XMLCOLATTVAL('SERVICE_PART_DESCRIPTION' AS name,
                                            utl_i18n.escape_reference(regexp_replace(misont_cloud_pub2.get_b_part(mts.inventory_item_id,'ITEM_DESC'),'[^'
                                            || fnd_global.local_chr(32)
                                            || '-'
                                            || fnd_global.local_chr(127)
                                            || ']',' ') ) AS value) AS properties,
                                            XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                            utl_i18n.escape_reference(regexp_replace(mts.description,'[^'
                                            || fnd_global.local_chr(32)
                                            || '-'
                                            || fnd_global.local_chr(127)
                                            || ']',' ') ) AS value) AS properties)
                                        ) )
                                    FROM
                                        bom_inventory_components_v bom_component,
                                        bom_bill_of_materials_v bom,
                                        mtl_system_items_b mts,
                                        mtl_categories mc,
                                        mtl_item_categories mic
                                    WHERE
                                        bom.bill_sequence_id = bom_component.bill_sequence_id
                                        AND   bom.assembly_item_id = oll.inventory_item_id
                                        AND   mts.inventory_item_id = bom_component.component_item_id
                                        AND   mts.organization_id = bom.organization_id
                                        AND   mts.organization_id = 14354
                                        AND   mc.category_id = mic.category_id
                                        AND   mic.category_set_id = 1100026004
                                        AND   mic.organization_id = 14354
                                        AND   nvl(bom_component.disable_date,SYSDATE + 1) > SYSDATE
                                        AND   mic.inventory_item_id = mts.inventory_item_id
                                        AND   (
                                            (mts.segment1,mts.inventory_item_id) IN(
                                                SELECT DISTINCT
                                                    qpp.pricing_attr_value_from sevenpart,
                                                    sevenpart.inventory_item_id sevenpart_inv_id
                                                FROM
                                                    misqp_cloud_credits_lines_all cloud,
                                                    mtl_system_items_b bpart,
                                                    mtl_system_items_b sevenpart,
                                                    qp_list_lines qpl,
                                                    qp_pricing_attributes qpp,
                                                    qp_list_headers pl
                                                WHERE
                                                    bpart.segment1 = cloud.inv_part_number
                                                    AND   qpp.product_attr_value = bpart.inventory_item_id
                                                    AND   bpart.organization_id = 14354
                                                    AND   qpp.pricing_attr_value_from = sevenpart.segment1
                                                    AND   sevenpart.organization_id = 14354
                                                    AND   cloud.rate_card_id = la.rate_card_id
                                                    AND   qpl.list_line_id = qpp.list_line_id
                                                    AND   qpl.list_header_id = pl.list_header_id
                                                    AND   trunc(SYSDATE) BETWEEN(trunc(nvl(qpl.start_date_active,SYSDATE) ) ) AND(trunc(nvl(qpl.end_date_active,SYSDATE + 1) ) )
                                                    AND   qpp.product_attribute = 'PRICING_ATTRIBUTE1'
                                                    AND   qpp.product_attribute_context = 'ITEM'
                                                    AND   qpp.list_header_id = pl.list_header_id
                                                    AND   qpp.list_header_id = qpl.list_header_id
                                                    AND   pl.list_type_code = 'PRL'
                                                    AND   pl.currency_code = 'USD'
                                                    AND   qpp.pricing_phase_id = 1
                                                    AND   pl.name IN(
                                                        'CURRENT COMMERCIAL','SUBSCRIPTION CURRENT COMMERCIAL','SUBSCRIPTION PRICE HOLD PRICE LIST'
                                                    )
                                                    AND   qpp.qualification_ind IN(
                                                        4,6,20,22
                                                    )
                                                    AND   nvl(pl.end_date_active,SYSDATE) > SYSDATE - 1
                                                    AND   qpp.pricing_attribute_context = 'PRICING ATTRIBUTE'
                                            )
                                            OR    la.rate_card_id IS NULL
                                        )
                                ),
                                    CASE
                                        WHEN get_rule_values('CLOUD_TYPE',ol.ordered_item) IS NOT NULL THEN XMLCOLATTVAL(XMLCOLATTVAL('OPERATIONAL_POLICY' AS name,
                                        DECODE(get_rule_values('OPERATIONAL_POLICY',ol.ordered_item),'STANDARD','STANDARD','ENTERPRISE') AS value) AS properties,
                                        XMLCOLATTVAL('ASSOCIATED_SUBSCRIPTION_ID' AS name,
                                        get_associated_sub_id(ol.service_reference_line_id) AS value) AS properties,
                                        XMLCOLATTVAL('RATE_CARD_ID' AS name,
                                        la.rate_card_id AS value) AS properties,
                                        XMLCOLATTVAL('CHANNEL_OPTIONS' AS name,
                                        la.additional_column25 AS value) AS properties,
                                            CASE
                                                WHEN(
                                                    l_operation_type <> 'CMRB'
                                                    AND request_source <> 'SPM_CMRB_FLOW'
                                                )
                                                     OR(
                                                    request_source = 'SPM_CMRB_FLOW'
                                                    AND la.additional_column20 <> NULL
                                                ) THEN XMLCOLATTVAL('PROMOTION_INTENT_TO_PAY' AS name,
                                                la.additional_column39 AS value)
                                            END
                                        AS properties,
                                            CASE
                                                WHEN(l_operation_type <> 'CMRB') THEN XMLCOLATTVAL('PROMOTION_TYPE' AS name,
                                                la.additional_column43 AS value)
                                            END
                                        AS properties,
                                        XMLCOLATTVAL('DEPLOYMENT_TYPE' AS name,
                                        la.additional_column40 AS value) AS properties,
                                        XMLCOLATTVAL('DEPLOYMENT_NAME' AS name,
                                        la.additional_column41 AS value) AS properties,
                                        XMLCOLATTVAL('READINESS_TO_RECEIVE_HARDWARE_DATE' AS name,
                                        la.additional_column56 AS value) AS properties,
                                        XMLCOLATTVAL('APIARY_TOKEN_ID' AS name,
                                        la.additional_column52 AS value) AS properties,
                                        XMLCOLATTVAL('LINE_OF_BUSINESS' AS name,
                                        la.additional_column54 AS value) AS properties,
                                        XMLCOLATTVAL('TEXTURA_TOKEN_ID' AS name,
                                        la.additional_column55 AS value) AS properties,
                                         /*18.7 added 3 properties at line level  SPM-14762 */
                                         XMLCOLATTVAL('CLOUD_ACCOUNT_NAME' AS name,
                                        la.additional_column15 AS value) AS properties,
                                         XMLCOLATTVAL('CLOUD_ACCOUNT_ID' AS name,
                                        la.additional_column14 AS value) AS properties,
                                        XMLCOLATTVAL('TRA_IBE_OPERATION_ITEM_ID' AS name,
                                           la.additional_column65 AS value) AS properties,
                                        XMLCOLATTVAL('CLOUD_TYPE' AS name,
                                        get_rule_values('CLOUD_TYPE',ol.ordered_item) AS value) AS properties,
                                        XMLCOLATTVAL('IS_ADDITIONAL_INSTANCE' AS name,
                                        DECODE(flv_item_exceptions.enabled_flag,'Y','Y','N') AS value) AS properties,
                                        XMLCOLATTVAL('IS_BASE_SERVICE_COMPONENT' AS name,
                                        DECODE(upper(emsv.c_ext_attr1),'STANDALONE','Y','N') AS value) AS properties,
                                        XMLCOLATTVAL('METRIC_NAME' AS name,
                                        mc.segment1 AS value) AS properties,
                                        XMLCOLATTVAL(mc.segment1 AS name,
                                        op.pricing_attribute3 AS value) AS properties,
                                        XMLCOLATTVAL('PROVISIONED_PRODUCT' AS name,
                                        misimd_tas_cloud_wf.check_provisioned_product(oll.inventory_item_id) AS value) AS properties,
                                        XMLCOLATTVAL('SERVICE_PART_DESCRIPTION' AS name,
                                        utl_i18n.escape_reference(regexp_replace(msi.description,'[^'
                                        || fnd_global.local_chr(32)
                                        || '-'
                                        || fnd_global.local_chr(127)
                                        || ']',' ') ) AS value) AS properties,
                                        XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                        utl_i18n.escape_reference(regexp_replace(msil.description,'[^'
                                        || fnd_global.local_chr(32)
                                        || '-'
                                        || fnd_global.local_chr(127)
                                        || ']',' ') ) AS value) AS properties,
                                        XMLCOLATTVAL('USER_ITEM_DESCRIPTION' AS name,
                                        utl_i18n.escape_reference(regexp_replace(ol.user_item_description,'[^'
                                        || fnd_global.local_chr(32)
                                        || '-'
                                        || fnd_global.local_chr(127)
                                        || ']',' ') ) AS value) AS properties)
                                        WHEN get_rule_values('CLOUD_TYPE',ol.ordered_item) IS NULL THEN XMLCOLATTVAL(XMLCOLATTVAL('OPERATIONAL_POLICY' AS name,
                                        DECODE(get_rule_values('OPERATIONAL_POLICY',ol.ordered_item),'STANDARD','STANDARD','ENTERPRISE') AS value) AS properties,
                                        XMLCOLATTVAL('ASSOCIATED_SUBSCRIPTION_ID' AS name,
                                        get_associated_sub_id(ol.service_reference_line_id) AS value) AS properties,
                                        XMLCOLATTVAL('RATE_CARD_ID' AS name,
                                        la.rate_card_id AS value) AS properties,
                                        XMLCOLATTVAL('CHANNEL_OPTIONS' AS name,
                                        la.additional_column25 AS value) AS properties,
                                            CASE
                                                WHEN(
                                                    l_operation_type <> 'CMRB'
                                                    AND request_source <> 'SPM_CMRB_FLOW'
                                                )
                                                     OR(
                                                    request_source = 'SPM_CMRB_FLOW'
                                                    AND la.additional_column20 <> NULL
                                                ) THEN XMLCOLATTVAL('PROMOTION_INTENT_TO_PAY' AS name,
                                                la.additional_column39 AS value)
                                            END
                                        AS properties,
                                            CASE
                                                WHEN(l_operation_type <> 'CMRB') THEN XMLCOLATTVAL('PROMOTION_TYPE' AS name,
                                                la.additional_column43 AS value)
                                            END
                                        AS properties,
                                        XMLCOLATTVAL('DEPLOYMENT_TYPE' AS name,
                                        la.additional_column40 AS value) AS properties,
                                        XMLCOLATTVAL('DEPLOYMENT_NAME' AS name,
                                        la.additional_column41 AS value) AS properties,
                                        XMLCOLATTVAL('READINESS_TO_RECEIVE_HARDWARE_DATE' AS name,
                                        la.additional_column56 AS value) AS properties,
                                        XMLCOLATTVAL('APIARY_TOKEN_ID' AS name,
                                        la.additional_column52 AS value) AS properties,
                                        XMLCOLATTVAL('LINE_OF_BUSINESS' AS name,
                                        la.additional_column54 AS value) AS properties,
                                        XMLCOLATTVAL('TEXTURA_TOKEN_ID' AS name,
                                        la.additional_column55 AS value) AS properties,
                                         /*18.7 added 3 properties at line level  SPM-14762 */
                                         XMLCOLATTVAL('CLOUD_ACCOUNT_NAME' AS name,
                                        la.additional_column15 AS value) AS properties,
                                         XMLCOLATTVAL('CLOUD_ACCOUNT_ID' AS name,
                                        la.additional_column14 AS value) AS properties,
                                        XMLCOLATTVAL('TRA_IBE_OPERATION_ITEM_ID' AS name,
                                           la.additional_column65 AS value) AS properties,
                                        XMLCOLATTVAL('PROGRAM_TYPE' AS name,
                                        la.additional_column60 AS value) AS properties,
                                        XMLCOLATTVAL('IS_ADDITIONAL_INSTANCE' AS name,
                                        DECODE(flv_item_exceptions.enabled_flag,'Y','Y','N') AS value) AS properties,
                                        XMLCOLATTVAL('IS_BASE_SERVICE_COMPONENT' AS name,
                                        DECODE(upper(emsv.c_ext_attr1),'STANDALONE','Y','N') AS value) AS properties,
                                        XMLCOLATTVAL('METRIC_NAME' AS name,
                                        mc.segment1 AS value) AS properties,
                                        XMLCOLATTVAL(mc.segment1 AS name,
                                        op.pricing_attribute3 AS value) AS properties,
                                        XMLCOLATTVAL('PROVISIONED_PRODUCT' AS name,
                                        misimd_tas_cloud_wf.check_provisioned_product(oll.inventory_item_id) AS value) AS properties,
                                        XMLCOLATTVAL('SERVICE_PART_DESCRIPTION' AS name,
                                        utl_i18n.escape_reference(regexp_replace(msi.description,'[^'
                                        || fnd_global.local_chr(32)
                                        || '-'
                                        || fnd_global.local_chr(127)
                                        || ']',' ') ) AS value) AS properties,
                                        XMLCOLATTVAL('LICENSE_PART_DESCRIPTION' AS name,
                                        utl_i18n.escape_reference(regexp_replace(msil.description,'[^'
                                        || fnd_global.local_chr(32)
                                        || '-'
                                        || fnd_global.local_chr(127)
                                        || ']',' ') ) AS value) AS properties,
                                        XMLCOLATTVAL('USER_ITEM_DESCRIPTION' AS name,
                                        utl_i18n.escape_reference(regexp_replace(ol.user_item_description,'[^'
                                        || fnd_global.local_chr(32)
                                        || '-'
                                        || fnd_global.local_chr(127)
                                        || ']',' ') ) AS value) AS properties)
                                    END
                            )
                            ORDER BY
                                CASE
                                    WHEN l_split_flag = 'Y' THEN l_operation_type
                                    ELSE op.pricing_attribute94
                                END,
                                ol.service_end_date,
                                ol.service_start_date
                            )
                        )
                    FROM
                        oe_order_lines_all ol,
                        oe_order_lines_all oll,
                        oe_order_price_attribs op,
                        mtl_system_items_b msi,
                        oe_sets oes,
                        oe_line_sets sln,
                        mtl_categories mc,
                        mtl_item_categories mic,
                        mtl_system_items_b msil,
                        misont_order_line_attribs_ext la,
                        (
                            SELECT
                                c_ext_attr1,
                                inventory_item_id
                            FROM
                                ego_mtl_sy_items_ext_vl
                            WHERE
                                attr_group_id = 48084
                                AND   organization_id = 14354
                        ) emsv,
                        (
                            SELECT
                                lookup_code,
                                enabled_flag
                            FROM
                                fnd_lookup_values flv
                            WHERE
                                flv.lookup_type = 'MISONT_CLOUD_NOTIFY_CRITERIA'
                                AND   flv.tag = 'ITEM'
                                AND   flv.language = 'US'
                        ) flv_item_exceptions
                    WHERE
                        ol.item_type_code = 'SERVICE'
                        AND   ol.header_id = oh.header_id
                        AND   op.line_id = ol.line_id
                        AND   (
                            (
                                l_cpq_flag = 'N'
                                AND   p_line_ids IS NULL
                            )
                            OR    (
                                (
                                    (p_line_ids IS NOT NULL)
                                    OR    (l_cpq_flag = 'Y')
                                    OR    (
                                        l_split_flag = 'Y'
                                        AND   p_line_ids IS NOT NULL
                                    )
                                )
                                AND   (ol.line_id IN(
                                    SELECT
                                        to_number(regexp_substr(p_line_ids,'[^,]+',1,level) ) AS cpqlineids
                                    FROM
                                        dual
                                    CONNECT BY
                                        level <= regexp_count(p_line_ids,'[^,]+')
                                ) )
                            )
                        )
      /* included for CPQ GRP*/
                        AND   (
                            (
                                (p_sub_id IS NOT NULL)
                                AND   (op.pricing_attribute92 = p_sub_id)
                            )
                            OR    (p_sub_id IS NULL)
                        )
                        AND   DECODE(request_source,'PAYGEN',op.pricing_attribute94,'SPLIT_SEND',l_operation_type,1) = DECODE(request_source,'PAYGEN',nvl(p_operation_type,op.pricing_attribute94
),'SPLIT_SEND',l_operation_type,1)
                        AND   msi.inventory_item_id = ol.inventory_item_id
                        AND   msi.organization_id = ol.ship_from_org_id
                        AND   nvl(misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'TAG'),'X') IN(
                            'SaaS','PaaS'
                        )
                        AND   oll.header_id = ol.header_id
                        AND   oll.line_id = ol.service_reference_line_id
                        AND   oes.set_id = sln.set_id
                        AND   oes.set_type = 'FULFILLMENT_SET'
                        AND   sln.line_id = ol.service_reference_line_id
                        AND   mc.category_id = mic.category_id
                        AND   mic.category_set_id = 1100026004
                        AND   mic.organization_id = 14354
                        AND   mic.inventory_item_id = ol.inventory_item_id
                        AND   msil.inventory_item_id = oll.inventory_item_id
                        AND   msil.organization_id = 14354
                        AND   emsv.inventory_item_id(+) = msi.inventory_item_id
                        AND   flv_item_exceptions.lookup_code(+) = ol.ordered_item
                        AND   ol.line_id = la.line_id(+)
                        AND   (
                            (
                                request_source IN(
                                    'GSI','TAS'
                                )
                                AND   EXISTS(
                                    SELECT
                                        1
                                    FROM
                                        wf_item_activity_statuses s,
                                        wf_process_activities p
                                    WHERE
                                        s.process_activity = p.instance_id
                                        AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                                        AND   s.item_type = 'OEOL'
                                        AND   s.item_key = TO_CHAR(ol.line_id)
                                )
                                AND   NOT EXISTS(
                                    SELECT
                                        1
                                    FROM
                                        oe_order_lines_all
                                    WHERE
                                        line_id = ol.line_id
                                        AND   flow_status_code IN(
                                            'CLOSED','CANCELLED'
                                        )
                                )
                            )
                            OR    (
                                request_source <> 'GSI'
                                AND   request_source <> 'TAS'
                            )
                        )
                )
            ) AS "Order_List"
        INTO
            l_order_str
        FROM
            oe_order_headers_all oh,
            hz_cust_accounts cust_acct,
            hz_parties cust_party
        WHERE
            oh.header_id = oh.header_id
            AND   cust_acct.cust_account_id = sold_to_org_id --16.12 MSP related changes
            AND   cust_acct.party_id = cust_party.party_id
            AND   oh.header_id = p_header_id;

  /*IF l_order_str IS NOT NULL THEN
  Dbms_Output.put_line('  l_order_str is not null' );
  ELSE
  Dbms_Output.put_line('  l_order_str is null' );
  END IF; */
  --*****************************--
  ---- Adding the lines based on the part number
  --*****************************--

        BEGIN
            IF
                regexp_like(l_operation_type,'ONBOARDING')
            THEN
                l_order_str := append_iot_lines(l_order_str);
                NULL;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RETURN l_order_str;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
            RAISE;
    END get_payload;

    FUNCTION get_covered_line_metrics (
        p_line_id   IN VARCHAR2,
        p_metric    IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_metrics   VARCHAR2(1000);
    BEGIN
        IF
            p_metric = 'METRIC_VALUE'
        THEN
            SELECT
                SUM(cip.pricing_attribute7)
            INTO
                l_metrics
            FROM
                csi_i_pricing_attribs cip
            WHERE
                cip.instance_id IN (
                    SELECT DISTINCT
                        okii.object1_id1
                    FROM
                        okc_k_lines_b okll,
                        okc_k_items okii
                    WHERE
                        okll.cle_id = p_line_id
                        AND   okii.cle_id = okll.id
                );

        ELSIF p_metric = 'METRIC_NAME' THEN
            SELECT
                mcl.segment1
            INTO
                l_metrics
            FROM
                okc_k_lines_b okll,
                mtl_system_items_b msil,
                okc_k_items okil,
                csi_i_pricing_attribs cip,
                csi_item_instances cii,
                mtl_categories mcl,
                mtl_item_categories micl
            WHERE
                okll.cle_id = p_line_id
                AND   okil.cle_id = okll.id
                AND   msil.inventory_item_id = (
                    SELECT
                        k.inventory_item_id
                    FROM
                        csi_item_instances k
                    WHERE
                        to_number(okil.object1_id1) = k.instance_id
                )
                AND   msil.organization_id = 14354
                AND   cii.instance_id = cip.instance_id
                AND   okil.object1_id1 = cii.instance_id
                AND   micl.inventory_item_id = msil.inventory_item_id
                AND   mcl.category_id = micl.category_id
                AND   micl.category_set_id = 1100026004
                AND   micl.organization_id = 14354
                AND   ROWNUM = 1;

        ELSIF p_metric = 'LICENSE_PART_DESCRIPTION' THEN
            SELECT
                msil.description
            INTO
                l_metrics
            FROM
                okc_k_lines_b okll,
                mtl_system_items_b msil,
                okc_k_items okil,
                csi_i_pricing_attribs cip,
                csi_item_instances cii,
                mtl_categories mcl,
                mtl_item_categories micl
            WHERE
                okll.cle_id = p_line_id
                AND   okil.cle_id = okll.id
                AND   msil.inventory_item_id = (
                    SELECT
                        k.inventory_item_id
                    FROM
                        csi_item_instances k
                    WHERE
                        to_number(okil.object1_id1) = k.instance_id
                )
                AND   msil.organization_id = 14354
                AND   cii.instance_id = cip.instance_id
                AND   okil.object1_id1 = cii.instance_id
                AND   micl.inventory_item_id = msil.inventory_item_id
                AND   mcl.category_id = micl.category_id
                AND   micl.category_set_id = 1100026004
                AND   micl.organization_id = 14354
                AND   ROWNUM = 1;

        END IF;

        RETURN l_metrics;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
  /*-  raise;*/
    END get_covered_line_metrics;

    FUNCTION get_unique_instance_id (
        p_line_id IN NUMBER
    ) RETURN NUMBER AS
        l_id   NUMBER;
    BEGIN
        SELECT
            cii.instance_id
        INTO
            l_id
        FROM
            csi_item_instances cii,
            okc_k_items oki
        WHERE
            oki.cle_id = p_line_id
            AND   oki.object1_id1 = cii.instance_id
            AND   ROWNUM = 1;

        RETURN l_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
  /*-  raise;*/
    END get_unique_instance_id;

    FUNCTION check_provisioned_product (
        p_item_id IN NUMBER
    ) RETURN VARCHAR2 AS
        l_result   VARCHAR2(100);
    BEGIN
        SELECT
            mc.description AS value
        INTO
            l_result
        FROM
            mtl_categories mc,
            mtl_category_sets mcs,
            mtl_item_categories mic
        WHERE
            mc.category_id = mic.category_id
            AND   mcs.category_set_id = mic.category_set_id
            AND   mic.organization_id = 14354
            AND   mic.inventory_item_id = p_item_id
            AND   mcs.category_set_name = 'PROVISIONED_PRODUCT'
            AND   ROWNUM = 1;

        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
  /*-  raise;*/
    END check_provisioned_product;

    FUNCTION is_metered_subscription (
        p_line_id IN NUMBER
    ) RETURN VARCHAR2 AS
        l_is_metered_billing   VARCHAR2(100) := 'N';
    BEGIN
        BEGIN
            SELECT
                'Y'
            INTO
                l_is_metered_billing
            FROM
                oe_order_lines_all ool,
                mtl_categories mc,
                mtl_item_categories mic,
                mtl_category_sets mcs
            WHERE
                (
                    ool.line_id = p_line_id
                    OR    ool.service_reference_line_id = p_line_id
                )
                AND   ool.inventory_item_id = mic.inventory_item_id
                AND   mcs.category_set_id = mic.category_set_id
                AND   mc.category_id = mic.category_id
                AND   mic.organization_id = 14354
                AND   lower(category_set_name) LIKE 'usage%billing%'
                AND   mc.segment1 = 'METERED_BILLING'
                AND   ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                l_is_metered_billing := 'N';
        END;

        RETURN l_is_metered_billing;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
  /*-  raise;*/
    END is_metered_subscription;

    FUNCTION is_combined_payload (
        p_hdr_id IN NUMBER
    ) RETURN VARCHAR2 AS

        l_combined_grp        VARCHAR2(1) := 'N';
  /* l_service_group   varchar2(200);*/
        l_combined_grp_oper   VARCHAR2(200) := 'Y';
        CURSOR c2 IS SELECT
            misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') AS service_group
                     FROM
            oe_order_lines_all ol
                     WHERE
            ol.header_id = p_hdr_id
            AND   ol.item_type_code = 'SERVICE';

        CURSOR c3 IS SELECT DISTINCT
            pricing_attribute94 AS line_operation_type
                     FROM
            oe_order_price_attribs
                     WHERE
            pricing_attribute94 IS NOT NULL
            AND   header_id = p_hdr_id;

    BEGIN
  /*- Check for Operation Type for Combined Payload*/
        FOR l_opr_typ IN c3 LOOP
            IF
                ( l_opr_typ.line_operation_type <> 'ONBOARDING' )
            THEN
                l_combined_grp_oper := 'N';
                EXIT;
            END IF;
        END LOOP;
  /*- Check for Product Group for Combined Payload*/

        FOR l_srv_grp IN c2 LOOP
            IF
                ( ( l_srv_grp.service_group IN (
                    'BI',
                    'IAASMB',
                    'DBMB',
                    'JAVAMB'
                ) ) AND l_combined_grp_oper = 'Y' )
            THEN
                l_combined_grp := 'Y';
                EXIT;
            END IF;
        END LOOP;

        RETURN l_combined_grp;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
  /*-  raise;*/
    END is_combined_payload;

    PROCEDURE init (
        p_errror_flag OUT NOCOPY VARCHAR2
    ) IS
        g_delay   NUMBER;
    BEGIN
        g_module := 'INIT';
        g_tracefile_identifier := 'MISIMD_TAS_CLOUD_WF'
        || TO_CHAR(SYSDATE,'DDMMHHMISS');
        g_context_name2 := 'Collect Lookup Values';
        SELECT
            lookup_value
        INTO
            g_trace_level
        FROM
            oss_intf_user.misimd_intf_lookup
        WHERE
            application = 'GSI-TAS CLOUD BRIDGE'
            AND   component = 'MISIMD_TAS_CLOUD_WF'
            AND   upper(lookup_code) = 'TRACE_LEVEL'
            AND   enabled = 'Y';

        SELECT
            lookup_value
        INTO
            g_log_level
        FROM
            oss_intf_user.misimd_intf_lookup
        WHERE
            application = 'GSI-TAS CLOUD BRIDGE'
            AND   component = 'MISIMD_TAS_CLOUD_WF'
            AND   upper(lookup_code) = 'LOG_LEVEL'
            AND   enabled = 'Y';

        SELECT
            lookup_value
        INTO
            g_trace
        FROM
            oss_intf_user.misimd_intf_lookup
        WHERE
            application = 'GSI-TAS CLOUD BRIDGE'
            AND   component = 'MISIMD_TAS_CLOUD_WF'
            AND   upper(lookup_code) = 'TRACE_ENABLED'
            AND   enabled = 'Y';

        SELECT
            lookup_value
        INTO
            g_delay
        FROM
            oss_intf_user.misimd_intf_lookup
        WHERE
            application = 'GSI-TAS CLOUD BRIDGE'
            AND   component = 'MISIMD_TAS_CLOUD_WF'
            AND   upper(lookup_code) = 'TIME_DELAY'
            AND   enabled = 'Y';
  /*sleep for g_delay seconds*/

        dbms_lock.sleep(g_delay);
        IF
            g_trace = 'Y'
        THEN
            misimd_audit.enable_trace(g_trace_level,g_tracefile_identifier);
        END IF;
        p_errror_flag := 'N';
        BEGIN
            g_context_name2 := 'Generate Run Key';
            SELECT
                round(SUM(TO_CHAR(SYSDATE,'DDDSSSSSSSSS') + dbms_random.value(1000000000,9999999999) ) )
            INTO
                g_intf_run_key
            FROM
                dual;

            g_audit_message := 'Run Key '
            || g_intf_run_key;
            insert_log(g_audit_message,3,g_module,g_context_name2,g_context_id,NULL);
        EXCEPTION
            WHEN OTHERS THEN
                p_errror_flag := 'Y';
                p_error_code := sqlcode;
                p_error_message := sqlerrm;
                insert_error(p_error_code,p_error_message,g_module,g_context_name2,g_context_id,errbuf);
        END;

    END init;

    PROCEDURE insert_log (
        g_audit_message      IN VARCHAR2,
        g_audit_level        IN NUMBER,
        g_module             IN VARCHAR2,
        g_context_name2      IN VARCHAR2,
        g_context_id         IN NUMBER,
        g_audit_attachment   IN CLOB
    ) IS

        p_transaction_reference   NUMBER;
        p_application             VARCHAR2(100);
        p_component               VARCHAR2(100);
        p_platform                VARCHAR2(100);
        p_timestamp               TIMESTAMP(9);
    BEGIN
        p_transaction_reference := g_intf_run_key;
        p_application := 'GSI-TAS CLOUD BRIDGE';
        p_component := 'MISIMD_TAS_CLOUD_WF';
        p_platform := 'Oracle Database';
        p_timestamp := systimestamp;
        g_log_level := 5;
        IF
            g_audit_level <= g_log_level
        THEN
            misimd_audit.intf_log(p_transaction_reference,g_audit_message,g_audit_level,p_application,p_component,g_module,p_timestamp,g_context_name,g_context_id,
g_context_name2,g_context_id2,global_entity,g_context_id3,p_platform,g_audit_attachment,errbuf);
        END IF;

    END insert_log;

    PROCEDURE insert_error (
        p_error_code      IN VARCHAR2,
        p_error_message   IN VARCHAR2,
        g_module          IN VARCHAR2,
        g_context_name2   IN VARCHAR2,
        g_context_id      IN NUMBER,
        errbuf            OUT NOCOPY VARCHAR2
    ) IS

        p_transaction_reference   NUMBER;
        p_application             VARCHAR2(100);
        p_component               VARCHAR2(100);
        p_platform                VARCHAR2(100);
        p_log_details             VARCHAR2(300);
        p_timestamp               TIMESTAMP(9);
    BEGIN
        p_transaction_reference := g_intf_run_key;
        p_application := 'GSI-TAS CLOUD BRIDGE';
        p_component := 'MISIMD_TAS_CLOUD_WF';
        p_platform := 'Oracle Database';
        p_log_details := 'Tracefile Identifier:'
        || g_tracefile_identifier;
        p_timestamp := systimestamp;
        IF
            g_log_level >= 1
        THEN
            misimd_audit.intf_error(p_transaction_reference,p_error_code,p_error_message,p_application,p_component,g_module,p_timestamp,g_context_name,g_context_id
,g_context_name2,g_context_id2,global_entity,g_context_id3,p_platform,p_log_details,errbuf);
        END IF;

    END insert_error;

    FUNCTION get_rule_values (
        p_rule_set     IN VARCHAR2,
        p_rule_value   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_value   VARCHAR2(2000);
    BEGIN
        SELECT
            attribute_value
        INTO
            l_value
        FROM
            (
                SELECT
                    attribute_value
                FROM
                    apxiimd.misimd_om_tas_rule_values tab1,
                    apxiimd.misimd_om_tas_ruleset tab2
                WHERE
                    tab1.ruleset_id = tab2.ruleset_id
                    AND   tab1.rule_value = p_rule_value
                    AND   tab2.ruleset_name = p_rule_set
                    AND   tab1.enabled = 'Y'
            )
        WHERE
            ROWNUM = 1;

        RETURN l_value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rule_values;
/*16.7 changes*/

    FUNCTION get_associated_sub_id (
        p_line_id IN NUMBER
    ) RETURN VARCHAR2 IS
        l_associated_sub_id   VARCHAR2(2000);
    BEGIN
        IF
            p_line_id IS NULL
        THEN
            l_associated_sub_id := NULL;
        ELSE
            SELECT
                additional_column17
            INTO
                l_associated_sub_id
            FROM
                misont_order_line_attribs_ext mole
            WHERE
                mole.line_id = p_line_id;

        END IF;

        RETURN l_associated_sub_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_associated_sub_id;
/*-========== SPLIT CODE===========================*/
/**/
/* Logging*/
/**/

    PROCEDURE split_insert_log_debug (
        dbms_flag   IN VARCHAR2,
        str         IN VARCHAR2
    )
        IS
    BEGIN
        IF
            dbms_flag = 'Y'
        THEN
    /*      Dbms_Output.put_line(str);*/
            NULL;
        ELSE
            fnd_file.put_line(fnd_file.output,str);
        END IF;
    END split_insert_log_debug;
/**/
/* update transaction lines from ready to send*/
/**/

    PROCEDURE split_upd_txn_line_status (
        p_header_id   IN NUMBER DEFAULT NULL,
        p_line_ids    IN VARCHAR2 DEFAULT NULL,
        p_trx_id      IN NUMBER DEFAULT NULL,
        p_dbms_flag   IN VARCHAR2 DEFAULT 'N'
    )
        IS
    BEGIN
        l_dbms_flag := p_dbms_flag;
        split_insert_log_debug(l_dbms_flag,'Split Engine: Starting processing UPD_LINE_STATUS:');
  /**/
  /* update the status from ready to send*/
  /**/
        UPDATE apxiimd.misimd_tas_split_stage
            SET
                status = l_split_status_s,
                last_updated_date = SYSDATE
        WHERE
            line_id IN (
                SELECT
                    to_number(regexp_substr(p_line_ids,'[^,]+',1,level) ) AS lineids
                FROM
                    dual
                CONNECT BY
                    level <= regexp_count(p_line_ids,'[^,]+')
            )
            AND   status = l_split_status_r
            AND   transaction_id = p_trx_id;

        split_insert_log_debug(l_dbms_flag,'Split Engine: Complete processing UPD_LINE_STATUS: Updated '
        || SQL%rowcount
        || ' records in the stg table');
    EXCEPTION
        WHEN OTHERS THEN
            split_insert_log_debug(l_dbms_flag,sqlerrm);
            RAISE;
    END split_upd_txn_line_status;
/**/
/* Send payload based onthe parameters*/
/**/

    PROCEDURE split_send_split_payload (
        p_line_ids    IN VARCHAR2 DEFAULT NULL,
        p_trx_id      IN NUMBER DEFAULT NULL,
        p_dbms_flag   IN VARCHAR2 DEFAULT 'N'
    ) IS

        l_order_str          XMLTYPE;
        l_order_data         CLOB;
        l_tas_or_email       VARCHAR2(10);
        l_order_number       VARCHAR2(200);
        l_seq_number         NUMBER;
        l_source_name        VARCHAR2(300);
        l_onboarding_count   NUMBER;
        l_header_id          NUMBER;
        l_line_ids           VARCHAR2(200);
        l_optype             VARCHAR2(40);
        l_trx_id             NUMBER;
        l_paramlist_t        wf_parameter_list_t := NULL;
        l_line_id            oe_order_lines_all.line_id%TYPE;
    BEGIN
        l_dbms_flag := p_dbms_flag;
        fnd_file.put_line(fnd_file.log,'*** Split send payload  ***');
  /* We have TransactionID*/
  /* get the linelist and operation_type for the TransactionID and send it*/
  /**/
        SELECT DISTINCT
            transaction_id,
            staging_operation_type,
            header_id
        INTO
            l_trx_id,l_optype,l_header_id
        FROM
            apxiimd.misimd_tas_split_stage
        WHERE
            transaction_id = p_trx_id;
  /**/
  /* if linelist is null,get the line list from staging*/
  /**/

        IF
            p_line_ids IS NULL
        THEN
            SELECT
                LISTAGG(line_id,
                ',') WITHIN GROUP(
                ORDER BY
                    header_id
                )
            INTO
                l_line_ids
            FROM
                apxiimd.misimd_tas_split_stage
            WHERE
                status IN (
                    l_split_status_r
                )
                AND   transaction_id = p_trx_id;

        ELSE
            l_line_ids := p_line_ids;
        END IF;

        IF
            l_line_ids IS NOT NULL
        THEN
    /* get one lineid from the linelist*/
            SELECT
                to_number(regexp_substr(l_line_ids,'[^,]+',1,level) )
            INTO
                l_line_id
            FROM
                dual
            CONNECT BY
                level <= 1;

            split_insert_log_debug(l_dbms_flag,'Split Engine: SEND_PAYLOAD-> Send_payload parameters');
            split_insert_log_debug(l_dbms_flag,'Split Engine: SEND_PAYLOAD-> l_header_id: '
            || l_header_id);
            split_insert_log_debug(l_dbms_flag,'Split Engine: SEND_PAYLOAD-> l_operation_type: '
            || l_optype);
            split_insert_log_debug(l_dbms_flag,'Split Engine: SEND_PAYLOAD-> l_line_ids: '
            || l_line_ids);
            split_insert_log_debug(l_dbms_flag,'Split Engine: SEND_PAYLOAD-> l_line_id: '
            || l_line_id);
            l_order_str := misimd_tas_cloud_wf.get_payload(p_header_id => l_header_id,request_source => 'SPLIT_SEND',p_operation_type => l_optype,p_line_ids => l_line_ids,p_line_id
=> l_line_id,p_sub_id => NULL);

            split_insert_log_debug(l_dbms_flag,' got back from TAS');
            IF
                l_order_str IS NOT NULL
            THEN
                split_insert_log_debug(l_dbms_flag,' l_order_data data is not null');
                SELECT
                    XMLROOT(l_order_str,
                    VERSION '1.0',STANDALONE YES) AS xmlroot
                INTO
                    l_order_str
                FROM
                    dual;

                l_order_data := l_order_str.getclobval ();
                wf_event.RAISE(p_event_name => 'misimd.om.notify.tas',p_event_key => systimestamp,p_event_data => l_order_data,p_parameters => l_paramlist_t,p_send_date => SYSDATE
);

                split_insert_log_debug(l_dbms_flag,'Business Event Raised');
      /* update the sent lines to SENT*/
                split_upd_txn_line_status(p_header_id => l_header_id,p_line_ids => l_line_ids,p_trx_id => l_trx_id);
            ELSE
                split_insert_log_debug(l_dbms_flag,'Split Engine: blank xml from get_payload call');
            END IF;

        ELSE
            split_insert_log_debug(l_dbms_flag,'Split Engine: SEND_PAYLOAD-> NO LINE IDS ARE FOUND');
        END IF;

        split_insert_log_debug(l_dbms_flag,'End  SEND_PAYLOAD');
    EXCEPTION
        WHEN OTHERS THEN
            split_insert_log_debug(l_dbms_flag,sqlerrm);
            RAISE;
    END split_send_split_payload;
/**/
/* main proc used in Concurrent pgm*/
/**/

    PROCEDURE split_initiate_send (
        errbuf        OUT NOCOPY VARCHAR2,
        retcode       OUT NOCOPY VARCHAR2,
        p_trx_id      IN NUMBER DEFAULT NULL,
        p_source      IN VARCHAR2 DEFAULT 'SPLIT_SEND',
        p_header_id   IN NUMBER DEFAULT NULL,
        p_line_ids    IN VARCHAR2 DEFAULT NULL,
        p_optype      IN VARCHAR2 DEFAULT NULL,
        p_dbms_flag   IN VARCHAR2 DEFAULT 'N'
    ) IS

        l_line_id     NUMBER;
        l_header_id   NUMBER;
        l_line_ids    VARCHAR2(200);
        l_optype      VARCHAR2(40);
        l_trx_id      NUMBER;
  /*- CURSOR to Identify eligible orders in OM for split->Process*/
        CURSOR c_omsplit_eligible IS SELECT
            SYSDATE
                                     FROM
            dual;

    BEGIN
  /**/
  /* If you want to write some output call:*/
        fnd_file.put_line(fnd_file.log,'*** transaction id being processed : '
        || p_trx_id);
  /**/
        l_dbms_flag := p_dbms_flag;
  /*-LOGIC TO INDETIFY THE SOURCE CALLING THE SPLIT------*/
        IF
            p_source = 'SPLIT_SEND' AND p_trx_id IS NOT NULL
        THEN
    /* call send_payload with txn id*/
            split_send_split_payload(p_trx_id => p_trx_id,p_dbms_flag => p_dbms_flag);
        ELSIF p_source = 'SPLIT_SEND' AND p_trx_id IS NULL THEN
    /**/
    /*- Find all the ready status for each distinct transaction loop and send it*/
    /**/
            BEGIN
                FOR each_transaction IN (
                    SELECT DISTINCT
                        transaction_id AS transaction_id
                    FROM
                        apxiimd.misimd_tas_split_stage
                    WHERE
                        status = l_split_status_r
                ) LOOP
                    split_send_split_payload(p_trx_id => each_transaction.transaction_id,p_dbms_flag => p_dbms_flag);
                END LOOP;

            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
      /* No transactionID handled*/
            END;
        ELSIF p_source IS NOT NULL AND upper(p_source) = l_source_ss THEN
    /* SCHEDULED_SPLIT*/
    /*- Do you want to stamp the SCHEDULED_SPLIT ,in the staging table instead of SPLIT_SEND*/
    /**/
    /* Concurrent program has been invoked with/without  TXN_ID*/
            IF
                p_trx_id IS NOT NULL
            THEN
                split_send_split_payload(p_trx_id => p_trx_id,p_dbms_flag => 'Y');
            ELSE
      /**/
      /*- find all the new status - dsitinct transacation.*/
      /*- for each transaction,find all the distinct waiting_on list.*/
      /*- find in oe_order_lines if all these lines are provisioned*/
      /*- if all lines are provisioned,then change the transaction to READY*/
      /**/
                NULL;
            END IF;
    /*-*/
    /* Send all ready status transaction in loop*/
    /*-*/

            BEGIN
                FOR each_transaction IN (
                    SELECT DISTINCT
                        transaction_id AS transaction_id
                    FROM
                        apxiimd.misimd_tas_split_stage
                    WHERE
                        status = l_split_status_r
                ) LOOP
                    split_send_split_payload(p_trx_id => each_transaction.transaction_id,p_dbms_flag => 'Y');
                END LOOP;

            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
      /* No transactionID handled*/
            END;

        ELSIF p_source IS NOT NULL AND upper(p_source) = l_source_ls THEN
            split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT->'
            || l_source_ls);
            IF
                p_line_ids IS NOT NULL
            THEN
                SELECT
                    to_number(regexp_substr(p_line_ids,'[^,]+',1,level) )
                INTO
                    l_line_id
                FROM
                    dual
                CONNECT BY
                    level <= 1;

                SELECT DISTINCT
                    header_id
                INTO
                    l_header_id
                FROM
                    oe_order_lines_all
                WHERE
                    line_id = l_line_id;

                SELECT
                    transaction_id,
                    staging_operation_type
                INTO
                    l_trx_id,l_optype
                FROM
                    apxiimd.misimd_tas_split_stage
                WHERE
                    line_id = l_line_id
                    AND   header_id = l_header_id;
      /*SEND_PAYLOAD( P_SOURCE => P_SOURCE ,P_HEADER_ID => l_header_id ,P_LINE_IDS => P_LINE_IDS ,P_OPTYPE => l_optype ,P_TRX_ID => l_trx_id);*/
      /*UPD_LINE_STATUS( P_HEADER_ID => l_header_id ,P_LINE_IDS => P_LINE_IDS ,P_TRX_ID => l_trx_id);*/

            ELSE
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> No Line Ids are passed');
            END IF;

        ELSIF p_source IS NOT NULL AND upper(p_source) = l_source_ss THEN
            split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT->'
            || l_source_ls);
    /*select To_Number(regexp_substr(p_line_ids,'[^,]+',1,level)) as cpqlineids from dual connect by level <= regexp_count(p_line_ids,'[^,]+');*/
    /* go to Staging table*/
    /*- for every new record ,go to OM and find if provisioned*/
    /*===========if provisioned then change the status from NEW to READY*/
    /*=====================then send payload*/
            FOR c_records IN c_omsplit_eligible LOOP
      /* LOGIC*/
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> Send_payload parameters derrived');
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> P_SOURCE: '
                || p_source);
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> l_header_id: '
                || l_header_id);
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> P_LINE_IDS: '
                || p_line_ids);
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> l_optype: '
                || l_optype);
                split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT-> l_trx_id: '
                || l_trx_id);
      /*SEND_PAYLOAD( P_SOURCE => P_SOURCE ,P_HEADER_ID => l_header_id ,P_LINE_IDS => P_LINE_IDS ,P_OPTYPE => l_optype ,P_TRX_ID => l_trx_id);*/
      /*UPD_LINE_STATUS( P_HEADER_ID => l_header_id ,P_LINE_IDS => P_LINE_IDS ,P_TRX_ID => l_trx_id);*/
            END LOOP;

        ELSIF p_source IS NOT NULL AND upper(p_source) = l_source_ms THEN
            split_insert_log_debug(l_dbms_flag,'Split Engine: INITIATE_SPLIT->'
            || l_source_ls);
            SELECT
                transaction_id,
                staging_operation_type
            INTO
                l_trx_id,l_optype
            FROM
                apxiimd.misimd_tas_split_stage
            WHERE
                line_id = l_line_id
                AND   header_id = l_header_id;
    /* USE the Submitted Trx Id,instead of the derived one.*/

            IF
                p_trx_id IS NOT NULL
            THEN
                l_trx_id := p_trx_id;
            END IF;
            IF
                p_line_ids IS NULL
            THEN
                SELECT
                    LISTAGG(line_id,
                    ',') WITHIN GROUP(
                    ORDER BY
                        header_id
                    )
                INTO
                    l_line_ids
                FROM
                    apxiimd.misimd_tas_split_stage
                WHERE
                    status = l_split_status_r;

            ELSE
                l_line_ids := p_line_ids;
            END IF;

            IF
                p_header_id IS NOT NULL
            THEN
      /*SEND_PAYLOAD( P_SOURCE => P_SOURCE ,P_HEADER_ID => P_HEADER_ID ,P_LINE_IDS => l_line_ids ,P_OPTYPE => l_optype ,P_TRX_ID => l_trx_id);*/
      /*UPD_LINE_STATUS( P_HEADER_ID => P_HEADER_ID ,P_LINE_IDS => l_line_ids ,P_TRX_ID => l_trx_id);*/
                NULL;
            ELSE
                fnd_file.put_line(fnd_file.log,'*** Split Engine: Header Id cannot be NULL : '
                || p_trx_id);
            END IF;

        END IF;

        fnd_file.put_line(fnd_file.log,'*** Split Engine: completed for '
        || p_trx_id);
  /* Return 0 for successful completion.*/
        errbuf := '';
        retcode := '0';
    EXCEPTION
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := '2';
            fnd_file.put_line(fnd_file.log,'OTHERS exception while submitting The Program: '
            || sqlerrm);
    END split_initiate_send;
/**/
/* Main procedure which will check the rule and insert into staging table.*/
/**/

    PROCEDURE split_prepare_split_lines (
        p_header_id              IN NUMBER,
        p_sub_id                 IN VARCHAR2,
        p_line_ids               IN OUT NOCOPY VARCHAR2,
        p_line_ids_changed_flg   OUT NOCOPY VARCHAR2
    ) AS

        l_line_list                    VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_rule_matched                 VARCHAR2(10);
        l_processing_line_list         VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_processing_lineid            VARCHAR2(2000);
        l_onboarding_line_list         VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_split_line_list              VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_line_provisioning_group      VARCHAR2(500);
        l_line_operation_type          VARCHAR2(500);
        l_line_ordered_item            VARCHAR2(500);
        l_split_part_action            VARCHAR2(500);
        l_split_part_hold              VARCHAR2(500);
        l_split_part_fullfill          VARCHAR2(500);
        l_send_seq_transaction_id      NUMBER := NULL;
        l_hold_seq_transaction_id      NUMBER := NULL;
        l_seq_transaction_id           NUMBER := NULL;
        l_sps_line_list                VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_tas_line_list                VARCHAR2(32767);
  /* ravelard,Bug 24801585,Oct 12,2016*/
        l_is_tas_enabled               VARCHAR2(200) := NULL;
        l_sps_transaction_id           NUMBER := NULL;
        l_sps_tas_split_flg            VARCHAR2(20);
        l_split_o_dependency_chk_flg   VARCHAR2(20);
        l_split_m_dependency_chk_flg   VARCHAR2(20);
        l_arr_rules_seq                dbms_utility.instance_table;
        l_arr_rule_id                  VARCHAR2(20);
        l_commit                       VARCHAR2(1) := 'Y';
        CURSOR c_get_provisioning_group (
            csr_line_id VARCHAR2
        ) IS SELECT
            misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') AS service_group
             FROM
            oe_order_lines_all ol
             WHERE
            ol.line_id = csr_line_id
            AND   ol.item_type_code = 'SERVICE';

        CURSOR c_get_operation_type (
            csr_line_id VARCHAR2
        ) IS SELECT DISTINCT
            pa.pricing_attribute94 AS line_operation_type
             FROM
            oe_order_price_attribs pa,
            oe_order_lines_all ol
             WHERE
            pa.pricing_attribute94 IS NOT NULL
            AND   pa.header_id = ol.header_id
            AND   ol.line_id = csr_line_id;

    BEGIN
        p_line_ids_changed_flg := 'N';
        l_split_o_dependency_chk_flg := 'Y';
        IF
            p_line_ids IS NOT NULL
        THEN
    /* We are ready to process the line list.*/
            l_line_list := p_line_ids;
        ELSE
    /* get the line list.*/
            l_line_list := split_create_line_list(p_header_id,p_sub_id);
        END IF;
  /*- IMPORTANT ----*/
  /*TODO----- OPTION to reduce time*/
  /*--- Get list of B part and compare with split-part-rule b part.*/
  /* if anything matches then do this ,otherwise skip doing this*/
  /*-*/

        IF
            regexp_count(l_line_list,',') = 0
        THEN
    /*TODO-*/
    /* If only one line,just dont do anything*/
    /* exception for this rule is if this lineId already exists in Staging,update to ready and send that line*/
            NULL;
        ELSE
    /* We have list of lines now to be processed.*/
    /* Process the lineID from line list*/
            l_rule_matched := 'N';
            l_processing_line_list := l_line_list;
            WHILE l_processing_line_list IS NOT NULL LOOP
                l_processing_lineid := regexp_substr(l_processing_line_list,'[^,]+',1,1);
                l_processing_line_list := substr(l_processing_line_list,length(regexp_substr(l_processing_line_list,'[^,]+',1,1) ) + 2);
      /* Check the line in the Staging table,*/
      /* if the line exists in any status other than invalid,which means its a OM resend.*/
      /* do*/
      /* copy the staging line*/
      /* get provisioning_group  -- Implicit Cursor*/

                SELECT
                    misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP'),
                    ol.ordered_item
                INTO
                    l_line_provisioning_group,l_line_ordered_item
                FROM
                    oe_order_lines_all ol
                WHERE
                    ol.line_id = l_processing_lineid
                    AND   ol.item_type_code = 'SERVICE';
      /* get operation_type  -- Implicit Cursor*/

                SELECT DISTINCT
                    pa.pricing_attribute94
                INTO
                    l_line_operation_type
                FROM
                    oe_order_price_attribs pa,
                    oe_order_lines_all ol
                WHERE
                    pa.pricing_attribute94 IS NOT NULL
                    AND   pa.header_id = ol.header_id
                    AND   ol.line_id = l_processing_lineid;

      /*' l_line_provisioning_group : ' || l_line_provisioning_group || ' l_line_ordered_item : ' || l_line_ordered_item);*/
      /* Got the Operation Type and Provisioning Group*/

                FOR split_part_rule IN (
                    SELECT
                        part_rule_seq,
                        part_number,
                        part_dependency,
                        optional_part_dependency,
                        new_operation_type,
                        nvl(hold,'Y') hold,
                        nvl(fullfillment_chg,'Y') fullfillment_chg
                    FROM
                        apxiimd.misimd_tas_split_part_rule
                    WHERE
                        enabled = 'Y'
                        AND   provisioning_group = l_line_provisioning_group
                        AND   operation_type = DECODE(operation_type,'ALL','ALL',l_line_operation_type)
                        AND   part_number = DECODE(part_number,'ALL','ALL',l_line_ordered_item)
                    ORDER BY
                        rule_rank ASC
                ) LOOP

        /* Do dependency Check here*/
                    IF
                        split_part_rule.part_dependency IS NULL
                    THEN
                        l_split_m_dependency_chk_flg := 'Y';
                    ELSE
                        l_split_m_dependency_chk_flg := 'N';
                        SELECT
                            DECODE(COUNT(1),0,'Y','N')
                        INTO
                            l_split_m_dependency_chk_flg
                        FROM
                            (
                                SELECT
                                    a.dep_group,
                                    b.provisioninggroup,
                                    c.ordered_item
                                FROM
                                    (
                                        SELECT
                                            TRIM(regexp_substr(split_part_rule.part_dependency,'[^,]+',1,level) ) dep_group
                                        FROM
                                            dual
                                        CONNECT BY
                                            regexp_substr(split_part_rule.part_dependency,'[^,]+',1,level) IS NOT NULL
                                    ) a,
                                    (
                                        SELECT
                                            misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') provisioninggroup
                                        FROM
                                            oe_order_lines_all ol
                                        WHERE
                                            ol.line_id IN (
                                                SELECT
                                                    TRIM(regexp_substr(p_line_ids,'[^,]+',1,level) ) str
                                                FROM
                                                    dual
                                                CONNECT BY
                                                    regexp_substr(p_line_ids,'[^,]+',1,level) IS NOT NULL
                                            )
                                            AND   ol.item_type_code = 'SERVICE'
                                    ) b,
                                    (
                                        SELECT
                                            ol.ordered_item
                                        FROM
                                            oe_order_lines_all ol
                                        WHERE
                                            ol.line_id IN (
                                                SELECT
                                                    TRIM(regexp_substr(p_line_ids,'[^,]+',1,level) ) str
                                                FROM
                                                    dual
                                                CONNECT BY
                                                    regexp_substr(p_line_ids,'[^,]+',1,level) IS NOT NULL
                                            )
                                            AND   ol.item_type_code = 'SERVICE'
                                    ) c
                                WHERE
                                    a.dep_group = b.provisioninggroup (+)
                                    AND   a.dep_group = c.ordered_item (+)
                            )
                        WHERE
                            provisioninggroup IS NULL
                            AND   ordered_item IS NULL;

                    END IF;
        /* If the dependency is not null*/

                    IF
                        split_part_rule.part_dependency IS NULL AND split_part_rule.optional_part_dependency IS NOT NULL
                    THEN
                        l_split_o_dependency_chk_flg := 'N';
          /*- find any one dependency part in the line list.*/
          /* either service group or part number,if any one exists in the line list then make it pass thru*/
                        SELECT
                            DECODE(COUNT(1),0,'N','Y')
                        INTO
                            l_split_o_dependency_chk_flg
                        FROM
                            (
                                SELECT
                                    a.dep_group,
                                    b.provisioninggroup
                                FROM
                                    (
                                        SELECT
                                            TRIM(regexp_substr(split_part_rule.optional_part_dependency,'[^,]+',1,level) ) dep_group
                                        FROM
                                            dual
                                        CONNECT BY
                                            regexp_substr(split_part_rule.optional_part_dependency,'[^,]+',1,level) IS NOT NULL
                                    ) a,
                                    (
                                        SELECT
                                            misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') provisioninggroup,
                                            ol.ordered_item
                                        FROM
                                            oe_order_lines_all ol
                                        WHERE
                                            ol.line_id IN (
                                                SELECT
                                                    TRIM(regexp_substr(p_line_ids,'[^,]+',1,level) ) str
                                                FROM
                                                    dual
                                                CONNECT BY
                                                    regexp_substr(p_line_ids,'[^,]+',1,level) IS NOT NULL
                                            )
                                            AND   ol.item_type_code = 'SERVICE'
                                    ) b
                                WHERE
                                    ( a.dep_group = b.ordered_item )
                                    OR   ( a.dep_group = b.provisioninggroup )
                            )
                        WHERE
                            provisioninggroup IS NOT NULL;

                    ELSE
                        l_split_o_dependency_chk_flg := 'Y';
                    END IF;

                    IF
                        l_split_m_dependency_chk_flg = 'Y' AND l_split_o_dependency_chk_flg = 'Y'
                    THEN
          /*Since part number found,mark the out variable as Changed_line_list*/
                        IF
                            l_rule_matched <> 'Y'
                        THEN
                            l_rule_matched := 'Y';
                        END IF;
          /* Get the action to be done for this part number*/
                        BEGIN
                            IF
                                l_arr_rules_seq.EXISTS(split_part_rule.part_rule_seq)
                            THEN
              /* 'OK,element # exists.'*/
                                l_seq_transaction_id := l_arr_rules_seq(split_part_rule.part_rule_seq).inst_number;
                            ELSE
              /*'OK,element # does not exist at all.'*/
                                l_seq_transaction_id := misimd_om_tas_grouping_trans.nextval;
                                l_arr_rules_seq(split_part_rule.part_rule_seq).inst_number := l_seq_transaction_id;
                                l_arr_rules_seq(split_part_rule.part_rule_seq).inst_name := split_part_rule.hold;
                            END IF;

                        EXCEPTION
                            WHEN OTHERS THEN
            /* on any error,create new transaction and go thru*/
                                l_seq_transaction_id := misimd_om_tas_grouping_trans.nextval;
                        END;
          /*
          IF l_split_part_hold             ='Y' THEN
          l_hold_seq_transaction_id := misimd_om_tas_grouping_trans.nextval;
          l_seq_transaction_id          := l_hold_seq_transaction_id;
          ELSIF l_send_seq_transaction_id IS NULL AND l_split_part_hold = 'N' THEN
          l_send_seq_transaction_id := misimd_om_tas_grouping_trans.nextval;
          l_seq_transaction_id          := l_send_seq_transaction_id;
          ELSIF l_send_seq_transaction_id IS NOT NULL AND l_split_part_hold = 'N' THEN
          l_seq_transaction_id          := l_send_seq_transaction_id;
          END IF; */
          /* Insert this lineID into Stage table*/

                        split_insert_split_line(l_processing_lineid,NULL,split_part_rule.new_operation_type,split_part_rule.hold,split_part_rule.fullfillment_chg,l_seq_transaction_id
);
          /**/
          /**/
          /*- since line split happening,set sequence null from consolidation table for this line*/
          /**/

                        UPDATE misimd_om_tas_groups_tbl
                            SET
                                comments = 'Rule Matched,moved to Split Staging,so Removed from '
                                || group_sequence_id,
                                group_sequence_id = NULL
                        WHERE
                            header_id = p_header_id
                            AND   line_id = l_processing_lineid;
          /* commit changes*/

                        BEGIN
                            SELECT
                                lookup_value
                            INTO
                                l_commit
                            FROM
                                oss_intf_user.misimd_intf_lookup
                            WHERE
                                application = 'MISIMD_TAS_CLOUD_WF'
                                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                                AND   upper(lookup_code) = 'PROCEDURE_SPLIT_TRANSACTION_COMMIT'
                                AND   enabled = 'Y';

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_commit := 'Y';
                        END;

                        IF
                            l_commit = 'Y'
                        THEN
                            COMMIT;
                        END IF;
          /* ---- COPY the staging line if the line already exists in the table,make a new txn for matching lines*/
          /**/
          /*Check for the rules ,if matched,append line_id to the l_processed_line_list*/
                        IF
                            l_split_line_list IS NULL
                        THEN
                            l_split_line_list := l_processing_lineid;
                        ELSE
                            l_split_line_list := l_split_line_list
                            || ','
                            || l_processing_lineid;
                        END IF;

                    ELSE
                        IF
                            l_onboarding_line_list IS NULL
                        THEN
                            l_onboarding_line_list := l_processing_lineid;
                        ELSE
                            l_onboarding_line_list := l_onboarding_line_list
                            || ','
                            || l_processing_lineid;
                        END IF;
                    END IF;
        /*
        IF l_onboarding_line_list IS NULL THEN
        l_onboarding_line_list  := l_processing_lineid;
        ELSE
        l_onboarding_line_list := l_onboarding_line_list ||','||l_processing_lineid;
        END IF;
        */

                    EXIT WHEN l_rule_matched = 'Y';
                END LOOP;
      /*set the l_rule_matched,if the rules matched for any id with the rule set*/

                IF
                    l_rule_matched <> 'Y'
                THEN
                    IF
                        l_onboarding_line_list IS NULL
                    THEN
                        l_onboarding_line_list := l_processing_lineid;
                    ELSE
                        l_onboarding_line_list := l_onboarding_line_list
                        || ','
                        || l_processing_lineid;
                    END IF;
                END IF;

                IF
                    l_rule_matched = 'Y'
                THEN
                    p_line_ids_changed_flg := 'Y';
                    p_line_ids := l_onboarding_line_list;
                END IF;
            END LOOP;
    /*- Split into   TAS ans SPS payload*/
    /*if above rules matched,use the onboarding list otherwise use the line list*/

            BEGIN
                SELECT
                    enabled
                INTO
                    l_sps_tas_split_flg
                FROM
                    "APXIIMD"."MISIMD_TAS_SPLIT_PART_RULE"
                WHERE
                    provisioning_group = 'ALL'
                    AND   operation_type IN (
                        'ONBOARDING',
                        'PILOT_ONBOARDING'
                    )
                    AND   part_number = 'EXCEPTION'
                    AND   rule_name = 'EXCEPTION_SPS_TAS_SPLIT';

            EXCEPTION
                WHEN OTHERS THEN
                    l_sps_tas_split_flg := 'N';
            END;

            IF
                l_sps_tas_split_flg = 'Y'
            THEN
                IF
                    l_rule_matched = 'Y'
                THEN
                    l_processing_line_list := l_onboarding_line_list;
                ELSE
                    l_processing_line_list := l_line_list;
                END IF;

                WHILE l_processing_line_list IS NOT NULL LOOP
                    l_processing_lineid := regexp_substr(l_processing_line_list,'[^,]+',1,1);
                    l_processing_line_list := substr(l_processing_line_list,length(regexp_substr(l_processing_line_list,'[^,]+',1,1) ) + 2);

                    l_is_tas_enabled := nvl(misont_cloud_pub2.get_order_line_info(l_processing_lineid,'IS_SERVICE_TAS_ENABLED'),'-999');
                    IF
                        l_is_tas_enabled = 'Y'
                    THEN
                        IF
                            l_tas_line_list IS NULL
                        THEN
                            l_tas_line_list := l_processing_lineid;
                        ELSE
                            l_tas_line_list := l_tas_line_list
                            || ','
                            || l_processing_lineid;
                        END IF;
                    ELSE
                        IF
                            l_sps_line_list IS NULL
                        THEN
                            l_sps_line_list := l_processing_lineid;
                        ELSE
                            l_sps_line_list := l_sps_line_list
                            || ','
                            || l_processing_lineid;
                        END IF;
                    END IF;

                END LOOP;
      /**/
      /*-- send the tas list back to GET_PAYLOAD*/
      /*-*/

                IF
                    l_sps_line_list IS NOT NULL AND l_tas_line_list IS NOT NULL
                THEN
        /* to return to get_payload*/
                    p_line_ids_changed_flg := 'Y';
                    p_line_ids := l_tas_line_list;
        /* end to return to get_payload*/
        /*this is to update the waitiong on lines*/
                    l_onboarding_line_list := l_tas_line_list;
        /*this is to loop and insert the sps lines*/
                    l_processing_line_list := l_sps_line_list;
        /* get a new seq for SPS line group*/
                    l_sps_transaction_id := misimd_om_tas_grouping_trans.nextval;
        /**/
        /*- Send the l_sps_line_list to Split stage*/
        /**/
                    WHILE l_processing_line_list IS NOT NULL LOOP
                        l_processing_lineid := regexp_substr(l_processing_line_list,'[^,]+',1,1);
                        l_processing_line_list := substr(l_processing_line_list,length(regexp_substr(l_processing_line_list,'[^,]+',1,1) ) + 2);

                        split_insert_split_line(l_processing_lineid,NULL,NULL,'N','N',l_sps_transaction_id);
          /**/
          /*- SPS lines remove sequence tham from consolidation table*/
          /**/
                        UPDATE misimd_om_tas_groups_tbl
                            SET
                                comments = 'SPS enabled,so Removed from '
                                || group_sequence_id,
                                group_sequence_id = NULL
                        WHERE
                            header_id = p_header_id
                            AND   line_id = l_processing_lineid;
          /* commit changes*/

                        IF
                            l_commit = 'Y'
                        THEN
                            COMMIT;
                        END IF;
                    END LOOP;
        /* Send the payload if l_SPS_transaction_id is not null*/

                    IF
                        l_sps_transaction_id IS NOT NULL
                    THEN
                        split_send_split_payload(p_trx_id => l_sps_transaction_id,p_dbms_flag => 'Y');
                    END IF;

                END IF;

            END IF;
    /*- END of Split TAS and SPS payload*/

            IF
                l_rule_matched = 'Y'
            THEN
      /* Update the Waiting on Column in the staging table now*/
                NULL;
            END IF;
    /* Send the payload for all HOLD transaction_id*/
            l_arr_rule_id := l_arr_rules_seq.first;
            WHILE l_arr_rule_id IS NOT NULL LOOP
                IF
                    l_arr_rules_seq(l_arr_rule_id).inst_name = 'N'
                THEN
                    split_send_split_payload(p_trx_id => l_arr_rules_seq(l_arr_rule_id).inst_number,p_dbms_flag => 'Y');
                ELSE
                    UPDATE apxiimd.misimd_tas_split_stage
                        SET
                            waiting_on = l_onboarding_line_list
                    WHERE
                        header_id = p_header_id
                        AND   transaction_id = l_arr_rules_seq(l_arr_rule_id).inst_number
                        AND   status = l_split_status_n;
        /* commit changes*/

                    IF
                        l_commit = 'Y'
                    THEN
                        COMMIT;
                    END IF;
                END IF;

                l_arr_rule_id := l_arr_rules_seq.next(l_arr_rule_id);
            END LOOP;

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_line_ids := p_line_ids;
            p_line_ids_changed_flg := 'N';
    END split_prepare_split_lines;
/**/
/* Will insert the row in staging table .*/
/**/

    PROCEDURE split_insert_split_line (
        p_line_id                  IN VARCHAR2,
        p_waiting_on               IN VARCHAR2,
        p_staging_operation_type   IN VARCHAR2,
        p_hold                     IN VARCHAR2,
        p_fullfillment_chg         IN VARCHAR2,
        p_transaction_id           IN NUMBER
    ) AS
        l_status   VARCHAR2(100) := NULL;
        l_commit   VARCHAR2(1) := 'Y';
    BEGIN
  /* update the staging table ,for any existing transaction for header and line combination*/
  /* if so,update the status to INVALID for the whole transaction.*/
        UPDATE apxiimd.misimd_tas_split_stage
            SET
                status = status
                || '_INVALID',
                last_updated_date = SYSDATE
        WHERE
            transaction_id IN (
                SELECT DISTINCT
                    transaction_id
                FROM
                    apxiimd.misimd_tas_split_stage
                WHERE
                    line_id = p_line_id
                    AND   status NOT LIKE '%INVALID%'
            );
  /* commit changes*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'UPDATE_MISIMD_TAS_SPLIT_STAGE'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;

        IF
            l_commit = 'Y'
        THEN
            COMMIT;
        END IF;
  /*-*/
        INSERT INTO apxiimd.misimd_tas_split_stage (
            transaction_id,
            order_number,
            header_id,
            line_id,
            subscription_id,
            provisioning_group,
            fulfilment_set,
            om_operation_type,
            staging_operation_type,
            status,
            comments,
            created_date,
            last_updated_date,
            waiting_on,
            ordered_item,
            hold,
            fullfillment_chg
        )
            SELECT
                p_transaction_id,
                oh.order_number,
                oh.header_id,
                ol.line_id,
                op.pricing_attribute92 subscription_id,
                substr(oes.set_name,1,instr(oes.set_name,'-') - 1) service_group,
                oes.set_name fulfillment_set,
                op.pricing_attribute94 om_operation_type,
                nvl(p_staging_operation_type,op.pricing_attribute94) staging_operation_type,
                DECODE(p_hold,'Y',l_split_status_n,'N',l_split_status_r) status,
                NULL comments,
                SYSDATE created_date,
                SYSDATE last_updated_date,
                p_waiting_on waiting_on,
                ol.ordered_item,
                p_hold,
                p_fullfillment_chg
            FROM
                oe_order_lines_all ol,
                oe_order_price_attribs op,
                oe_sets oes,
                oe_line_sets sln,
                oe_order_headers_all oh
            WHERE
                1 = 1
                AND   oes.set_id = sln.set_id
                AND   oes.set_type = 'FULFILLMENT_SET'
                AND   sln.line_id = ol.service_reference_line_id
                AND   ol.header_id = oh.header_id
                AND   op.line_id = ol.service_reference_line_id
                AND   op.header_id = oh.header_id
                AND   ol.item_type_code = 'SERVICE'
                AND   ol.line_id = p_line_id
                AND   (
                    EXISTS (
                        SELECT
                            1
                        FROM
                            wf_item_activity_statuses s,
                            wf_process_activities p
                        WHERE
                            s.process_activity = p.instance_id
                            AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                            AND   s.item_type = 'OEOL'
                            AND   s.item_key = TO_CHAR(ol.line_id)
                    )
                    AND   NOT EXISTS (
                        SELECT
                            1
                        FROM
                            oe_order_lines_all
                        WHERE
                            line_id = ol.line_id
                            AND   flow_status_code IN (
                                'CLOSED',
                                'CANCELLED'
                            )
                    )
                );
  /* commit changes*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'INSERT_MISIMD_TAS_SPLIT_STAGE'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;

        IF
            l_commit = 'Y'
        THEN
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END split_insert_split_line;
/**/
/* Create line list from OE_lines/header and return it back*/
/**/

    FUNCTION split_create_line_list (
        p_header_id   IN NUMBER,
        p_sub_id      IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_line_list   VARCHAR2(2000);
    BEGIN
        IF
            p_sub_id IS NOT NULL
        THEN
    /* Get all the lines from HEADER_ID and SUB_ID combination*/
            NULL;
        ELSE
    /* get all the lines from HEADER_ID*/
            NULL;
        END IF;
        SELECT
            LISTAGG(ol.line_id,
            ',') WITHIN GROUP(
            ORDER BY
                op.pricing_attribute92,
                ol.line_id
            ) line_list
        INTO
            l_line_list
        FROM
            oe_order_lines_all ol,
            oe_order_price_attribs op,
            oe_sets oes,
            oe_line_sets sln,
            oe_order_headers_all oh
        WHERE
            1 = 1
            AND   oes.set_id = sln.set_id
            AND   oes.set_type = 'FULFILLMENT_SET'
            AND   sln.line_id = ol.service_reference_line_id
            AND   ol.header_id = oh.header_id
            AND   op.line_id = ol.service_reference_line_id
            AND   op.header_id = oh.header_id
            AND   ol.item_type_code = 'SERVICE'
            AND   oh.header_id = p_header_id
            AND   op.pricing_attribute92 = nvl(p_sub_id,op.pricing_attribute92)
            AND   (
                EXISTS (
                    SELECT
                        1
                    FROM
                        wf_item_activity_statuses s,
                        wf_process_activities p
                    WHERE
                        s.process_activity = p.instance_id
                        AND   p.activity_name = 'CLOUD_TAS_INTERFACE'
                        AND   s.item_type = 'OEOL'
                        AND   s.item_key = TO_CHAR(ol.line_id)
                )
                AND   NOT EXISTS (
                    SELECT
                        1
                    FROM
                        oe_order_lines_all
                    WHERE
                        line_id = ol.line_id
                        AND   flow_status_code IN (
                            'CLOSED',
                            'CANCELLED'
                        )
                )
            );
  /*- TODO: Operation Type should be conisdered case goes here,if so*/

        RETURN l_line_list;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END split_create_line_list;

    PROCEDURE split_concurrent_pgm (
        p_transaction_id NUMBER
    ) IS
  /**/
  /*PRAGMA AUTONOMOUS_TRANSACTION;*/
  /**/

        v_user_id      NUMBER;
        v_app_id       NUMBER;
        v_resp_id      NUMBER;
        v_resp_name    VARCHAR2(100);
        v_request_id   NUMBER;
        v_app_name     VARCHAR2(20);
        l_commit       VARCHAR2(1) := 'Y';
    BEGIN
        fnd_file.put_line(fnd_file.log,'*** Call The  Program  ***');
        fnd_file.put_line(fnd_file.log,'transaction id currently being processed : '
        || p_transaction_id);
  /*    log_errors (p_error_message => '   transaction id currently being processed   :  ' || p_transaction_id);*/
        BEGIN
            SELECT
                user_id
            INTO
                v_user_id
            FROM
                fnd_user
            WHERE
                upper(user_name) = upper('vetri.srinivasan@oracle.com');

            fnd_file.put_line(fnd_file.log,'got user id : ');
        EXCEPTION
            WHEN OTHERS THEN
                v_user_id := NULL;
                fnd_file.put_line(fnd_file.log,'error in getting user id : ');
        END;

        BEGIN
            SELECT
                fa.application_id,
                fr.responsibility_id,
                fr.responsibility_name,
                fa.application_short_name
            INTO
                v_app_id,v_resp_id,v_resp_name,v_app_name
            FROM
                fnd_responsibility_vl fr,
                fnd_application fa
            WHERE
                responsibility_name LIKE 'ADIT_INTEGRATION'
                AND   fr.application_id = fa.application_id;

            fnd_file.put_line(fnd_file.log,'recevied responsibility : ');
        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'error in getting responsibility: ');
                v_app_id := NULL;
                v_resp_id := NULL;
                v_resp_name := NULL;
                v_app_name := NULL;
        END;
  /*log_errors (p_error_message => 'Inside the concurretn pgm' || p_transaction_id);*/
  /* Initializing apps*/

        fnd_global.apps_initialize(user_id => v_user_id,resp_id => v_resp_id,resp_appl_id => v_app_id);
  /*-- set or Change parameters here*/
  /* Use transaction id as is*/
  /* Submit Request*/
  /*  SPLIT_INITIATE_SEND( l_errbuf ,l_retcode,to_number(each_transaction.stg_trans),'SPLIT_SEND',NULL,NULL,NULL ,'Y');*/

        v_request_id := fnd_request.submit_request(v_app_name,'MISIMDSPLITPAYLOAD',p_transaction_id,SYSDATE,false,argument1 => p_transaction_id,argument2 => 'SPLIT_SEND'
,argument3 => NULL,argument4 => NULL,argument5 => NULL,argument6 => 'Y');
  /* Update the conccurrent pgm in Staging table*/

        fnd_file.put_line(fnd_file.log,' request id  : '
        || v_request_id);
  /*    log_errors (p_error_message => '   CC PGM ID  :  ' || v_request_id);*/
        UPDATE apxiimd.misimd_tas_split_stage
            SET
                cc_request_id = nvl(v_request_id,0)
        WHERE
            transaction_id = p_transaction_id;
  /*log_errors (p_error_message => 'v_request_id  -- ' || v_request_id);*/
  /* this commit is needed for CC PGM - dont remove*/
  /* commit changes*/

        BEGIN
            SELECT
                lookup_value
            INTO
                l_commit
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'MISIMD_TAS_CLOUD_WF'
                AND   component = 'MISIMD_COMMIT_TAS_GRP'
                AND   upper(lookup_code) = 'UPDATE_MISIMD_TAS_SPLIT_CP'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_commit := 'Y';
        END;

        IF
            l_commit = 'Y'
        THEN
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'*** error in The  Program  ***');
    END split_concurrent_pgm;
/*-==================== END OF SPLIT CODE =============*/

    PROCEDURE manage_tas_lines (
        p_tas_outbound_payload   IN XMLTYPE,
        p_header_id              IN NUMBER,
        p_source                 IN VARCHAR,
        p_status                 OUT NOCOPY VARCHAR,
        p_message                OUT NOCOPY VARCHAR
    ) AS

        l_line_id                     VARCHAR2(20);
        l_removed_line                VARCHAR2(200);
        l_concat_line_id              VARCHAR2(1500);
        l_order_number                VARCHAR2(1500);
        l_subscription_id             VARCHAR2(1500);
        l_operation_type              VARCHAR2(1500);
        l_provisioning_order_number   VARCHAR2(1500);
        l_removed_line_list           VARCHAR2(1500);
        l_status                      VARCHAR2(1500);
        l_key_id                      VARCHAR2(1500);
        v_code                        NUMBER;
        v_errm                        VARCHAR2(64);
        l_temp_payload                VARCHAR2(30000);
        lines_count                   NUMBER;
        update_flag                   VARCHAR2(2);
    BEGIN
  /* Parse All key elements from TAS Payload to finally insert into  APXIIMD.MISIMD_SKIP_TAS_PROV_LINES table*/
        l_provisioning_order_number := p_tas_outbound_payload.extract('InputParameters/I_ORDER/ORDER_NUMBER/text()').getstringval ();
        FOR xmlrow IN (
            SELECT
                column_value AS xml
            FROM
                TABLE ( xmlsequence(p_tas_outbound_payload.extract('/InputParameters/I_ORDER/PROPERTIES/PROPERTIES_ITEM') ) )
        ) LOOP
            SELECT
                upper(extractvalue(xmlrow.xml,'PROPERTIES_ITEM/KEY') )
            INTO
                l_key_id
            FROM
                dual;
    /* insert into yuva_temp (id,text) values (2,l_key_id);*/
    /* l_orig_sys_ref := '''' || innerxmlrow.xml.getstringval() || '''';*/

            IF
                ( l_key_id = '$$OM_ORDER_NUMBER$$' )
            THEN
                SELECT
                    upper(extractvalue(xmlrow.xml,'/PROPERTIES_ITEM//VALUE') )
                INTO
                    l_order_number
                FROM
                    dual;

            END IF;

            IF
                ( l_key_id = '$$OM_OPERATION_TYPE$$' )
            THEN
                SELECT
                    upper(extractvalue(xmlrow.xml,'/PROPERTIES_ITEM//VALUE') )
                INTO
                    l_operation_type
                FROM
                    dual;

            END IF;

        END LOOP;

        FOR linexmlrow IN (
            SELECT
                column_value AS xml
            FROM
                TABLE ( xmlsequence(p_tas_outbound_payload.extract('/InputParameters/I_ORDER/LINE_ITEMS/LINE_ITEMS_ITEM') ) )
        ) LOOP
            SELECT
                upper(extractvalue(linexmlrow.xml,'LINE_ITEMS_ITEM/LINE_ID') )
            INTO
                l_line_id
            FROM
                dual;
    /* insert into yuva_temp (id,text) values (3,l_line_id);*/

            SELECT
                upper(extractvalue(linexmlrow.xml,'LINE_ITEMS_ITEM/SUBSCRIPTION_ID') )
            INTO
                l_subscription_id
            FROM
                dual;

            l_removed_line_list := '';
            FOR innerxmlrow IN (
                SELECT
                    column_value AS xml
      /* FROM TABLE(XMLSequence(xmlrow.xml.EXTRACT('PRMOrderLine/column[@name="PROPERTIES"]')))*/
                FROM
                    TABLE ( xmlsequence(linexmlrow.xml.extract('LINE_ITEMS_ITEM/SERVICE_COMPONENTS/SERVICE_COMPONENTS_ITEM') ) )
            ) LOOP
                SELECT
                    upper(extractvalue(innerxmlrow.xml,'SERVICE_COMPONENTS_ITEM/LINE_ID') )
                INTO
                    l_removed_line
                FROM
                    dual;

                l_removed_line_list := l_removed_line_list
                || l_removed_line
                || ',';
      /* l_orig_sys_ref := '''' || innerxmlrow.xml.getstringval() || '''';*/
            END LOOP;

            SELECT
                substr(l_removed_line_list,1,instr(l_removed_line_list,',',-1) - 1)
            INTO
                l_removed_line_list
            FROM
                dual;
    /*  UPDATE APPS.OM_SUB_ID_TEMP
    SET SUBID   = l_new_subscription_id ,
    DATACENTER= l_new_datacenter
    WHERE lineid= l_line_id; */

            SELECT
                COUNT(provlines.line_id)
            INTO
                lines_count
            FROM
                misimd_skip_tas_prov_lines provlines
            WHERE
                1 = 1
                AND   provlines.line_id = l_line_id;

            IF
                lines_count > 0
            THEN
                update_flag := 'Y';
            ELSE
                update_flag := 'N';
            END IF;

            IF
                ( update_flag = 'Y' )
            THEN
                UPDATE misimd_skip_tas_prov_lines
                    SET
                        status = 'AWAIT_PROVISIONING_RETRIED',
                        sent_time = SYSDATE,
                        last_updated_date = SYSDATE
                WHERE
                    line_id = l_line_id;

            END IF;

            INSERT INTO misimd_skip_tas_prov_lines (
                line_id,
                header_id,
                order_number,
                subscription_id,
                operation_type,
                provisioning_order_number,
                removed_line_list,
                status,
                sent_time,
                provisioned_date,
                last_updated_date
            ) VALUES (
                l_line_id,
                p_header_id,
                l_order_number,
                l_subscription_id,
                l_operation_type,
                l_provisioning_order_number,
                l_removed_line_list,
                'AWAIT_PROVISIONING',
                SYSDATE,
                NULL,
                SYSDATE
            );

        END LOOP;

        p_status := 'COMPLETED';
    EXCEPTION
        WHEN OTHERS THEN
            misimd_audit.intf_log(p_transaction_reference => l_provisioning_order_number,p_audit_message => 'Exception '
            || sqlerrm,p_audit_level => NULL,p_application => 'MISIMD_MANAGE_TAS_PROV_LINES',p_component => NULL,p_module => NULL,p_timestamp => SYSDATE,p_context_name1 => NULL
,p_context_id1 => l_order_number,p_context_name2 => NULL,p_context_id2 => NULL,p_context_name3 => NULL,p_context_id3 => NULL,p_platform => NULL,p_audit_attachment => NULL,errbuf => p_status);

            p_status := 'ERROR';
    END manage_tas_lines;
/*16.12 SPS Move*/

    FUNCTION get_provisioning_system (
        p_service_group   IN VARCHAR2 DEFAULT NULL,
        p_line_id         IN VARCHAR2 DEFAULT NULL,
        p_line_ids        IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value              VARCHAR2(2000) := NULL;
        l_default_tas_flag   VARCHAR2(50) := NULL;
    BEGIN
        BEGIN
            SELECT
                lookup_value
            INTO
                l_default_tas_flag
            FROM
                oss_intf_user.misimd_intf_lookup
            WHERE
                application = 'PROVISIONING_SYSTEM'
                AND   component = 'PROVISIONING_SYSTEM'
                AND   upper(lookup_code) = 'PROVISIONING_SYSTEM'
                AND   enabled = 'Y';

        EXCEPTION
            WHEN OTHERS THEN
                l_default_tas_flag := 'SPS';
        END;
  /* Fetch the lookup to check if SPS/TAS*/
  /* If TAS,just pass the value back*/
  /* If Other than TAS derive the value and pass the value*/

        IF
            ( l_default_tas_flag = 'TAS' )
        THEN
            l_value := l_default_tas_flag;
        ELSIF ( p_service_group IS NOT NULL ) THEN
            SELECT DISTINCT
                provisioning_system
                || '-'
                || order_flow_code l_provisioning_system
            INTO
                l_value
            FROM
                apxiimd.misimd_sps_production_grp_map
            WHERE
                enabled = 'Y'
                AND   ROWNUM = 1
                AND   upper(gsi_service_group_name) = p_service_group;

        ELSIF ( p_line_id IS NOT NULL ) THEN
            SELECT DISTINCT
                provisioning_system
                || '-'
                || order_flow_code l_provisioning_system
            INTO
                l_value
            FROM
                oe_order_lines_all ol,
                apxiimd.misimd_sps_production_grp_map map
            WHERE
                ol.line_id = to_number(p_line_id)
                AND   upper(map.gsi_service_group_name) = misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP')
                AND   ROWNUM = 1;

        ELSIF ( p_line_ids IS NOT NULL ) THEN
            SELECT
                upper(l_provisioning_system)
            INTO
                l_value
            FROM
                (
                    SELECT DISTINCT
                        provisioning_system
                        || '-'
                        || order_flow_code l_provisioning_system,
                        misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP')
                    FROM
                        oe_order_lines_all ol,
                        apxiimd.misimd_sps_production_grp_map map
                    WHERE
                        upper(map.gsi_service_group_name) = misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP')
                        AND   ol.line_id IN (
                            SELECT
                                to_number(regexp_substr(p_line_ids,'[^,]+',1,level) ) AS lineid
                            FROM
                                dual
                            CONNECT BY
                                level <= regexp_count(p_line_ids,'[^,]+')
                        )
                    ORDER BY
                        CASE
                            WHEN l_provisioning_system LIKE 'SPS%M%' THEN 1
                            WHEN l_provisioning_system LIKE 'SPS%A%' THEN 2
                            WHEN l_provisioning_system LIKE 'TAS%M%' THEN 3
                            WHEN l_provisioning_system LIKE 'TAS%A%' THEN 4
                            WHEN l_provisioning_system LIKE 'TAS%P%' THEN 5
                            ELSE 6
            /*Need to check if any other cases need to be handled*/
                        END
                ) a
            WHERE
                ROWNUM = 1;

        END IF;

        IF
            ( l_value IS NULL OR l_value = '-' )
        THEN
            l_value := l_default_tas_flag;
        END IF;

        RETURN l_value;
    EXCEPTION
        WHEN OTHERS THEN
            l_value := l_default_tas_flag;
            RETURN l_value;
    END get_provisioning_system;

    FUNCTION get_subscription_info (
        spmsub misimd_subid_collection
    ) RETURN misimd_subid_collection IS
        errb     VARCHAR2(1000);
        output   misimd_subid_collection;
    BEGIN
        output := spmsub;
        FOR i IN 1..output.count LOOP
            output(i).provisioningsystem := misimd_tas_cloud_wf.get_provisioning_system(output(i).provisioninggroup);

            output(i).issubscriptionenabled := misont_cloud_pub2.is_subscription_tas_enabled(output(i).subid);

        END LOOP;

        RETURN output;
    EXCEPTION
        WHEN OTHERS THEN
            insert_error(1900,sqlerrm,'TERMINATION_GET_SUB_INFO','SPM TAS Termination GSI Lookup',1900,errb);
            RAISE;
    END get_subscription_info;
	
	
	PROCEDURE update_rebate_table(
      p_header_id      IN NUMBER ,
      p_line_id        IN NUMBER ,
      p_sub_id         IN NUMBER ,
      p_prov_date      IN VARCHAR2,
      p_status OUT NOCOPY  VARCHAR,
      p_message OUT  NOCOPY VARCHAR )
  IS
    l_event_name VARCHAR2(200) := 'oracle.apps.misecx.ont.statuschange.update';
    l_line_id VARCHAR2(200);
    l_sub_id VARCHAR2(200);
    l_operation_type VARCHAR2(200);
  BEGIN
    IF p_prov_date IS NOT NULL THEN
  BEGIN
    BEGIN
      SELECT LINE_ID,
        PRICING_ATTRIBUTE92 ,
        PRICING_ATTRIBUTE94
      INTO l_line_id,
        l_sub_id,
        l_operation_type
      FROM
        (SELECT op.line_id,
          op.pricing_attribute92,
          op.pricing_attribute94
        FROM oe_order_price_attribs op,
          oe_order_headers_all ooh
        WHERE pricing_attribute92 = p_sub_id
        AND op.header_id          = p_header_id
        AND op.header_id          = ooh.header_id
        AND op.line_id            = p_line_id
        AND ( EXISTS
          (SELECT 1
          FROM fnd_lookup_values flv
          WHERE flv.lookup_type = 'SALES_CHANNEL'
          AND flv.language      = 'US'
          AND flv.attribute3    = 'Y'
          AND flv.lookup_code   = ooh.sales_channel_code
          )
        OR EXISTS
          (SELECT 1
          FROM oe_agreements_b a,
            fnd_lookup_values c
          WHERE a.agreement_id = ooh.agreement_id
          AND c.lookup_code    = a.agreement_type_code
          AND c.lookup_type    = 'QP_AGREEMENT_TYPE'
          AND c.language       = 'US'
          AND c.attribute2     = 'Y'
          )
        OR EXISTS
          /*16.12 MSP Changes */
          (
          SELECT 1
          FROM misont_order_line_attribs_ext ext
          WHERE ext.header_id                = p_header_id
          AND upper(ext.additional_column28) = 'MSP'
            /*Partner Transaction Type*/
          ) )
        AND NOT EXISTS
          (SELECT 1
          FROM misozf.misozf_cloud_interface mci
          WHERE mci.om_line_id             = op.line_id
          AND TO_CHAR(mci.subscription_id) = op.pricing_attribute92
          )
        UNION
        SELECT op.line_id,
          op.pricing_attribute92,
          op.pricing_attribute94
        FROM oe_order_price_attribs op,
          oe_order_headers_all ooh
        WHERE op.header_id = p_header_id
        AND op.header_id   = ooh.header_id
        AND line_id       IN
          (SELECT p_line_id
          FROM dual
          )
        AND ( EXISTS
          (SELECT 1
          FROM fnd_lookup_values flv
          WHERE flv.lookup_type = 'SALES_CHANNEL'
          AND flv.language      = 'US'
          AND flv.attribute3    = 'Y'
          AND flv.lookup_code   = ooh.sales_channel_code
          )
        OR EXISTS
          (SELECT 1
          FROM oe_agreements_b a,
            fnd_lookup_values c
          WHERE a.agreement_id = ooh.agreement_id
          AND c.lookup_code    = a.agreement_type_code
          AND c.lookup_type    = 'QP_AGREEMENT_TYPE'
          AND c.language       = 'US'
          AND c.attribute2     = 'Y'
          )
        OR EXISTS
          /*16.12 MSP Changes */
          (
          SELECT 1
          FROM misont_order_line_attribs_ext ext
          WHERE ext.header_id                = p_header_id
          AND upper(ext.additional_column28) = 'MSP'
            /*Partner Transaction Type*/
          ) )
        AND NOT EXISTS
          (SELECT 1
          FROM misozf.misozf_cloud_interface mci
          WHERE mci.om_line_id             = op.line_id
          AND TO_CHAR(mci.subscription_id) = op.pricing_attribute92
          )
        );
        oe_order_util.raise_business_event(p_header_id => p_header_id,p_line_id => l_line_id,p_status => 'PROVISIONED',p_event_name => l_event_name);
        INSERT
        INTO misozf.misozf_cloud_interface
          (
            source,
            om_line_id,
            subscription_id,
            provision_date,
            operation_type,
            creation_date
          )
          VALUES
          (
            'SPM_PROV',
            l_line_id,
            l_sub_id,
            to_date(p_prov_date, 'mm-dd-yyyy hh24:mi:ss'),
            l_operation_type,
            SYSDATE
          );
        p_status  := 'S';
        p_message := 'SUCCESS';
        EXCEPTION  
        WHEN NO_DATA_FOUND THEN
        p_status := 'E';
        p_message := 'NO_DATA_FOUND';
        WHEN OTHERS THEN        
        p_status := 'E';
        p_message := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
		END;
	END;
	ELSE
		BEGIN
		p_status  := 'E';
		p_message := 'PROVISIONING DATE IS NULL (LINE NOT PROVISIONED) OR  PROVISIONING DATE IS NULL';
		END;
	END IF;
  END update_rebate_table;
	
END misimd_tas_cloud_wf;
/

COMMIT;

EXIT
