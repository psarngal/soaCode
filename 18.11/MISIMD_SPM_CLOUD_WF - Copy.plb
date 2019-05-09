rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
rem dbdrv: checkfile:~PROD:~PATH:~FILE

set verify off
whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback
create or replace PACKAGE BODY                                         MISIMD_SPM_CLOUD_WF AS
-- $Header: MISIMD_SPM_CLOUD_WF.plb 120.148 2018/09/21 04:40:24 psarngal noship $
-- Copyright (c) 2005, 2018  Oracle and/or its affiliates.
-- All rights reserved.
-- Version 12.0.0
-- ===========================================================================
-- Incident Bug #:
--
-- Purpose:
--
--   This package is used to create subscription in SPM from OM GSI.
--
-- Notes:
--
-- Modifications:
--
--   File     Date in
--   Version  Production  Author    Modification
--   =======  ==========  ========  ==========================================
--   120.0    2014/04/07  nitesaxe - created
--   120.69   2017/01/17  rdnagara - Bug 25341009
--   120.70   2017/01/17  rdnagara - Bug 25341009 adding hint clause to the query
--   120.75   2017/03/18  psarngal - Bug 25385746 & 25688486
--   120.77   2017/03/18  nitesaxe - Bug 25714388
--   120.80   2017/04/15  psarngal - SPM-7825 ,SPM-7586
--   120.82   2017/04/15  psarngal - Bug 25802029
--   120.83   2017/04/15  nitesaxe - NPI-115
--   120.87   2017/06/17  psarngal - SPM-8232 , SPM-8213
--   120.89   2017/06/24  psarngal - SPM-8232 , SPM-8213 ( Removed bug#26176194 fix)
--   120.90   2017/07/15  psarngal - Bug 26314070 fix
--   120.93   2017/07/29  psarngal - Bug 26176194 & 26314070fix
--   120.94   2017/08/05  nitesaxe - Bug 26143912 fix
--   120.100  2017/09/21  rdnagara - Bug 26568469 and Bug 25556168
--   120.102  2017/10/28  psarngal - SPM-7904,26934150,CF 17.10
--   120.103  2017/12/xx  psarngal - SPM Provisioning
--   120.106  2018/02/03  psarngal - CF 18.2
--   120.109  2018/03/01  rdnagara - Bug 27366815, 27476500  and 26712778
--   120.110  2018/03/17  psarngal - CF 18.3
--   120.111  2018/03/07  rdnagara - Bug changes for 27476500
--   120.112  2018/03/09  rdnagara - DURATION calculation changes for Provisioned lines
--   120.113  2018/03/15  srechand - ER27691142 ,If no line info formed,dont form payload at GSI
--   120.114  2018/04/14  psarngal - moved all the custom looksup to OSS_INTF_USER.MISIMD_INTF_LOOKUP
--   120.115  2018/04/05  srechand - FIX-27815012 - fix to not consider CLOSED/CANCEL lines to prepare payload
--   120.116  2018/04/14  nitesaxe - CF 18.4
--   120.120  2018/04/14  nitesaxe - CF 18.4 + Change to restrict entitlements based on rate card (if populated)
--   120.125  2018/05/05  psarngal - CF 18.5 + devops fix included for overage_enabled and line level end date.
--   120.131  2018/06/23  psarngal - CF 18.6 + SOA DevOPS Fix Bug 27183108
--   120.132  2018/06/30  tayala   - Enh 28130148 - Payment Method is showing PO for Invoice
--   120.139  2018/08/04  psarngal - CF 18.8 changes.
--   120.142  2018/09/22  psarngal - CF 18.9 changes.
--   120.145  2018/09/22  psarngal - CF 18.9 changes + Enh 28563087.
--   120.147  2018/09/29  psarngal - SPM-14386
--   120.151  2018/12/     psarngal - CF 18.11
-- ===========================================================================

/*- Internal helper Procedures/ Global Vars for Logging -BEGIN */
  g_tracefile_identifier VARCHAR2 (150) := 'MISIMD_SPM_CLOUD_WF' || TO_CHAR (
  sysdate, 'DDMMHHMISS');
  g_log_level      NUMBER := 12;
  g_trxn_reference NUMBER := -1;
  g_trace_enabled VARCHAR2(2) := '-';

PROCEDURE init;

PROCEDURE insert_log (
    p_module           IN VARCHAR2,
    p_audit_message    IN VARCHAR2,
    p_audit_level      IN NUMBER,
    p_context_name1    IN VARCHAR2 := NULL,
    p_context_id1      IN NUMBER   := NULL,
    p_context_name2    IN VARCHAR2 := NULL,
    p_context_id2      IN NUMBER   := NULL,
    p_context_name3    IN VARCHAR2 := NULL,
    p_context_id3      IN NUMBER   := NULL,
    p_audit_attachment IN CLOB     := NULL);
PROCEDURE insert_error (
    p_error_code    IN VARCHAR2,
    p_error_message IN VARCHAR2,
    p_module        IN VARCHAR2,
    p_context_name1 IN VARCHAR2 := NULL,
    p_context_id1   IN NUMBER   := NULL,
    p_context_name2 IN VARCHAR2 := NULL,
    p_context_id2   IN NUMBER   := NULL,
    p_context_name3 IN VARCHAR2 := NULL,
    p_context_id3   IN NUMBER   := NULL);
/*Internal helper Procedures/ Global Vars for Logging -End */


PROCEDURE prepare_notify_payload (
    p_header_id IN NUMBER ,
    p_subscription_id IN NUMBER DEFAULT NULL,
    resultout OUT nocopy VARCHAR2)
IS
  l_paramlist_t wf_parameter_list_t := NULL;
  l_order_data CLOB;
  v_wait  VARCHAR2(2) := 'N';
  v_coterm VARCHAR2(2) := 'N';
  v_coterm_master VARCHAR2(100);
  v_line_id number;
  v_operation_type VARCHAR2(100);
  v_operation_type_ct VARCHAR2(100);
  v_sub_id NUMBER;
  v_co_term_flag VARCHAR2(2) := 'Y';
  v_order_provisiong_source VARCHAR(50);
  v_spm_prov_auto_flow VARCHAR2(2) := 'N';
  SPM_LINE_COUNT NUMBER :=0;
  SPM_CHECK_FLAG  VARCHAR2(2) := 'N';

--SRECHAND CHANGES BEGIN 27815012
  CURSOR get_operation_types(p_header_id IN NUMBER, p_subscription_id IN NUMBER)
  IS
   SELECT OPERATION_TYPE
    FROM
      (SELECT oopa.pricing_attribute94 OPERATION_TYPE,
        MIN(oopa.pricing_attribute58) SEQUENCE_ID
      FROM oe_order_price_attribs oopa, oe_order_lines_all oola
      WHERE
    oopa.header_id = oola.header_id
    AND oopa.line_id = oola.line_id
    AND oopa.header_id          = p_header_id
      AND oopa.pricing_attribute92  = p_subscription_id
    AND oola.flow_status_code NOT IN ('CLOSED','CANCELLED')
      AND oopa.pricing_attribute94 IS NOT NULL
    AND oopa.pricing_attribute93  = 'PROVISIONED'
      GROUP BY oopa.pricing_attribute94
      ORDER BY SEQUENCE_ID ASC
      );
--SRECHAND CHANGES END 27815012
  v_order_number VARCHAR2(50);

BEGIN
  init;
  resultout := 'SUCCESS';
  --
  SELECT order_number
  INTO v_order_number
  FROM oe_order_headers_all
  WHERE header_id = p_header_id;

   --27691142 SRECHAND CHANGES BEGIN
  BEGIN
  select  count(1)
  into SPM_LINE_COUNT
  from MISONT_ORDER_LINE_ATTRIBS_EXT
  where header_id = p_header_id
  and (additional_column46 = 'SPM' OR UPPER(additional_column28) = 'TENCENT');
  EXCEPTION
  WHEN OTHERS THEN
  SPM_LINE_COUNT   := 0;
  END;

  BEGIN
  IF (SPM_LINE_COUNT = 0) THEN
    SPM_CHECK_FLAG := 'N';
  ELSE
    SPM_CHECK_FLAG := 'Y';
  END IF;
  EXCEPTION
  WHEN OTHERS THEN
    SPM_CHECK_FLAG   := 'N';
  END;
  --27691142 SRECHAND CHANGES END
  -- Changes for SPM-9570 - SPMPROV
  -- OM Provisioning flow for Not NULL Subscription Id

  IF p_subscription_id IS NOT NULL AND SPM_CHECK_FLAG = 'N' THEN

  SELECT MIN(ol.line_id)
  INTO v_line_id
  FROM oe_order_lines_all ol,
    oe_order_price_attribs opa
  WHERE ol.item_type_code = 'SERVICE'
  AND ol.header_id        = p_header_id
  AND ol.header_id        = opa.header_id
  AND ol.line_id          = opa.line_id
  AND pricing_attribute92 = p_subscription_id;
  --
  IF is_metered_subscription(v_line_id) = 'Y' THEN
  --Only for Metered Subscriptions
  --
  --

  --
  BEGIN
    SELECT max(pricing_attribute92)
    INTO v_sub_id
    FROM oe_order_price_attribs
    WHERE header_id = p_header_id
    AND is_metered_subscription(line_id) = 'Y';
 EXCEPTION WHEN OTHERS THEN
  v_sub_id := p_subscription_id;
  END;
  IF v_sub_id = p_subscription_id THEN
  v_wait := 'N';
  ELSE
  v_wait := 'Y';
  END IF;
  --
  ELSE
  --
  --Check for MASTER Subscription creation in SPM
  IF v_wait = 'N' THEN
    SELECT nvl2(pricing_attribute85,'Y','N'),
      NVL(pricing_attribute85,'0')
    INTO v_coterm,
      v_coterm_master
    FROM oe_order_price_attribs
    WHERE header_id         = p_header_id
    AND pricing_attribute92 = p_subscription_id
    AND rownum              =1;
    IF v_coterm             = 'Y' THEN
      BEGIN
        SELECT DISTINCT 'N'
        INTO v_wait
        FROM MISONT_ORDER_LINE_ATTRIBS_EXT
        WHERE subscription_id = v_coterm_master
        AND spm_plan_number  IS NOT NULL;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_wait := 'Y';
      WHEN OTHERS THEN
        v_wait := 'N';
      END;
    END IF;
  END IF;
  --
  END IF;
  --Bug 21254518 - Chk if the SPM Plan already exists
  IF v_wait = 'Y' THEN
    BEGIN
      SELECT DECODE(NVL(
        (SELECT pricing_attribute79
        FROM oe_order_price_attribs
        WHERE header_id              = p_header_id
        AND pricing_attribute79     IS NOT NULL
        AND is_spm_eligible(line_id) ='Y'
        AND rownum                   =1
        ),'0'),'0','Y','N')
      INTO v_wait
      FROM dual;
    EXCEPTION
    WHEN OTHERS THEN
      v_wait := 'N';
    END;
  END IF;
  --
  IF v_wait = 'Y' THEN
 -- rdnagara Bug 26712778 - Alert for RAMPED UPDATE lines with SPM INTERFACE STATUS as NULL
  UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
  SET spm_interface_status = 'WAITING FOR MASTER SUBS INTF'
  WHERE header_id      = p_header_id
  AND subscription_id  = p_subscription_id;
  --
  ELSIF v_wait = 'N' THEN
  --
  insert_log (p_module =>'PREPARE_NOTIFY_PAYLOAD(+)',
    p_audit_message => 'Raise event misimd.om.notify.spm',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);

  --Bug#21144368. Fee and consult items will be send in the payload of the first operation type.

    FOR rec IN get_operation_types(p_header_id, p_subscription_id)

    LOOP
      l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id, p_subscription_id, rec.OPERATION_TYPE).getClobVal();


      l_order_data := SUBSTR (l_order_data, 1,
        instr (l_order_data, '>', 1, 2) - 1)
        || ' xmlns="http://www.oracle.com/spm">'
        || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);


      wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
        p_event_key => systimestamp,
        p_event_data => l_order_data,
        p_parameters => l_paramlist_t,
        p_send_date => sysdate);

    END LOOP;

  insert_log (p_module =>'PREPARE_NOTIFY_PAYLOAD(-)',
    p_audit_message => 'Event Raised Successfully',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  END IF;
  ELSE

  IF SPM_CHECK_FLAG = 'Y' THEN
  --SPM Provisioning flow for NULL Subscription Id
  insert_log (p_module =>'PREPARE_NOTIFY_PAYLOAD(+)',
      p_audit_message => 'Raise event misimd.om.notify.spm',
      p_audit_level => 1,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number);
  --Get Automated Flow Flag
   BEGIN
    SELECT lookup_value
    INTO v_spm_prov_auto_flow
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE component = 'SPM_PROV_FLOW'
  AND application = 'MISIMD_SPM_CLOUD_WF'
    AND lookup_code   = 'AUTOMATED_FLOW';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_spm_prov_auto_flow := 'N';
  WHEN OTHERS THEN
    v_spm_prov_auto_flow := 'N';
  END;
  --
  IF v_spm_prov_auto_flow = 'Y' THEN
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL).getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
  ELSE
  UPDATE misont_order_line_attribs_ext
  SET SPM_INTERFACE_ERROR = 'SPM_PROV_FLOW:AUTOMATED_FLOW is not Enabled - Retry Manually after setting the flag to Y in OSS_INTF_USER.MISIMD_INTF_LOOKUP'
  WHERE header_id         = p_header_id;
  END IF;
  END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  insert_log (p_module =>'PREPARE_NOTIFY_PAYLOAD(*)',
    p_audit_message => 'Error Raising Business Event. Check misimd_intf_error',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  insert_error (p_error_code => 'BACKTRACE:',
    p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => 'PREPARE_NOTIFY_PAYLOAD',
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id,
    p_context_name3 => SUBSTR ('Error_Stack:'
      || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
    p_context_id3 => SQLCODE);
    raise;
END prepare_notify_payload;

FUNCTION get_bus_event_xml (
    p_header_id NUMBER,
    p_subscription_id NUMBER DEFAULT NULL,
    p_operation_type VARCHAR2 DEFAULT NULL,
    p_spl_payload_num VARCHAR2 DEFAULT NULL,
    p_spl_subs_plan_type VARCHAR2 DEFAULT NULL)
  RETURN xmltype
AS
  v_payload OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION :=
    OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION.NEW_INSTANCE();
  v_parent_ent_comp OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL;
  MISSING_INVOICE_SCHEDULE EXCEPTION;
  CSI_GENERATION_EXCEPTION EXCEPTION;
  v_xml_payload xmltype;
  v_service_ref_line_id NUMBER;
  i number;
  v_line_id number;
  CURSOR c_bom_components(p_line_id IN NUMBER) IS
  SELECT DISTINCT L.INV_PART_NUMBER ,
  L.INV_PART_DESCRIPTION ,
  L.INVENTORY_ITEM_ID ,
  L.PRICE_BAND_ITEM_FLAG ,
  L.PRICING_UOM ,
  L.RATE_CARD_ID ,
  (SELECT DECODE(upper(a.C_EXT_ATTR1),'MONTHLY','M','MONTH','M','SERVICE PERIOD','SP','QUATERLY','Q','ANNUAL','A','BI-ANNUAL','B',a.C_EXT_ATTR1)
   FROM EGO_MTL_SY_ITEMS_EXT_B A
   WHERE a.organization_id = 14354
   AND a.inventory_item_id = ool.INVENTORY_ITEM_ID
   AND a.ATTR_GROUP_ID     = 100084
   AND ROWNUM              = 1
   ) PRICE_PERIOD
  FROM MISQP_CLOUD_CREDITS_HDRS_ALL H,
    MISQP_CLOUD_CREDITS_LINES_ALL L ,
    oe_order_lines_all ool
  WHERE H.TRANSACTION_HDR_ID     = L.TRANSACTION_HDR_ID
  AND H.om_order_header_id       = ool.header_id
  AND L.parent_inventory_item_id = ool.inventory_item_id
  AND ool.line_id                = p_line_id;

  CURSOR c_otiers(p_header_id IN NUMBER, p_line_id IN NUMBER) IS
  SELECT oline.*
  FROM MISQP_CLOUD_OTIERS_HDRS_ALL ohdr,
       MISQP_CLOUD_OTIERS_LINES_ALL oline,
       oe_order_lines_all ol
  WHERE ohdr.transaction_hdr_id = oline.transaction_hdr_id
  AND om_order_header_id        = p_header_id
  AND oline.inventory_item_id   = ol.inventory_item_id
  AND ol.line_id                = p_line_id
  order by oline.quantity;


  CURSOR c_sales_credit(p_header_id IN NUMBER, p_line_id IN NUMBER) IS
  SELECT sc.salesrep_id SALESREP_ID,
  jtf.salesrep_number SALESREP_NUMBER,
  NVL(res.resource_name,NVL(jtf.name,jtf.salesrep_number)) SALESREP_NAME,
  jtf.email_address SALESREP_EMAIL,
  sc.percent PERCENT,
  sc.sales_credit_type_id SALES_CREDIT_TYPE_ID, jtf.resource_id
  FROM jtf_rs_salesreps jtf,
    oe_sales_credits sc,
    jtf_rs_resource_extns_vl res,
    oe_order_headers_all oh
  WHERE jtf.salesrep_id = sc.salesrep_id
  AND jtf.resource_id   = res.resource_id
  AND jtf.org_id        = oh.org_id
  AND oh.header_id      = sc.header_id
  AND sc.sales_credit_type_id IN (select sales_credit_type_id from oe_sales_credit_types where quota_flag = 'Y')
  AND sc.percent        > 0
  AND NVL(SC.LINE_ID,1) = NVL(p_line_id,1)
  AND sc.header_id      = p_header_id;
  v_item_cat VARCHAR2(100) := NULL;
  v_item_usage_billing VARCHAR2(100) := NULL;
  v_service_period NUMBER := 1;
  v_service_UOM VARCHAR2(100) := NULL;
  v_sc_line_id NUMBER := NULL;
  v_operation_type VARCHAR2(100) := 'X';
  v_order_number VARCHAR2(50);
  v_meaning VARCHAR2(10):='Line';
  v_contract_type VARCHAR2(50);
  v_order_commit_model VARCHAR(30);
  v_count_extsite_lines NUMBER;
  v_count_textura_lines NUMBER;
  v_order_prov_source VARCHAR(50);
  v_flag VARCHAR2(10);
  v_temp_plan_number VARCHAR2(100);
  old_contract_number VARCHAR2(100);
  v_extension_update_flag VARCHAR2(10);
  v_start_end_date_flag VARCHAR2(10);
  v_lineid_count NUMBER :=0;
  v_supersede VARCHAR2(100);
  v_old_opcm VARCHAR2(10);
  v_old_order_id NUMBER;
  v_payload_lines NUMBER :=0;
  l_lines_formed   VARCHAR2(1) := 'N';
  v_old_spm_plan_spl VARCHAR2(100);
  v_order_source VARCHAR(100);
  v_asset_transfer_flag varchar(100);
  X_SYSTEM_ID NUMBER;
  X_RETURN_STATUS VARCHAR2(200);
  X_MSG_COUNT NUMBER;
  X_MSG_DATA VARCHAR2(200);
BEGIN
  init;
  /*Necessary since BPEL can have other NLS Lang param(eg. BRITISH) */
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
  --
  SELECT order_number
  INTO v_order_number
  FROM oe_order_headers_all
  WHERE header_id = p_header_id;
  --
  insert_log (p_module =>'GET_BUS_EVENT_XML(+)',
    p_audit_message => 'Enter Function GET_BUS_EVENT_XML',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --Fetch SPM Subscription data
  insert_log (p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetch <MISIMD_SPM_SUBSCRIPTION> info',
    p_audit_level => 3,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --Get Min Line ID for Customer Data
  SELECT MIN(ol.line_id)
  INTO v_line_id
  FROM oe_order_lines_all ol,
    oe_order_price_attribs opa
  WHERE ol.item_type_code = 'SERVICE'
  AND ol.header_id        = p_header_id
  AND ol.header_id        = opa.header_id
  AND ol.line_id          = opa.line_id
  AND NVL(pricing_attribute92,'1') = NVL(p_subscription_id,'1');
  --
  v_payload.INFLIGHT_ORDER           := 'N';
  --
  -- rdnagara  Bug 27476500 - RCA: Lines stuck in SPM interface "Header Start Date or End date is not matching
  BEGIN
SELECT COUNT(oep.line_id)
INTO v_lineid_count
FROM oe_order_price_attribs oep
WHERE oep.header_id = p_header_id
AND pricing_attribute92 IS NOT NULL
AND pricing_attribute93 ='PROVISIONED';
  EXCEPTION
   WHEN OTHERS THEN
   v_lineid_count :=0;
 END;

  BEGIN
 SELECT lookup_value
 INTO v_start_end_date_flag
 FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
 WHERE component  ='START_END_DATE_FLAG'
 AND application = 'MISIMD_SPM_CLOUD_WF'
 AND LOOKUP_CODE  ='START_END_DATES'
 AND enabled = 'Y';
    EXCEPTION
        WHEN OTHERS THEN
          v_start_end_date_flag := 'N';
END;

  SELECT oh.header_id,
    oh.org_id,
    (SELECT hr.name
    FROM hr_operating_units hr
    WHERE organization_id = oh.org_id
    ) organization_name,
    oh.order_number,
    TO_CHAR (trunc(oh.ordered_date), 'YYYY-MM-DD')
      ||' '||TO_CHAR (trunc(oh.ordered_date), 'HH24:MI:SS') ORDERED_DATE,
    (select name from OE_TRANSACTION_TYPES_TL where transaction_type_id = oh.order_type_id and language = 'US') ORDER_TYPE,
    decode(p_operation_type,NULL,(SELECT pricing_attribute94 FROM oe_order_price_attribs
    WHERE header_id = p_header_id  AND pricing_attribute94 IS NOT NULL AND ROWNUM=1),p_operation_type) OPERATION_TYPE,
     -- START BUG 27476500 - RCA: Lines stuck in SPM interface "Header Start Date or End date is not matching - rdnagara
      CASE
      WHEN (v_lineid_count > 0 AND v_start_end_date_flag ='Y') THEN
     (select TO_CHAR(min(oola.service_start_date), 'YYYY-MM-DD')||' '
      ||TO_CHAR(min(oola.service_start_date), 'HH24:MI:SS') from oe_order_lines_all oola, oe_order_price_attribs oopa
      where is_spm_eligible(oola.line_id) = 'Y' and oola.header_id = oopa.header_id and oola.line_id = oopa.line_id AND oopa.pricing_attribute93 = 'PROVISIONED' and oola.header_id = oh.header_id)
      ELSE
      (select TO_CHAR(min(service_start_date), 'YYYY-MM-DD')||' '
      ||TO_CHAR(min(service_start_date), 'HH24:MI:SS') from oe_order_lines_all
      where is_spm_eligible(line_id) = 'Y' and header_id = oh.header_id and flow_status_code <> 'CANCELLED')
      END AS START_DATE,

       CASE
      WHEN (v_lineid_count > 0 AND v_start_end_date_flag ='Y') THEN
    (select TO_CHAR(max(oola.service_end_date), 'YYYY-MM-DD')||' '
      ||TO_CHAR(max(oola.service_end_date), 'HH24:MI:SS') from oe_order_lines_all oola, oe_order_price_attribs oopa
      where is_spm_eligible(oola.line_id) = 'Y' and oola.header_id = oopa.header_id and oola.line_id = oopa.line_id AND oopa.pricing_attribute93 = 'PROVISIONED' and oola.header_id = oh.header_id)
      ELSE
      (select TO_CHAR(max(service_end_date), 'YYYY-MM-DD')||' '
      ||TO_CHAR(max(service_end_date), 'HH24:MI:SS') from oe_order_lines_all
      where is_spm_eligible(line_id) = 'Y' and header_id = oh.header_id and flow_status_code <> 'CANCELLED')
      END AS  END_DATE,
   CASE
     WHEN (v_lineid_count > 0 AND v_start_end_date_flag ='Y') THEN
    (SELECT months_between(MAX(oola.service_end_date+1),MIN(oola.service_start_date)) FROM oe_order_lines_all oola, oe_order_price_attribs oopa
      where is_spm_eligible(oola.line_id) = 'Y' and oola.header_id = oopa.header_id and oola.line_id = oopa.line_id AND oopa.pricing_attribute93 = 'PROVISIONED' and oola.header_id = oh.header_id)
   ELSE
    (SELECT months_between(MAX(service_end_date+1),MIN(service_start_date)) FROM oe_order_lines_all
      where is_spm_eligible(line_id) = 'Y' and header_id = oh.header_id)
    END AS DURATION,
   -- END BUG 27476500
    'OBSCNTR_M' DURATION_UOM,
    misont_cloud_pub2.get_order_header_info(oh.header_id, 'SALESREPS') sales_rep,
    oh.salesrep_id PRIMARY_SALESREP_ID,
    (select jtf.salesrep_number from jtf_rs_salesreps jtf where jtf.salesrep_id = oh.salesrep_id and org_id = oh.org_id) SALESREP_NUMBER,
    (select NVL(res.resource_name,NVL(jtf.name,jtf.salesrep_number)) from jtf_rs_salesreps jtf, jtf_rs_resource_extns_vl res where jtf.salesrep_id = oh.salesrep_id
    and jtf.resource_id = res.resource_id and jtf.org_id = oh.org_id) SALESREP_NAME,
    (select jtf.email_address from jtf_rs_salesreps jtf where jtf.salesrep_id = oh.salesrep_id and org_id = oh.org_id) SALESREP_EMAIL,
    misont_cloud_pub2.get_order_header_info(oh.header_id, 'SALES_CHANNEL') sales_channel,
    misont_cloud_pub2.get_order_header_info(oh.header_id, 'IS_AUTO_RENEW')IS_AUTO_RENEWED,
    misont_cloud_pub2.get_order_header_info(oh.header_id,
      'IS_CREATED_BY_AUTO_RENEW') ORDER_CREATED_BY_AUTO_RENEWAL,
    (SELECT DECODE(name,
              'Order Capture Quotes', 'WQ',
              'Global Store', 'ST',
              'Partner Store', 'OPS',
              'Internal', 'IO',
              'XML', 'XML',
              'CPQ', 'CPQ',
              'Copy', 'CP', name)
    FROM oe_order_sources
    WHERE order_source_id = oh.order_source_id) ORDER_SOURCE,
    (SELECT name
    FROM ra_terms
    WHERE term_id = oh.payment_term_id
    ) PAYMENT_TERMS,
    (SELECT NVL(rtl.due_days,0)
    FROM ra_terms_lines rtl, oe_order_lines_all ol
    where ol.header_id = oh.header_id
    and ol.payment_term_id  = rtl.term_id
    and rownum = 1) PAYMENT_TERMS_DAYS_DUE,
    oh.payment_term_id PAYMENT_TERMS_ID,
    oh.transactional_curr_code CURRENCY,
    (SELECT name
    FROM qp_list_headers
    WHERE list_header_id = oh.price_list_id
    ) PRICE_LIST,
    DECODE(oh.payment_type_code,
      'CREDIT_CARD', 'Credit Card',
      'CASH', 'Cash',
      'WIRE', 'Wire',
      'PO_NUMBER', 'PO Number',
      'CHECK', 'Check',
      'ACH','ACH', --SPM-7904
      'PayPal','PayPal', -- SPM-18254
      'eCheck','eCheck', -- SPM-18254
      'PO Number') PAYMENT_METHOD,
    oh.cust_po_number PO_NUMBER,
    (SELECT name
      FROM ra_rules
      WHERE rule_id =oh.invoicing_rule_id
    )
    ||'-'||oh.attribute19||'-'
    || NVL(
    (SELECT OVERAGE_BILLING_FREQUENCY
      FROM MISONT_ORDER_LINE_ATTRIBS_EXT
      WHERE OVERAGE_BILLING_FREQUENCY IS NOT NULL
      AND header_id                    = oh.header_id
      AND rownum                       =1
    ),'Monthly') INVOICE_SCHEDULE,
    NULL IS_INDIRECT,
    --get_subscription_type(oh.header_id) CONTRACT_TYPE,
     COALESCE((select pricing_attribute79 from oe_order_price_attribs where header_id = oh.header_id
    and pricing_attribute79 is not null AND is_spm_eligible(line_id) ='Y'
    and nvl(pricing_attribute50,'X') <> 'REPLACETERMINATE' --Added fix for Bug 25688486,25714388
    and ( pricing_attribute94 <> 'CONVERT_TO_UCM' or pricing_attribute94 <> 'RENEW_TO_UCM')
    and rownum=1),
    (select SPM_PLAN_NUMBER from MISONT_ORDER_LINE_ATTRIBS_EXT where header_id = oh.header_id
    and SPM_PLAN_NUMBER is not null and SPM_PLAN_NUMBER <> '0' and rownum=1),'0' ) spm_plan_number,
      nvl(oh.attribute13,'0') CRM_OPTY_NUM,
    decode((select upper(pricing_attribute48) from oe_order_price_attribs where header_id = oh.header_id
    and pricing_attribute48 is not null and rownum=1),'Y','true','N','false','false') ISPUBLICSECTOR,
    (select COST_CENTER from MISONT_ORDER_LINE_ATTRIBS_EXT where header_id = oh.header_id
    and cost_center is not null and rownum=1) COST_CENTER,
    (select COST_CENTER_DESCRIPTION from MISONT_ORDER_LINE_ATTRIBS_EXT where header_id = oh.header_id
    and cost_center_description is not null and rownum=1) COST_CENTER_DESCRIPTION,
    (SELECT DECODE(ltrim(rtrim(pricing_attribute90)),'@',NULL,ltrim(rtrim(pricing_attribute90)))
    from oe_order_price_attribs where header_id = oh.header_id and pricing_attribute90 is not null and rownum=1) BUYER_EMAIL_ID,
    (select ADDITIONAL_COLUMN18 from MISONT_ORDER_LINE_ATTRIBS_EXT where header_id = oh.header_id
    and ADDITIONAL_COLUMN18 is not null and rownum=1) RELATED_GROUP_PLAN_ID,
    NVL((select 'NCER' from MISONT_ORDER_LINE_ATTRIBS_EXT where header_id = oh.header_id
    and ADDITIONAL_COLUMN34 = 'Y' and rownum=1),'STANDARD') PLAN_CLASSIFICATION,
    --Changes for SPM-9570 - SPMPROV
    oh.ATTRIBUTE3 REKEY_TYPE,
    --Changes for SPM-9570 - SPMPROV
    (select ADDITIONAL_COLUMN79 from MISONT_ORDER_LINE_ATTRIBS_EXT where header_id = oh.header_id and ADDITIONAL_COLUMN79 is not null and rownum=1) CRM_TARGET_PARTY_ID
  INTO v_payload.ORDER_HEADER_ID,
    v_payload.ORGANIZATION_ID,
    v_payload.ORGANIZATION_NAME,
    v_payload.ORDER_NUMBER,
    v_payload.ORDER_DATE,
    v_payload.ORDER_TYPE,
    v_payload.OPERATIONTYPE,
    v_payload.START_DATE,
    v_payload.END_DATE,
    v_payload.DURATION,
    v_payload.DURATION_UOM,
    v_payload.SALES_REPS,
    v_payload.PRIMARY_SALESREP_ID,
    v_payload.SALESREP_NUMBER,
    v_payload.SALESREP_NAME,
    v_payload.SALESREP_EMAIL,
    v_payload.SALES_CHANNEL,
    v_payload.IS_AUTO_RENEWED,
    v_payload.ORDER_CREATED_BY_AUTO_RENEWAL,
    v_payload.ORDER_SOURCE,
    v_payload.PAYMENT_TERMS,
    v_payload.PAYMENT_TERMS_DAYS_DUE,
    v_payload.PAYMENT_TERMS_ID,
    v_payload.CURRENCY,
    v_payload.PRICE_LIST,
    v_payload.PAYMENT_METHOD,
    v_payload.PO_NUMBER,
    v_payload.INVOICE_SCHEDULE,
    v_payload.IS_INDIRECT,
    v_payload.SPM_PLAN_NUMBER,
    v_payload.CRM_OPTY_NUM,
    v_payload.ISPUBLICSECTOR,
    v_payload.COST_CENTER,
    v_payload.COST_CENTER_DESCRIPTION,
    v_payload.BUYER_EMAIL_ID,
    v_payload.RELATED_GROUP_PLAN_ID,
    v_payload.PLAN_CLASSIFICATION,
    v_payload.REKEY_TYPE,
    v_payload.CRM_TARGET_PARTY_ID
  FROM oe_order_headers_all oh
  WHERE oh.header_id        = p_header_id;
  --
  v_old_spm_plan_spl := v_payload.SPM_PLAN_NUMBER;
  --
  insert_log (p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<MISIMD_SPM_SUBSCRIPTION> info fetch successful',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --Generate RELATED_GROUP_PLAN_ID SPM-4990 - Create related group plan identifier and set on subscription plan creation
  IF v_payload.RELATED_GROUP_PLAN_ID IS NULL THEN
  SELECT OSS_INTF_USER.MISIMD_SPM_CLOUD_SEQ.NEXTVAL
  INTO v_payload.RELATED_GROUP_PLAN_ID
  FROM DUAL;
  EXECUTE IMMEDIATE 'UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
  SET ADDITIONAL_COLUMN18 = '||v_payload.RELATED_GROUP_PLAN_ID||'
  WHERE header_id = '||p_header_id;
  END IF;
  --Order Source: Copy - 24927-I "Enable Functionality to Copy an Order to Initiate a CMRB"
  IF v_payload.ORDER_SOURCE = 'CP' AND v_payload.SPM_PLAN_NUMBER <> '0' THEN
  v_payload.SUPERSEDED_PROJECT := v_payload.SPM_PLAN_NUMBER;
  v_payload.SPM_PLAN_NUMBER := '0';
  END IF;

    -- rdnagara START Bug 27366815 - RCA : Extension-Update orders are creating new spm plan
  BEGIN
 SELECT opa.pricing_attribute50 INTO v_supersede
 FROM oe_order_price_attribs opa
 WHERE opa.header_id = p_header_id
 AND opa.pricing_attribute50 IS NOT NULL
 AND rownum <2;
  EXCEPTION
    WHEN OTHERS THEN
   v_supersede := NULL;
 END;

 BEGIN
 SELECT lookup_value
 INTO v_extension_update_flag
 FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
 WHERE component ='EXTENSION_UPDATE_FLAG'
 AND application = 'MISIMD_SPM_CLOUD_WF'
 AND LOOKUP_CODE ='EXTENSION_UPDATE'
 AND enabled     = 'Y';
    EXCEPTION
        WHEN OTHERS THEN
          v_extension_update_flag := 'N';
END;

BEGIN
 SELECT pricing_attribute79
 INTO old_contract_number
 FROM oe_order_price_attribs opa
 where opa.header_id = p_header_id
   and pricing_attribute79 is not null
   and nvl(pricing_attribute50,'X') <> 'REPLACETERMINATE' --Added fix for Bug 25688486,25714388
   and rownum=1;
    EXCEPTION
        WHEN OTHERS THEN
          old_contract_number := NULL;
END;

BEGIN

IF(p_operation_type <> 'ONBOARDING' AND v_extension_update_flag = 'Y')
 THEN
  SELECT olae.SPM_PLAN_NUMBER INTO v_temp_plan_number
  FROM MISONT_ORDER_LINE_ATTRIBS_EXT olae ,  oe_order_headers_all oh where olae.line_id IN (SELECT oep.line_id FROM oe_order_price_attribs oep where
  oep.pricing_attribute94 IS NOT NULL AND oep.pricing_attribute94 IN ('EXTENSION','RAMPED_EXTENSION')
        AND   oep.header_id = oh.header_id) AND
        olae.header_id = p_header_id
    and SPM_PLAN_NUMBER is not null and SPM_PLAN_NUMBER <> '0' and rownum=1;

    IF(v_supersede IS NULL AND v_temp_plan_number IS NOT NULL AND (v_temp_plan_number <> old_contract_number))
      THEN

        v_payload.SPM_PLAN_NUMBER := v_temp_plan_number;

     END IF;
END IF;
EXCEPTION
  WHEN OTHERS THEN
    v_payload.SPM_PLAN_NUMBER := v_payload.SPM_PLAN_NUMBER;
END;
-- rdnagara END

  --INVOICE_SCHEDULE
  BEGIN
    SELECT lookup_value
    INTO v_payload.INVOICE_SCHEDULE
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE component = 'INVOICE_SCHEDULE'
  AND application = 'MISIMD_SPM_CLOUD_WF'
    AND lookup_code   = v_payload.INVOICE_SCHEDULE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE MISSING_INVOICE_SCHEDULE;
  WHEN OTHERS THEN
    RAISE MISSING_INVOICE_SCHEDULE;
  END;
  --
  -- ORDER_TYPE_COMPLEX
  IF v_payload.ORDER_TYPE like '%CLOUD SERVICES COMPLEX%'  or v_payload.OPERATIONTYPE = 'MIGRATION' THEN
  v_payload.ORDER_TYPE_COMPLEX := 'true';
  ELSE
  v_payload.ORDER_TYPE_COMPLEX := 'false';
  END IF;

  -- START BUG 27476500 rdnagara
  IF (v_lineid_count > 0 AND v_start_end_date_flag ='Y') THEN
    IF mod(v_payload.DURATION,12) = 0 THEN
    v_payload.DURATION := v_payload.DURATION/12;
    v_payload.DURATION_UOM := 'OBSCNTR_Y';
    ELSIF mod(v_payload.DURATION,2) = 0 THEN
    v_payload.DURATION := v_payload.DURATION;
    v_payload.DURATION_UOM := 'OBSCNTR_M';
    ELSE
    SELECT ceil(MAX(oola.service_end_date+1)- MIN(oola.service_start_date))
    INTO v_payload.DURATION
    FROM oe_order_lines_all oola, oe_order_price_attribs oopa
      where  oola.header_id = oopa.header_id and oola.line_id = oopa.line_id
      AND oopa.pricing_attribute93 = 'PROVISIONED' and oola.header_id = p_header_id;
    v_payload.DURATION_UOM := 'OBSCNTR_D';
    END IF;

  ELSE
     IF mod(v_payload.DURATION,12) = 0 THEN
    v_payload.DURATION := v_payload.DURATION/12;
    v_payload.DURATION_UOM := 'OBSCNTR_Y';
    ELSIF mod(v_payload.DURATION,2) = 0 THEN
    v_payload.DURATION := v_payload.DURATION;
    v_payload.DURATION_UOM := 'OBSCNTR_M';
    ELSE
    SELECT ceil(MAX(service_end_date+1)- MIN(service_start_date))
    INTO v_payload.DURATION
    FROM oe_order_lines_all
    WHERE header_id = p_header_id;
    v_payload.DURATION_UOM := 'OBSCNTR_D';
    END IF;
  END IF;
  -- END BUG 27476500  rdnagara

  --Fetch/Update Price List from Order Lines
  BEGIN
    SELECT distinct qp.name
    INTO v_payload.PRICE_LIST
    FROM qp_list_headers qp,
         oe_order_lines_all ol
    WHERE qp.list_header_id = ol.price_list_id
    AND ol.header_id        = p_header_id;
  EXCEPTION WHEN TOO_MANY_ROWS THEN
    BEGIN
      SELECT distinct qp.name
      INTO v_payload.PRICE_LIST
      FROM qp_list_headers qp,
           oe_order_lines_all ol
      WHERE qp.list_header_id = ol.price_list_id
      AND qp.name             = 'SUBSCRIPTION PRICE HOLD PRICE LIST'
      AND ol.header_id        = p_header_id;
   EXCEPTION WHEN OTHERS THEN
   NULL;
   END;
  WHEN OTHERS THEN
  NULL; -- Not to update Price List from Line - Retain Header Level Price List
  END;
  --Fetch Usage Billing
  BEGIN
    SELECT DISTINCT mcb.segment1
    INTO v_payload.USAGE_BILLING
    FROM mtl_item_categories mic,
         mtl_categories_b mcb,
         MTL_CATEGORY_SETS_TL mctl,
         oe_order_lines_all ol
    WHERE 1                    =1
    AND mic.category_id        = mcb.category_id
    AND mctl.CATEGORY_SET_ID   = mic.CATEGORY_SET_ID
    AND mctl.LANGUAGE          = 'US'
    AND mcb.enabled_flag       = 'Y'
    AND mctl.CATEGORY_SET_NAME = 'Usage Billing'
    AND mic.organization_id    = 14354
    AND mic.inventory_item_id  = ol.inventory_item_id
    AND ol.header_id           = p_header_id
    AND rownum                 = 1;
  EXCEPTION WHEN TOO_MANY_ROWS THEN
  v_payload.USAGE_BILLING := 'METERED_BILLING';
  WHEN NO_DATA_FOUND THEN
  v_payload.USAGE_BILLING := 'METERED_COMMITMENT';
  WHEN OTHERS THEN
  v_payload.USAGE_BILLING := 'METERED_COMMITMENT';
  END;
  --Fetch CC Token Reference
  IF v_payload.PAYMENT_METHOD = 'Credit Card' THEN
  BEGIN
    select trxn_extension_id
    into v_payload.CC_TOKEN_REF
    from oe_payments
    where header_id = p_header_id --header_id
    and payment_level_code = 'ORDER'
    and payment_type_code = 'CREDIT_CARD';
  v_payload.CC_EXPIRY_DATE := NULL;
  EXCEPTION WHEN OTHERS THEN
  v_payload.CC_TOKEN_REF := NULL;
  v_payload.CC_EXPIRY_DATE := NULL;
  END;
  END IF;
  --Fetch Customers: BILL_TO/SHIP_TO/SOLD_TO
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetch <CUSTOMERS> info',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);

  v_payload.customers.extend (5);
  v_payload.customers (1) := OSS_INTF_USER.MISIMD_SPM_CUSTOMER.NEW_INSTANCE();
  v_payload.customers (2) := OSS_INTF_USER.MISIMD_SPM_CUSTOMER.NEW_INSTANCE();
  v_payload.customers (3) := OSS_INTF_USER.MISIMD_SPM_CUSTOMER.NEW_INSTANCE();
  v_payload.customers (4) := OSS_INTF_USER.MISIMD_SPM_CUSTOMER.NEW_INSTANCE();
  v_payload.customers (5) := OSS_INTF_USER.MISIMD_SPM_CUSTOMER.NEW_INSTANCE();

  --SOLD_TO
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetching <MISIMD_SPM_CUSTOMER> SOLD_TO',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  BEGIN
    SELECT OSS_INTF_USER.MISIMD_SPM_CUSTOMER (party.party_id,
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
    ), party.party_number, party.party_name, party.party_type,
    party.jgzz_fiscal_code, party.ORGANIZATION_NAME_PHONETIC, party.url,
    acct.cust_account_id, acct.account_number, NULL, NULL, NULL, NULL, NULL,NULL ,NULL ,
    NULL, NULL, NULL, 'SOLD_TO', NULL, ooh.sold_to_contact_id,
    hpc.person_first_name, hpc.person_last_name,
    (SELECT email_address
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'EMAIL'
    AND rownum                < 2
    ),
  (SELECT  REPLACE(REPLACE(REGEXP_REPLACE(
    (SELECT /*Warning: Reverse() is an undocumented Oracle SQL function*/
    reverse(to_char(transposed_phone_number))
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'PHONE'
    AND rownum                < 2
    ),'[^0-9]+', ''),'/','</'),'<<','<') from dual),
  hpc.party_id,hcar.cust_account_role_id,NULL, NULL, NULL,
    (SELECT NVL((SELECT 'true'  FROM hz_code_assignments
    WHERE owner_table_name = 'HZ_PARTIES'
    AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
    AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
    AND class_code <> 'No'
    AND owner_table_id =  party.party_id),'false') FROM DUAL), --IS_PUBLIC_SECTOR
    (SELECT NVL((SELECT 'true' FROM hz_code_assignments
      WHERE owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND CLASS_CATEGORY = 'CHAIN'
      AND CLASS_CODE IS NOT NULL
      AND owner_table_id = party.party_id),'false') FROM DUAL), --IS_CHAIN_CUSTOMER
       (SELECT CLASS_CODE
        FROM hz_code_assignments
        WHERE CLASS_CATEGORY = 'CHAIN'
        AND owner_table_name = 'HZ_PARTIES'
        AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
        AND owner_table_id =party.party_id))  --CUSTOMER_CHAIN_TYPE
  INTO v_payload.customers (1)
  FROM hz_cust_accounts acct,
    hz_parties party,
    oe_order_headers_all ooh,
    hz_cust_account_roles hcar,
    hz_relationships hr,
    hz_parties hpc
  WHERE ooh.sold_to_org_id =
    acct.cust_account_id
  AND acct.party_id = party.party_id
  AND ooh.header_id = p_header_id
  AND ooh.sold_to_contact_id          = hcar.cust_account_role_id(+)
  AND NVL(hcar.role_type,'CONTACT')   = 'CONTACT'
  AND hcar.party_id                   = hr.party_id(+)
  AND NVL(hr.relationship_code,'CONTACT_OF')   IN ( SELECT lookup_value
                            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                            WHERE component  ='RELATIONSHIP_CODE'
                            AND application = 'MISIMD_SPM_CLOUD_WF'
                            AND LOOKUP_CODE  ='RELATIONSHIP_CODE'
                            AND enabled = 'Y')
  AND hr.subject_id                   = hpc.party_id(+)
  AND NVL(hr.subject_type,'PERSON')   = 'PERSON';

    EXCEPTION
  WHEN NO_DATA_FOUND THEN
   insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<MISIMD_SPM_CUSTOMER> SOLD_TO DATA IS NULL',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  raise_application_error(-20102, 'SOLD_TO DATA IS NULL');
  END;

  --SHIP_TO
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetching <MISIMD_SPM_CUSTOMER> SHIP_TO',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  BEGIN
  SELECT OSS_INTF_USER.MISIMD_SPM_CUSTOMER (party.party_id,
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
    ), party.party_number, party.party_name, party.party_type,
    party.jgzz_fiscal_code, party.ORGANIZATION_NAME_PHONETIC, party.url,
    acct.cust_account_id, acct.account_number, party_site.party_site_id,
    party_site.party_site_number,cust_acct_site.CUST_ACCT_SITE_ID,
    loc.location_id, loc.address1, loc.address2, loc.city, loc.postal_code,
    NVL(loc.state,loc.province),loc.country
    /*(SELECT territory_short_name
    FROM fnd_territories_tl
    WHERE territory_code = loc.country
    AND language         = 'US'
    )*/
    , cust_site_use.site_use_code, cust_site_use.site_use_id,
    ooh.ship_TO_CONTACT_ID, hpc.person_first_name, hpc.person_last_name,
    (SELECT email_address
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'EMAIL'
    AND rownum                < 2
    ),
  (SELECT  REPLACE(REPLACE(REGEXP_REPLACE(
    (SELECT /*Warning: Reverse() is an undocumented Oracle SQL function*/
    reverse(to_char(transposed_phone_number))
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'PHONE'
    AND rownum                < 2
    ),'[^0-9]+', ''),'/','</'),'<<','<') from dual),
  hpc.party_id,hcar.cust_account_role_id,NULL, NULL, NULL,
    (SELECT NVL((SELECT 'true'  FROM hz_code_assignments
    WHERE owner_table_name = 'HZ_PARTIES'
    AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
    AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
    AND class_code <> 'No'
    AND owner_table_id =  party.party_id),'false') FROM DUAL),  --IS_PUBLIC_SECTOR
    (SELECT NVL((SELECT 'true' FROM hz_code_assignments
      WHERE owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND CLASS_CATEGORY = 'CHAIN'
      AND CLASS_CODE IS NOT NULL
      AND owner_table_id = party.party_id),'false') FROM DUAL), --IS_CHAIN_CUSTOMER
     (SELECT CLASS_CODE
      FROM hz_code_assignments
      WHERE CLASS_CATEGORY = 'CHAIN'
      AND owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND owner_table_id =party.party_id))  --CUSTOMER_CHAIN_TYPE
  INTO v_payload.customers (2)
  FROM hz_cust_site_uses_all cust_site_use,
    hz_cust_acct_sites_all cust_acct_site,
    hz_party_sites party_site,
    hz_cust_accounts acct,
    hz_parties party,
    hz_locations loc,
    oe_order_headers_all ooh,
    hz_cust_account_roles hcar,
    hz_relationships hr,
    hz_parties hpc
  WHERE 1                             = 1
  AND ooh.ship_to_org_id              = cust_site_use.site_use_id
  AND cust_site_use.site_use_code     = 'SHIP_TO'
  AND cust_acct_site.cust_account_id  = acct.cust_account_id
  AND cust_site_use.cust_acct_site_id = cust_acct_site.cust_acct_site_id
  AND cust_acct_site.party_site_id    = party_site.party_site_id
  AND party_site.party_id             = party.party_id
  AND party_site.location_id          = loc.location_id
  AND ooh.header_id                   = p_header_id
  AND ooh.ship_to_contact_id          = hcar.cust_account_role_id(+)
  AND NVL(hcar.role_type,'CONTACT')   = 'CONTACT'
  AND hcar.party_id                   = hr.party_id(+)
  AND NVL(hr.relationship_code,'CONTACT_OF')   IN ( SELECT lookup_value
                            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                            WHERE component  ='RELATIONSHIP_CODE'
                            AND application = 'MISIMD_SPM_CLOUD_WF'
                            AND LOOKUP_CODE  ='RELATIONSHIP_CODE'
                            AND enabled = 'Y')
  AND hr.subject_id                   = hpc.party_id(+)
  AND NVL(hr.subject_type,'PERSON')   = 'PERSON';

      EXCEPTION
  WHEN NO_DATA_FOUND THEN
   insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<MISIMD_SPM_CUSTOMER> SHIP_TO DATA IS NULL',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  raise_application_error(-20103, 'SHIP_TO DATA IS NULL');
  END;

  --BILL_TO
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetching <MISIMD_SPM_CUSTOMER> BILL_TO',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  BEGIN
  SELECT OSS_INTF_USER.MISIMD_SPM_CUSTOMER (party.party_id,
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
    ), party.party_number, party.party_name, party.party_type,
    party.jgzz_fiscal_code, party.ORGANIZATION_NAME_PHONETIC, party.url,
    acct.cust_account_id, acct.account_number, party_site.party_site_id,
    party_site.party_site_number,cust_acct_site.CUST_ACCT_SITE_ID,
    loc.location_id, loc.address1, loc.address2, loc.city, loc.postal_code,
    NVL(loc.state,loc.province),loc.country
    /*(SELECT territory_short_name
    FROM fnd_territories_tl
    WHERE territory_code = loc.country
    AND language         = 'US'
    )*/
    , cust_site_use.site_use_code, cust_site_use.site_use_id,
    ooh.INVOICE_TO_CONTACT_ID, hpc.person_first_name, hpc.person_last_name,
    (SELECT email_address
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'EMAIL'
    AND rownum                < 2
    ),
  (SELECT  REPLACE(REPLACE(REGEXP_REPLACE(
    (SELECT /*Warning: Reverse() is an undocumented Oracle SQL function*/
    reverse(to_char(transposed_phone_number))
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'PHONE'
    AND rownum                < 2
    ),'[^0-9]+', ''),'/','</'),'<<','<') from dual),
  hpc.party_id,hcar.cust_account_role_id,NULL, NULL, NULL,
    (SELECT NVL((SELECT 'true'  FROM hz_code_assignments
    WHERE owner_table_name = 'HZ_PARTIES'
    AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
    AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
    AND class_code <> 'No'
    AND owner_table_id =  party.party_id),'false') FROM DUAL), --IS_PUBLIC_SECTOR
    (SELECT NVL((SELECT 'true' FROM hz_code_assignments
      WHERE owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND CLASS_CATEGORY = 'CHAIN'
      AND CLASS_CODE IS NOT NULL
      AND owner_table_id = party.party_id),'false') FROM DUAL), --IS_CHAIN_CUSTOMER
     (SELECT CLASS_CODE
      FROM hz_code_assignments
      WHERE CLASS_CATEGORY = 'CHAIN'
      AND owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND owner_table_id =party.party_id))  -- CUSTOMER_CHAIN_TYPE
  INTO v_payload.customers (3)
  FROM hz_cust_site_uses_all cust_site_use,
    hz_cust_acct_sites_all cust_acct_site,
    hz_party_sites party_site,
    hz_cust_accounts acct,
    hz_parties party,
    hz_locations loc,
    oe_order_headers_all ooh,
    hz_cust_account_roles hcar,
    hz_relationships hr,
    hz_parties hpc
  WHERE 1                             = 1
  AND ooh.invoice_to_org_id           = cust_site_use.site_use_id
  AND cust_site_use.site_use_code     = 'BILL_TO'
  AND cust_acct_site.cust_account_id  = acct.cust_account_id
  AND cust_site_use.cust_acct_site_id = cust_acct_site.cust_acct_site_id
  AND cust_acct_site.party_site_id    = party_site.party_site_id
  AND party_site.party_id             = party.party_id
  AND party_site.location_id          = loc.location_id
  AND ooh.header_id                   = p_header_id
  AND ooh.invoice_TO_CONTACT_ID       = hcar.cust_account_role_id(+)
  AND NVL(hcar.role_type,'CONTACT')   = 'CONTACT'
  AND hcar.party_id                   = hr.party_id(+)
  AND NVL(hr.relationship_code,'CONTACT_OF')   IN ( SELECT lookup_value
                            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                            WHERE component  ='RELATIONSHIP_CODE'
                            AND application = 'MISIMD_SPM_CLOUD_WF'
                            AND LOOKUP_CODE  ='RELATIONSHIP_CODE'
                            AND enabled = 'Y')
  AND hr.subject_id                   = hpc.party_id(+)
  AND NVL(hr.subject_type,'PERSON')   = 'PERSON';

      EXCEPTION
  WHEN NO_DATA_FOUND THEN
   insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<MISIMD_SPM_CUSTOMER> BILL_TO DATA IS NULL',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  raise_application_error(-20104, 'BILL_TO DATA IS NULL');
  END;

  --END_USER
  BEGIN
  SELECT OSS_INTF_USER.MISIMD_SPM_CUSTOMER(
    party.party_id,
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
    ),
    party.party_number,
    party.party_name,
    party.party_type,
    party.jgzz_fiscal_code,
    party.ORGANIZATION_NAME_PHONETIC,
    party.url,
    acct.cust_account_id,
    acct.account_number,
    party_site.party_site_id,
    party_site.party_site_number,
    cust_acct_site.CUST_ACCT_SITE_ID,
    loc.location_id,
    loc.address1,
    loc.address2,
    loc.city,
    loc.postal_code,
    NVL(loc.state,loc.province),
    loc.country,
    'END_USER', --SITE_USE_TYPE
    null,--  SITE_USE_ID
    ooh.attribute16,--  CONTACT_ID
    hpc.person_first_name,--  CONTACT_FIRST_NAME
    hpc.person_last_name,--  CONTACT_LAST_NAME
    (SELECT email_address
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'EMAIL'
    AND rownum                < 2
    ),--  CONTACT_EMAIL
    (SELECT  REPLACE(REPLACE(REGEXP_REPLACE(
  (SELECT /*Warning: Reverse() is an undocumented Oracle SQL function*/
    reverse(to_char(transposed_phone_number))
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'PHONE'
    AND rownum                < 2
    ),'[^0-9]+', ''),'/','</'),'<<','<') from dual),--  CONTACT_PHONE
    hpc.party_id,--  CONTACT_PARTY_ID
    hcar.cust_account_role_id,--   CONTACT_CUST_ACCT_ROLE_ID
    null, --              CONTACT_CUST_ACCT_SITE_ID
    null, --BILL_TO_SITE_USE_ID
    null, --SHIP_TO_SITE_USE_ID
    (SELECT NVL((SELECT 'true'  FROM hz_code_assignments
    WHERE owner_table_name = 'HZ_PARTIES'
    AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
    AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
    AND class_code <> 'No'
    AND owner_table_id =  party.party_id),'false') FROM DUAL), --IS_PUBLIC_SECTOR
    (SELECT NVL((SELECT 'true' FROM hz_code_assignments
      WHERE owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND CLASS_CATEGORY = 'CHAIN'
      AND CLASS_CODE IS NOT NULL
      AND owner_table_id = party.party_id),'false') FROM DUAL), --IS_CHAIN_CUSTOMER
      (SELECT CLASS_CODE
      FROM hz_code_assignments
      WHERE CLASS_CATEGORY = 'CHAIN'
      AND owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND owner_table_id =party.party_id))  -- CUSTOMER_CHAIN_TYPE
  into v_payload.customers (4)
  FROM hz_cust_accounts acct,
    hz_parties party,
    oe_order_headers_all ooh,
    hz_cust_acct_sites_all cust_acct_site,
    hz_party_sites party_site,
    hz_locations loc,
    hz_cust_account_roles hcar,
    hz_relationships hr,
    hz_parties hpc
  WHERE ooh.attribute8 =
    acct.cust_account_id
  AND acct.party_id = party.party_id
  AND ooh.header_id = p_header_id
  and ooh.attribute9 = cust_acct_site.cust_acct_site_id(+)
  AND cust_acct_site.party_site_id    = party_site.party_site_id(+)
  AND party_site.location_id          = loc.location_id(+)
  AND ooh.attribute16                 = hcar.cust_account_role_id(+)
  AND NVL(hcar.role_type,'CONTACT')   = 'CONTACT'
  AND hcar.party_id                   = hr.party_id(+)
  AND NVL(hr.relationship_code,'CONTACT_OF')   IN ( SELECT lookup_value
                            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                            WHERE component  ='RELATIONSHIP_CODE'
                            AND application = 'MISIMD_SPM_CLOUD_WF'
                            AND LOOKUP_CODE  ='RELATIONSHIP_CODE'
                            AND enabled = 'Y')
  AND hr.subject_id                   = hpc.party_id(+)
  AND NVL(hr.subject_type,'PERSON')   = 'PERSON'
  ;
  EXCEPTION WHEN OTHERS THEN
  NULL;
  END;
  --
  --Reseller
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetching <MISIMD_SPM_CUSTOMER> RESELLER',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  BEGIN
  SELECT OSS_INTF_USER.MISIMD_SPM_CUSTOMER(
    party.party_id,
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
    ),
    party.party_number,
    party.party_name,
    party.party_type,
    party.jgzz_fiscal_code,
    party.ORGANIZATION_NAME_PHONETIC,
    party.url,
    acct.cust_account_id,
    acct.account_number,
    party_site.party_site_id,
    party_site.party_site_number,
    cust_acct_site.CUST_ACCT_SITE_ID,
    loc.location_id,
    loc.address1,
    loc.address2,
    loc.city,
    loc.postal_code,
    NVL(loc.state,loc.province),
    loc.country,
    'RESELLER', --SITE_USE_TYPE
    null,--  SITE_USE_ID
    ooh.attribute16,--  CONTACT_ID
    hpc.person_first_name,--  CONTACT_FIRST_NAME
    hpc.person_last_name,--  CONTACT_LAST_NAME
    (SELECT email_address
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'EMAIL'
    AND rownum                < 2
    ),--  CONTACT_EMAIL
    (SELECT  REPLACE(REPLACE(REGEXP_REPLACE(
  (SELECT /*Warning: Reverse() is an undocumented Oracle SQL function*/
    reverse(to_char(transposed_phone_number))
    FROM hz_contact_points hcpe
    WHERE hcpe.owner_table_id = hcar.party_id
    AND hcpe.owner_table_name = 'HZ_PARTIES'
    AND contact_point_type    = 'PHONE'
    AND rownum                < 2
    ),'[^0-9]+', ''),'/','</'),'<<','<') from dual),--  CONTACT_PHONE
    hpc.party_id,--  CONTACT_PARTY_ID
    hcar.cust_account_role_id,--   CONTACT_CUST_ACCT_ROLE_ID
    null, --              CONTACT_CUST_ACCT_SITE_ID
    null, --BILL_TO_SITE_USE_ID
    null, --SHIP_TO_SITE_USE_ID
   (SELECT NVL((SELECT 'true'  FROM hz_code_assignments
    WHERE owner_table_name = 'HZ_PARTIES'
    AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
    AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
    AND class_code <> 'No'
    AND owner_table_id =  party.party_id),'false') FROM DUAL), --IS_PUBLIC_SECTOR
    (SELECT NVL((SELECT 'true' FROM hz_code_assignments
      WHERE owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND CLASS_CATEGORY = 'CHAIN'
      AND CLASS_CODE IS NOT NULL
      AND owner_table_id = party.party_id),'false') FROM DUAL), --IS_CHAIN_CUSTOMER
      (SELECT CLASS_CODE
      FROM hz_code_assignments
      WHERE CLASS_CATEGORY = 'CHAIN'
      AND owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND owner_table_id =party.party_id))  -- CUSTOMER_CHAIN_TYPE
  into v_payload.customers (5)
  FROM hz_cust_accounts acct,
    hz_parties party,
    oe_order_headers_all ooh,
    hz_cust_acct_sites_all cust_acct_site,
    hz_party_sites party_site,
    hz_locations loc,
    hz_cust_account_roles hcar,
    hz_relationships hr,
    hz_parties hpc
  WHERE ooh.ATTRIBUTE11 =
    acct.cust_account_id
  AND acct.party_id = party.party_id
  AND ooh.header_id = p_header_id
  and ooh.ATTRIBUTE10 = cust_acct_site.cust_acct_site_id(+)
  AND cust_acct_site.party_site_id    = party_site.party_site_id(+)
  AND party_site.location_id          = loc.location_id(+)
  AND ooh.ATTRIBUTE17                 = hcar.cust_account_role_id(+)
  AND NVL(hcar.role_type,'CONTACT')   = 'CONTACT'
  AND hcar.party_id                   = hr.party_id(+)
  AND NVL(hr.relationship_code,'CONTACT_OF')   IN ( SELECT lookup_value
                            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                            WHERE component  ='RELATIONSHIP_CODE'
                            AND application = 'MISIMD_SPM_CLOUD_WF'
                            AND LOOKUP_CODE  ='RELATIONSHIP_CODE'
                            AND enabled = 'Y')
  AND hr.subject_id                   = hpc.party_id(+)
  AND NVL(hr.subject_type,'PERSON')   = 'PERSON'
  ;
  EXCEPTION WHEN OTHERS THEN
  NULL;
  END;
  --
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<MISIMD_SPM_CUSTOMER> SOLD_TO/SHIP_TO/BILL_TO successful',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);

  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<CUSTOMERS> Fetch Successful',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --
  --Check TEXTURA Order--
  SELECT COUNT(*)
  INTO v_count_textura_lines
  FROM
    (SELECT misont_cloud_pub2.get_cloud_servicegroup_tag(ol.ordered_item,'SERVICE_GROUP') AS service_group
    FROM oe_order_lines_all ol
    WHERE ol.header_id    = p_header_id
    AND ol.item_type_code = 'SERVICE'
    )
  WHERE SERVICE_GROUP IN ('TEXTURACPMGCMB','TEXTURATPMGCMB','TEXTURATPMSCMB','TEXTURACPMSCMB');
  --Check if Old order was OPCM
  BEGIN
    SELECT pricing_attribute79
    INTO v_old_opcm
    FROM oe_order_price_attribs
    WHERE header_id                   = p_header_id
    AND pricing_attribute79          IS NOT NULL
    AND is_spm_eligible(line_id)      ='Y'
    AND NVL(pricing_attribute50,'X') <> 'REPLACETERMINATE'
    AND rownum                        =1;
  EXCEPTION WHEN OTHERS THEN
  v_old_opcm := 'X';
  END;
  --
  IF v_old_opcm <> 'X' THEN
    BEGIN
      SELECT header_id
      INTO v_old_order_id
      FROM MISONT_ORDER_LINE_ATTRIBS_EXT
      WHERE spm_plan_number = v_old_opcm
      AND ROWNUM            = 1;
    EXCEPTION
    WHEN OTHERS THEN
      v_old_order_id := '0';
    END;
  ELSE
    v_old_order_id := '0';
  END IF;
  --
  -- CHECK OPCM ORDER--For present and old order
  SELECT COUNT(pricing_attribute99)
  INTO v_count_extsite_lines
  FROM oe_order_price_attribs
  WHERE LINE_ID IN
    (SELECT LINE_ID
    FROM MISONT_ORDER_LINE_ATTRIBS_EXT
    WHERE HEADER_ID IN (p_header_id,v_old_order_id)
    )
  AND pricing_attribute99 ='EXTSITE';
  --
  --Change in logic for NPI-131
  --Check COMMIT_MODEL in ONBOARDING and UPDATE/EXTENSION order
  BEGIN
    SELECT DISTINCT ADDITIONAL_COLUMN42
    INTO v_order_commit_model
    FROM misont_order_line_attribs_ext
    WHERE header_id  in  (p_header_id,v_old_order_id)
    AND ADDITIONAL_COLUMN42 IS NOT NULL;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_order_commit_model := NULL;
  WHEN OTHERS THEN
    v_order_commit_model := 'Monthly';
  END;
  --



  --
  --Fetch Lines info - For B Part
  FOR i IN--p_header_id
  (SELECT line_id, (SELECT pricing_attribute94 from oe_order_price_attribs where line_id = ol.line_id) operation_type
    FROM oe_order_lines_all ol
    WHERE item_type_code            = 'SERVICE'
    AND header_id                   = p_header_id
    AND flow_status_code           <> 'CANCELLED'
    AND is_spm_eligible(ol.line_id) ='Y'
    AND EXISTS
    (SELECT 1
    FROM oe_order_price_attribs
    WHERE line_id           = ol.line_id
    AND header_id           = ol.header_id
    AND decode(p_subscription_id,NULL,'PROVISIONED',pricing_attribute93) = 'PROVISIONED'
    AND decode(p_operation_type,NULL,'1',pricing_attribute94) = NVL(p_operation_type,'1')
    AND decode(p_subscription_id,NULL,'1',decode(misimd_spm_cloud_wf.is_metered_subscription(v_line_id),'Y',
              p_subscription_id,NVL(pricing_attribute92,p_subscription_id))) = NVL(p_subscription_id,'1')
    AND decode(p_subscription_id,NULL,'Y',decode(misimd_spm_cloud_wf.is_metered_subscription(v_line_id),'Y',
              misimd_spm_cloud_wf.is_metered_subscription(line_id),'Y')) = 'Y'
    )
    AND EXISTS
      (SELECT 1
      FROM misont_order_line_attribs_ext
      WHERE line_id                      = ol.line_id
      AND header_id                      = ol.header_id
      AND NVL(spm_interface_status,'A') <> 'SPM_INTERFACED'
      AND NVL(spm_interface_error,'A')  NOT like '%Awaiting SPM Response%'
      --START: SPM-9458
      AND NVL(spm_plan_status,'A') = decode(spm_plan_status,NULL,'A',COALESCE(p_spl_payload_num,spm_plan_status,'A'))
      --END: SPM-9458
      )
    AND EXISTS
      (SELECT 1
      FROM mtl_system_items_b
      WHERE organization_id         = 14354
      AND segment1                  = ol.ordered_item
      AND SERVICEABLE_PRODUCT_FLAG <> 'Y'
      )
   UNION /*-- replaced UNION ALL with UNION for Bug 26314070 fix*/
    SELECT ol.line_id,  (SELECT pricing_attribute94 from oe_order_price_attribs where line_id = ol.line_id) operation_type
    FROM mtl_item_categories mic,
      mtl_categories_b mcb,
      oe_order_lines_all ol
    WHERE 1                         =1
    AND mic.category_id             = mcb.category_id
    AND mcb.enabled_flag            = 'Y'
    AND mic.organization_id         = 14354
    AND mic.inventory_item_id       = ol.inventory_item_id
    AND mcb.segment1         IN -- added for Bug 27411024 (CONSULTCLD/EDPILT/TECHSUPA/CLDSUBSFEE/CLDPREPAID)
    (SELECT lookup_value
    FROM MISIMD_INTF_LOOKUP
    WHERE lookup_code IN ('ONE_TIME_ITEM_CATEGORY','SUBSCRIPTION_ITEM_CATEGORY')
  AND application = 'MISIMD_SPM_CLOUD_WF'
    AND enabled  = 'Y'
    )
    AND ol.item_type_code           = 'STANDARD'
    AND ol.header_id                = p_header_id
    AND ol.flow_status_code        <> 'CANCELLED'
    AND is_spm_eligible(ol.line_id) ='Y'
    AND EXISTS
      (SELECT 1
      FROM oe_order_price_attribs
      WHERE line_id           = ol.line_id
      AND header_id           = ol.header_id
      AND decode(p_subscription_id,NULL,'PROVISIONED',pricing_attribute93) = 'PROVISIONED'
      )
    AND EXISTS
      (SELECT 1
      FROM misont_order_line_attribs_ext
      WHERE line_id                      = ol.line_id
      AND header_id                      = ol.header_id
      AND NVL(spm_interface_status,'A') <> 'SPM_INTERFACED'
      AND NVL(spm_interface_error,'A')  <> 'Awaiting SPM Response'
      )
    AND EXISTS
      (SELECT 1
      FROM mtl_system_items_b
      WHERE organization_id         = 14354
      AND segment1                  = ol.ordered_item
      AND SERVICEABLE_PRODUCT_FLAG <> 'Y'
      ) ORDER BY 2,1)
  loop
  --27691142 SRECHAND CHANGES BEGIN
  v_payload_lines := i.line_id;
  -- 27691142 SRECHAND CHANGES END
  --Update MISONT_ORDER_LINE_ATTRIBS_EXT
  MISIMD_SPM_CLOUD_WF.SET_SPM_INFO(p_line_id => i.line_id,p_SPM_INTERFACE_ERROR => 'Awaiting SPM Response');
  --
  v_payload.LINES.extend;
  v_payload.LINES(v_payload.LINES.count) := OSS_INTF_USER.MISIMD_SPM_LINES.new_instance ();
  SELECT ol.line_id,
    ol.line_number,
    is_metered_subscription(ol.line_id),
    misont_cloud_reporting.get_line_info (ol.line_id, 'CSI') CSI,
    (SELECT system_id
    FROM CSI_SYSTEMS_TL
    WHERE language = 'US'
    AND name       = misont_cloud_reporting .get_line_info (ol.line_id, 'CSI')
    AND rownum     < 2
    ) GSI_SYSTEM_ID,
    misont_cloud_pub2.get_addi_line_info(ol.line_id, 'OVERAGE_FLAG') OVERAGE_ENABLED,
    misont_cloud_pub2.get_addi_line_info(ol.line_id, 'OVERAGE_THRESHOLD') OVERAGE_THRESHOLD,
    misont_cloud_pub2.get_addi_line_info(ol.line_id, 'OVERAGE_BILLING_TERM') OVERAGE_BILLING_TERM,
    (SELECT decode(overage_policy_type,'Bill Overage at Price List','BOPL',
                                       'Bill Overage at Contract Price','BOCP',
                                       'Bill Overage at Specific Price','BOSP','BOPL')
    FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) overage_policy,
    (SELECT overage_price FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) overage_price,
    (SELECT committed_period FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) allowance_split_duration,
    (SELECT substr(committed_period_uom,1,1) FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) allowance_split_duration_uom,
    misont_cloud_pub2.is_subscription_tas_enabled(opa.pricing_attribute92) IS_SUBSCRIPTION_ENABLED,
    NVL(opa.pricing_attribute92,(SELECT subscription_id FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id)) subscription_id,
    (SELECT pricing_attribute94 FROM oe_order_price_attribs      WHERE line_id= ol.line_id  AND pricing_attribute94 IS NOT NULL AND ROWNUM=1) OPERATION_TYPE,
    pricing_attribute84 CLOUD_RENEWAL_FLAG,
    (select meaning
      from FND_LOOKUP_VALUES_VL
      where 1=1
      and lookup_type = 'WEB_QUOTE_RENEWAL_PRG_FLAG_LKP'
      and lookup_code = pricing_attribute84 and rownum < 2)CLOUD_RENEWAL_FLAG_MEANING,
    msi.segment1 INV_PART_NUMBER,
    ol.INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
    msi.description INV_PART_DESCRIPTION,
    ol.USER_ITEM_DESCRIPTION USER_ITEM_DESCRIPTION,
    ol.item_type_code ITEM_TYPE_CODE,
    decode(TO_CHAR(ol.service_start_date, 'YYYY-MM-DD')||' '
      ||TO_CHAR(ol.service_start_date, 'HH24:MI:SS'),' ',v_payload.START_DATE,
      TO_CHAR(ol.service_start_date, 'YYYY-MM-DD')||' '
      ||TO_CHAR(ol.service_start_date, 'HH24:MI:SS')) START_DATE,
    decode(TO_CHAR(ol.service_end_date, 'YYYY-MM-DD')||' '
      ||TO_CHAR(ol.service_end_date, 'HH24:MI:SS'),' ',v_payload.START_DATE,
      TO_CHAR(ol.service_end_date, 'YYYY-MM-DD')||' '
      ||TO_CHAR(ol.service_end_date, 'HH24:MI:SS')) END_DATE,
    ol.service_duration duration,
    'OBSCNTR_'||substr(service_period,1,1) DURATION_UNIT,
   DECODE ((SELECT UPPER(ADDITIONAL_COLUMN28) FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id),'TENCENT' ,
    (SELECT ADDITIONAL_COLUMN51 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id),
    (DECODE ((SELECT UPPER(ADDITIONAL_COLUMN29) FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id),'YES',
    (SELECT ADDITIONAL_COLUMN51 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id),
    NVL(opa.pricing_attribute75, ol.UNIT_SELLING_PRICE*ol.ordered_quantity)))) TCLV,
    (SELECT NVL(ADDITIONAL_COLUMN57,opa.pricing_attribute3)
    FROM misont_order_line_attribs_ext
    WHERE line_id = ol.line_id
    ) QUANTITY,
    opa.pricing_attribute88 CLOUD_FUTURE_MON_PRICE,
    opa.pricing_attribute99 CLOUD_DATA_CENTER_REGION,
    (SELECT meaning
    FROM qp_lookups
    WHERE lookup_type = 'MISQP_CLOUD_DATACENTER'
    AND enabled_flag  = 'Y'
    AND SYSDATE BETWEEN START_DATE_ACTIVE AND NVL(END_DATE_ACTIVE,SYSDATE+1)
    AND lookup_code = opa.pricing_attribute99) CLOUD_DATA_CENTER_REGION_M,
    opa.pricing_attribute91 CLOUD_ACC_ADMIN_EMAIL,
    NVL(ol.Ordered_Quantity, 0) * NVL(ol.unit_selling_price, 0)
     SERVICE_LINE_AMOUNT,
   (SELECT OPC_CUSTOMER_NAME
    FROM misont_order_line_attribs_ext
    WHERE line_id = ol.line_id) OPC_CUSTOMER_NAME,
   decode(opa.pricing_attribute78,NULL,NULL,
   TO_CHAR(to_date(opa.pricing_attribute78,'MM-DD-YYYY'), 'YYYY-MM-DD')||' '
      ||TO_CHAR(to_date(opa.pricing_attribute78,'MM-DD-YYYY'), 'HH24:MI:SS')) SPMIST4C,
   initcap(opa.pricing_attribute93) PROVISIONING_STATUS,
   TO_CHAR (to_date(COALESCE(opa.pricing_attribute61, opa.pricing_attribute62), 'MM-DD-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS') PROVISIONING_DATE,
   NVL(opa.pricing_attribute3,'0') CAP_TO_PRICELIST,
   NVL(opa.pricing_attribute83,'0') SPM_OLD_LINE_ID, --modified for BUG#25385746
   opa.pricing_attribute27 ENTITLEMENT_COUNTRYCODE,
   opa.pricing_attribute26 ENTITLEMENT_PHONENUMBER,
   ol.attribute6 BASE_ORDER_LINE_ID,
   decode(NVL(opa.pricing_attribute56,'N'),'Y','true','N','false','false') HAS_PROMOTION,
   decode(NVL(opa.pricing_attribute38,'N'),'Y','true','N','false','false') REBALANCE_OPTED,
   OE_SET_UTIL.Get_Fulfillment_List(ol.service_reference_line_id) FULFILLMENT_SET,
   opa.pricing_attribute50 REPLACE_REASON_CODE,
  opa.pricing_attribute51 SUPERSEDE_NOTES,
   opa.pricing_attribute52 REPLACE_SUBSCRIPTION_ID,
   (SELECT ADDITIONAL_COLUMN4 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) SUPERSEDED_SET_ID,
   opa.pricing_attribute28 UNIFIED_REVENUE_QUOTA,
   opa.pricing_attribute29 PARENT_LINE_ID,
   opa.pricing_attribute30 UNIFIED_REVENUE_AMOUNT,
   decode(NVL(opa.pricing_attribute31,'N'),'Y','true','N','false','false') IS_UNIFIED,
   (SELECT DECODE(upper(a.C_EXT_ATTR1),'MONTHLY','M','MONTH','M','SERVICE PERIOD','SP','QUATERLY','Q','ANNUAL','A','BI-ANNUAL','B',a.C_EXT_ATTR1)
    FROM EGO_MTL_SY_ITEMS_EXT_B A
    WHERE a.organization_id = 14354
    AND a.inventory_item_id = ol.INVENTORY_ITEM_ID
    AND a.ATTR_GROUP_ID     =
      (SELECT attr_group_id
      FROM EGO_ATTR_GROUPS_V
      WHERE attr_group_name = 'MISEGO_SPM_PP'
      )
    AND ROWNUM = 1
   ) PRICE_PERIOD,
   (SELECT ADDITIONAL_COLUMN10 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) RENEWAL,
   (SELECT ADDITIONAL_COLUMN11 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) UPSELL,
   (SELECT ADDITIONAL_COLUMN12 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CROSSSELL,
   (SELECT ADDITIONAL_COLUMN13 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) DOWNSELL,
   (SELECT ADDITIONAL_COLUMN14 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CLOUD_ACCOUNT_ID,
   (SELECT ADDITIONAL_COLUMN15 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CLOUD_ACCOUNT_NAME,
   (SELECT ADDITIONAL_COLUMN17 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ASSOCIATE_SUB_ID,
   (SELECT ADDITIONAL_COLUMN20 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ORIGINAL_PROMO_AMT,
   (SELECT ADDITIONAL_COLUMN28 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) PARTNER_TRANSACTION_TYPE,
   (SELECT ADDITIONAL_COLUMN29 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) IS_CREDIT_ENABLED,
   (SELECT ADDITIONAL_COLUMN30 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CREDIT_PERCENTAGE,
   (SELECT ADDITIONAL_COLUMN31 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) OVERAGE_BILL_TO,
   (SELECT ADDITIONAL_COLUMN32 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) RATE_CARD_DIS_PER,
   (SELECT ADDITIONAL_COLUMN38 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) PAYG_POLICY,
   (SELECT ADDITIONAL_COLUMN39 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) INTENT_TO_PAY, --SPM-6637
   (SELECT ADDITIONAL_COLUMN40 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) DEPLOYMENT_TYPE, --SPM-7586
   (SELECT ADDITIONAL_COLUMN41 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) DEPLOYMENT_NAME, --SPM-7586
   (SELECT ADDITIONAL_COLUMN42 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) COMMIT_MODEL,    --SPM-7835
   (SELECT COMMITTED_QUANTITY FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) COMMITTED_QUANTITY,
   (SELECT ADDITIONAL_COLUMN45 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) OVERAGE_DISCOUNT_PRCNT,
   (SELECT ADDITIONAL_COLUMN44 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ASSC_REV_SUBSC_MAP,--SPM-6780
   (SELECT (misont_cloud_pub2.get_order_header_info(p_header_id,'SALESREPS')) FROM DUAL)      COMP_SALES_REP, --SPM-9566
   (DECODE((SELECT count(*)  from misont_order_line_attribs_ext where ADDITIONAL_COLUMN46 = 'SPM'
    and header_id=p_header_id),'0','OM','SPM'))                          PROVISIONING_SOURCE, --SPM-9560
   (SELECT ADDITIONAL_COLUMN47 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) PARTNER_CREDIT_VALUE, --SPM-10101
    --Changes for SPM-9570 - SPMPROV
    opa.PRICING_ATTRIBUTE58 CLOUD_PROVISION_SEQ_NUM,
    opa.PRICING_ATTRIBUTE64 CLOUD_PO_TERM,
    opa.PRICING_ATTRIBUTE65 CLOUD_PO_TERM_UOM,
    opa.PRICING_ATTRIBUTE69 CLOUD_BACK_DATED_CONTRACT,
    opa.PRICING_ATTRIBUTE87 CLOUD_STORE_SSO_USERNAME,
    opa.PRICING_ATTRIBUTE85 CLOUD_REF_SUBSCRIPTION_ID,
    (SELECT ADDITIONAL_COLUMN3 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CUSTOMERS_CRM_CHOICE,
    (SELECT ADDITIONAL_COLUMN5 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ADMIN_FIRST_NAME,
    (SELECT ADDITIONAL_COLUMN6 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ADMIN_LAST_NAME,
    (SELECT ADDITIONAL_COLUMN7 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CUSTOMER_CODE,
    (SELECT ADDITIONAL_COLUMN8 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) LANGUAGE_PACK,
    (SELECT ADDITIONAL_COLUMN9 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) TALEO_CONSULTING_METHODOLOGY,
    (SELECT ADDITIONAL_COLUMN16 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) AUTO_CLOSE_FOR_PROVISIONING,
    (SELECT ADDITIONAL_COLUMN25 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CHANNEL_OPTION,
    (SELECT ADDITIONAL_COLUMN26 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) PARTNER_ID,
    (SELECT ADDITIONAL_COLUMN27 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) RAVELLO_TOKEN_ID,
   --Changes for SPM-9570 - SPMPROV
   --Changes for SPM-11135 begin- SPMPROV
    opa.PRICING_ATTRIBUTE69 CLOUD_BACK_DATED_FLAG,
    opa.PRICING_ATTRIBUTE68 PILOT_TYPE,
    opa.PRICING_ATTRIBUTE96 FIXED_END_DATE_FLAG,
    (SELECT ADDITIONAL_COLUMN37 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) NCER_ZONE,
    (SELECT ADDITIONAL_COLUMN35 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) NCER_TYPE,
    --Changes for SPM-11135 end- SPMPROV
    (SELECT ADDITIONAL_COLUMN53 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) SPECIAL_HANDLING_FLAG, --SPM-11120
    (SELECT ADDITIONAL_COLUMN54 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) LINE_OF_BUSINESS,  --SPM-11396
    (SELECT ADDITIONAL_COLUMN55 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) TEXTURA_TOKEN_ID,  --SPM-11366
    (SELECT ADDITIONAL_COLUMN52 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) APIARY_TOKEN_ID, --SPM-12114
    (SELECT TO_CHAR(TO_DATE(ADDITIONAL_COLUMN56),'YYYY-MM-DD HH24:MI:SS') FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CUSTOMER_READINESS_DATE, --SPM-12007
    (SELECT DEDICATED_COMPUTE_CAPACITY FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) DEDICATED_COMPUTE_CAPACITY, --SPM-12114
    ((TO_CHAR(to_date(opa.PRICING_ATTRIBUTE49,'MM-DD-YYYY'), 'YYYY-MM-DD')||' '||TO_CHAR(to_date(opa.PRICING_ATTRIBUTE49,'MM-DD-YYYY'), 'HH24:MI:SS'))) ESTIMATED_PROV_DATE,  --SPM-12007
    (SELECT COST_CENTER FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) COST_CENTER, --SPM-12837
    (SELECT COST_CENTER_DESCRIPTION FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) COST_CENTER_DESCRIPTION,  --SPM-12837
    (SELECT ADDITIONAL_COLUMN60 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) PROGRAM_TYPE,                 --SPM-12837
    (SELECT ADDITIONAL_COLUMN61 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) START_DATE_TYPE,              --SPM-13062
    (SELECT ADDITIONAL_COLUMN62 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) SALES_SCENARIO,               --SPM-13142
    (SELECT ADDITIONAL_COLUMN43 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) PROMOTION_TYPE_VAL,           --SPM-13797
    (SELECT ADDITIONAL_COLUMN58 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ORIGINAL_SUB_IDS,             --SPM-12396
    opa.pricing_attribute33 ULA2PAAS,          --SPM-13991
    opa.pricing_attribute34 ULAORDER,          --SPM-13991
    opa.pricing_attribute35 CREDIT4_REPUR_SUPP,--SPM-13991
    (SELECT ADDITIONAL_COLUMN63 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ASSET_TRANSFER_FLAG,      --SPM-14298
    (SELECT ADDITIONAL_COLUMN66 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) SYNC_START_DATE_OCC,      --SPM-14813
    (SELECT ADDITIONAL_COLUMN65 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CLOUD_OPERATION_ID,       --SPM-14760
    (SELECT ADDITIONAL_COLUMN49 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) COMMIT_SCHEDULE_ID,       --SPM-10446
    (SELECT ADDITIONAL_COLUMN69 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) COS_ORDER_LINEID,         --SPM-17533
    (SELECT ORIG_SYS_DOCUMENT_REF FROM oe_order_headers_all WHERE ORIG_SYS_DOCUMENT_REF LIKE '%CPQ%' AND HEADER_ID=p_header_id ) QUOTE_NUMBER, --SPM-16173
    (SELECT ADDITIONAL_COLUMN70 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) CONFIG_ID,          --SPM-17920
    (SELECT ADDITIONAL_COLUMN76 FROM misont_order_line_attribs_ext WHERE line_id = ol.line_id) ENFORCED_RATECARD   --SPM-18059
  INTO v_payload.LINES(v_payload.LINES.count).ORDER_LINE_ID,
    v_payload.LINES(v_payload.LINES.count).ORDER_LINE_NUMBER,
    v_payload.LINES(v_payload.LINES.count).METERED_SUBSCRIPTION,
    v_payload.LINES(v_payload.LINES.count).CSI,
    v_payload.LINES(v_payload.LINES.count).GSI_SYSTEM_ID,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_ENABLED,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_THRESHOLD,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_BILLING_TERM,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_POLICY,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_PRICE,
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION,
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION_UOM,
    v_payload.LINES(v_payload.LINES.count).IS_SUBSCRIPTION_ENABLED,
    v_payload.LINES(v_payload.LINES.count).SUBSCRIPTION_ID,
    v_payload.LINES(v_payload.LINES.count).OPERATION_TYPE,
    v_payload.LINES(v_payload.LINES.count).CLOUD_RENEWAL_FLAG,
    v_payload.LINES(v_payload.LINES.count).CLOUD_RENEWAL_FLAG_MEANING,
    v_payload.LINES(v_payload.LINES.count).INV_PART_NUMBER,
    v_payload.LINES(v_payload.LINES.count).INVENTORY_ITEM_ID,
    v_payload.LINES(v_payload.LINES.count).INV_PART_DESCRIPTION,
    v_payload.LINES(v_payload.LINES.count).USER_ITEM_DESCRIPTION,
    v_payload.LINES(v_payload.LINES.count).ITEM_TYPE_CODE,
    v_payload.LINES(v_payload.LINES.count).START_DATE,
    v_payload.LINES(v_payload.LINES.count).END_DATE,
    v_payload.LINES(v_payload.LINES.count).DURATION,
    v_payload.LINES(v_payload.LINES.count).DURATION_UNIT,
    v_payload.LINES(v_payload.LINES.count).TCLV,
    v_payload.LINES(v_payload.LINES.count).QUANTITY,
    v_payload.LINES(v_payload.LINES.count).CLOUD_FUTURE_MON_PRICE,
    v_payload.LINES(v_payload.LINES.count).CLOUD_DATA_CENTER_REGION,
    v_payload.LINES(v_payload.LINES.count).CLOUD_DATA_CENTER_REGION_M,
    v_payload.LINES(v_payload.LINES.count).CLOUD_ACC_ADMIN_EMAIL,
    v_payload.LINES(v_payload.LINES.count).SERVICE_LINE_AMOUNT,
    v_payload.LINES(v_payload.LINES.count).OPC_CUSTOMER_NAME,
    v_payload.LINES(v_payload.LINES.count).SPMIST4C,
    v_payload.LINES(v_payload.LINES.count).PROVISIONING_STATUS,
    v_payload.LINES(v_payload.LINES.count).PROVISIONING_DATE,
    v_payload.LINES(v_payload.LINES.count).CAP_TO_PRICELIST,
    v_payload.LINES(v_payload.LINES.count).SPM_OLD_LINE_ID,
    v_payload.LINES(v_payload.LINES.count).ENTITLEMENT_COUNTRYCODE,
    v_payload.LINES(v_payload.LINES.count).ENTITLEMENT_PHONENUMBER,
    v_payload.LINES(v_payload.LINES.count).BASE_ORDER_LINE_ID,
    v_payload.LINES(v_payload.LINES.count).HAS_PROMOTION,
    v_payload.LINES(v_payload.LINES.count).REBALANCE_OPTED,
    v_payload.LINES(v_payload.LINES.count).FULFILLMENT_SET,
    v_payload.LINES(v_payload.LINES.count).REPLACE_REASON_CODE,
    v_payload.LINES(v_payload.LINES.count).SUPERSEDE_NOTES,
    v_payload.LINES(v_payload.LINES.count).REPLACE_SUBSCRIPTION_ID,
    v_payload.LINES(v_payload.LINES.count).SUPERSEDED_SET_ID,
    v_payload.LINES(v_payload.LINES.count).UNIFIED_REVENUE_QUOTA,
    v_payload.LINES(v_payload.LINES.count).PARENT_LINE_ID,
    v_payload.LINES(v_payload.LINES.count).UNIFIED_REVENUE_AMOUNT,
    v_payload.LINES(v_payload.LINES.count).IS_UNIFIED,
    v_payload.LINES(v_payload.LINES.count).PRICE_PERIOD,
    v_payload.LINES(v_payload.LINES.count).RENEWAL,
    v_payload.LINES(v_payload.LINES.count).UPSELL,
    v_payload.LINES(v_payload.LINES.count).CROSSSELL,
    v_payload.LINES(v_payload.LINES.count).DOWNSELL,
    v_payload.LINES(v_payload.LINES.count).CLOUD_ACCOUNT_ID,
    v_payload.LINES(v_payload.LINES.count).CLOUD_ACCOUNT_NAME,
    v_payload.LINES(v_payload.LINES.count).ASSOCIATE_SUB_ID,
    v_payload.LINES(v_payload.LINES.count).ORIGINAL_PROMO_AMT,
    v_payload.LINES(v_payload.LINES.count).PARTNER_TRANSACTION_TYPE,
    v_payload.LINES(v_payload.LINES.count).IS_CREDIT_ENABLED,
    v_payload.LINES(v_payload.LINES.count).CREDIT_PERCENTAGE,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_BILL_TO,
    v_payload.LINES(v_payload.LINES.count).RATE_CARD_DIS_PER,
    v_payload.LINES(v_payload.LINES.count).PAYG_POLICY,
    v_payload.LINES(v_payload.LINES.count).INTENT_TO_PAY,         --SPM-6637
    v_payload.LINES(v_payload.LINES.count).DEPLOYMENT_TYPE,       --SPM-7586
    v_payload.LINES(v_payload.LINES.count).DEPLOYMENT_NAME,       --SPM-7586
    v_payload.LINES(v_payload.LINES.count).COMMIT_MODEL,          --SPM-7835
    v_payload.LINES(v_payload.LINES.count).COMMITTED_QUANTITY,
    v_payload.LINES(v_payload.LINES.count).OVERAGE_DISCOUNT_PRCNT,
    v_payload.LINES(v_payload.LINES.count).ASSC_REV_SUBSC_MAP,   --SPM-6780
    v_payload.LINES(v_payload.LINES.count).COMP_SALES_REP,       --SPM-9566
    v_payload.LINES(v_payload.LINES.count).PROVISIONING_SOURCE,  --SPM-9560
    v_payload.LINES(v_payload.LINES.count).PARTNER_CREDIT_VALUE, --SPM-10101
    --Changes for SPM-9570 - SPMPROV
    v_payload.LINES(v_payload.LINES.count).CLOUD_PROVISION_SEQ_NUM,
    v_payload.LINES(v_payload.LINES.count).CLOUD_PO_TERM,
    v_payload.LINES(v_payload.LINES.count).CLOUD_PO_TERM_UOM,
    v_payload.LINES(v_payload.LINES.count).CLOUD_BACK_DATED_CONTRACT,
    v_payload.LINES(v_payload.LINES.count).CLOUD_STORE_SSO_USERNAME,
    v_payload.LINES(v_payload.LINES.count).CLOUD_REF_SUBSCRIPTION_ID,
    v_payload.LINES(v_payload.LINES.count).CUSTOMERS_CRM_CHOICE,
    v_payload.LINES(v_payload.LINES.count).ADMIN_FIRST_NAME,
    v_payload.LINES(v_payload.LINES.count).ADMIN_LAST_NAME,
    v_payload.LINES(v_payload.LINES.count).CUSTOMER_CODE,
    v_payload.LINES(v_payload.LINES.count).LANGUAGE_PACK,
    v_payload.LINES(v_payload.LINES.count).TALEO_CONSULTING_METHODOLOGY,
    v_payload.LINES(v_payload.LINES.count).AUTO_CLOSE_FOR_PROVISIONING,
    v_payload.LINES(v_payload.LINES.count).CHANNEL_OPTION,
    v_payload.LINES(v_payload.LINES.count).PARTNER_ID,
    v_payload.LINES(v_payload.LINES.count).RAVELLO_TOKEN_ID,
   --Changes for SPM-9570 - SPMPROV
    v_payload.LINES(v_payload.LINES.count).CLOUD_BACK_DATED_FLAG,         --SPM-11135
    v_payload.LINES(v_payload.LINES.count).PILOT_TYPE,                    --SPM-11135
    v_payload.LINES(v_payload.LINES.count).FIXED_END_DATE_FLAG,           --SPM-11135
    v_payload.LINES(v_payload.LINES.count).NCER_ZONE,                     --SPM-11135
    v_payload.LINES(v_payload.LINES.count).NCER_TYPE,                     --SPM-11135
    v_payload.LINES(v_payload.LINES.count).SPECIAL_HANDLING_FLAG,         --SPM-11120
    v_payload.LINES(v_payload.LINES.count).LINE_OF_BUSINESS,              --SPM-11396
    v_payload.LINES(v_payload.LINES.count).TEXTURA_TOKEN_ID,              --SPM-11366
    v_payload.LINES(v_payload.LINES.count).APIARY_TOKEN_ID,               --SPM-11366
    v_payload.LINES(v_payload.LINES.count).CUSTOMER_READINESS_DATE,       --SPM-11366
    v_payload.LINES(v_payload.LINES.count).DEDICATED_COMPUTE_CAPACITY,    --SPM-12114
    v_payload.LINES(v_payload.LINES.count).ESTIMATED_PROV_DATE,           --SPM-12007
    v_payload.LINES(v_payload.LINES.count).COST_CENTER,                   --SPM-12837
    v_payload.LINES(v_payload.LINES.count).COST_CENTER_DESCRIPTION,       --SPM-12837
    v_payload.LINES(v_payload.LINES.count).PROGRAM_TYPE,                  --SPM-12837
    v_payload.LINES(v_payload.LINES.count).START_DATE_TYPE,               --SPM-13062
    v_payload.LINES(v_payload.LINES.count).SALES_SCENARIO,                --SPM-13142
    v_payload.LINES(v_payload.LINES.count).PROMOTION_TYPE_VAL,            --SPM-13797
    v_payload.LINES(v_payload.LINES.count).ORIGINAL_SUB_IDS,              --SPM-12396
    v_payload.LINES(v_payload.LINES.count).ULA2PAAS,                      --SPM-13991
    v_payload.LINES(v_payload.LINES.count).ULAORDER,                      --SPM-13991
    v_payload.LINES(v_payload.LINES.count).CREDIT4_REPUR_SUPP,            --SPM-13991
    v_payload.LINES(v_payload.LINES.count).ASSET_TRANSFER_FLAG,           --SPM-14298
    v_payload.LINES(v_payload.LINES.count).SYNC_START_DATE_OCC,           --SPM-14813
    v_payload.LINES(v_payload.LINES.count).CLOUD_OPERATION_ID,            --SPM-14760
    v_payload.LINES(v_payload.LINES.count).COMMIT_SCHEDULE_ID,            --SPM-10446
    v_payload.LINES(v_payload.LINES.count).COS_ORDER_LINEID,              --SPM-14334
    v_payload.LINES(v_payload.LINES.count).QUOTE_NUMBER,                  --SPM-16173
    v_payload.LINES(v_payload.LINES.count).CONFIG_ID,                     --SPM-17920
    v_payload.LINES(v_payload.LINES.count).ENFORCED_RATECARD              --SPM-18059
  FROM oe_order_lines_all ol,
    oe_order_price_attribs opa,
    mtl_system_items_b msi
  WHERE opa.header_id         = p_header_id
  AND msi.inventory_item_id = ol.inventory_item_id
  AND msi.organization_id   = 14354
  AND opa.line_id           = ol.line_id
  AND ol.line_id            = i.line_id;

  --

  SELECT oe.name,ooha.agreement_id,TO_CHAR(TO_DATE(oe.end_date_active ),'YYYY-MM-DD HH24:MI:SS')
  INTO v_payload.LINES(v_payload.LINES.count).AGREEMENT_NAME,--SPM-13242
       v_payload.LINES(v_payload.LINES.count).AGREEMENT_ID,
       v_payload.LINES(v_payload.LINES.count).AGREEMENT_END_DATE --SPM-14231
  FROM oe_order_headers_all ooha,
        oe_agreements_v oe
        WHERE ooha.header_id = p_header_id
        AND ooha.agreement_id = oe.agreement_id
        AND EXISTS
        (SELECT 1
        FROM oe_transaction_types_tl
        WHERE transaction_type_id = ooha.order_type_id
        AND name LIKE '%CLOUD%'
        AND language = 'US');
  --SPM-14637 changes start
  SELECT TO_CHAR(TO_DATE(oha.CONVERSION_RATE_DATE),'YYYY-MM-DD HH24:MI:SS'),
    oha.CONVERSION_TYPE_CODE,
    oha.CONVERSION_RATE
  INTO  v_payload.LINES(v_payload.LINES.count).CONVERSION_RATE_DATE,
        v_payload.LINES(v_payload.LINES.count).CONVERSION_TYPE_CODE,
        v_payload.LINES(v_payload.LINES.count).CONVERSION_RATE
    FROM oe_order_headers_all OHA
    where header_id=p_header_id;

  --SPM-14637 changes end

  --SPM-14386 START--



    SELECT
        upper(oes.name)
    INTO v_order_source
    FROM
        oe_order_sources oes,
        oe_order_headers_all oh
    WHERE
        oh.order_source_id = oes.order_source_id
        AND oh.header_id = p_header_id;

 BEGIN
    SELECT
        'Y'
    INTO v_asset_transfer_flag
    FROM
        misont_order_line_attribs_ext
    WHERE
        header_id = p_header_id
        AND additional_column63 = 'Y'
        AND ROWNUM = 1;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;


  IF (v_order_source ='CLOUDPORTAL' AND  v_payload.OPERATIONTYPE ='UPDATE' AND v_asset_transfer_flag ='Y' AND X_SYSTEM_ID IS NULL) THEN
    BEGIN
    APPS.MISIMD_CSI_SYSTEMS_WRAPPER.CREATE_SYSTEM(v_payload.customers(2).TCA_CUST_ACCOUNT_ID,v_payload.customers(2).CUST_ACCT_SITE_ID, v_payload.customers(2).CONTACT_CUST_ACCT_ROLE_ID, p_header_id,
    X_SYSTEM_ID, X_RETURN_STATUS, X_MSG_COUNT, X_MSG_DATA);
        IF (X_RETURN_STATUS = 'S' ) THEN
            BEGIN
                UPDATE oe_order_price_attribs
                SET pricing_attribute95 = X_SYSTEM_ID
                WHERE HEADER_ID= p_header_id;

            END;
        ELSE
            RAISE CSI_GENERATION_EXCEPTION;
        END IF;
    END;
  END IF;
  IF X_SYSTEM_ID IS NOT NULL THEN
    v_payload.LINES(v_payload.LINES.count).CSI := NVL(X_SYSTEM_ID,v_payload.LINES(v_payload.LINES.count).CSI);
  END IF;
   --SPM-14386 END--

  --Bug#26143912 - RenewedLine ID
  IF v_payload.LINES(v_payload.LINES.count).SPM_OLD_LINE_ID <> '0' THEN
    IF v_payload.LINES(v_payload.LINES.count).OPERATION_TYPE IN ('EXTENSION','INCONTRACT_EXTENSION','SUPERSEDE','RAMPED_EXTENSION','RAMPED_UPDATE') THEN
      IF v_payload.LINES(v_payload.LINES.count).OPERATION_TYPE = 'RAMPED_UPDATE' THEN
        --Chk if RAMPED_UPDATE is with RAMPED_ONBOARDING or not
        BEGIN
          SELECT DECODE(pricing_attribute94,'RAMPED_ONBOARDING','Y','N') OPERATION_TYPE
          INTO v_flag
          FROM oe_order_price_attribs
          WHERE header_id         = p_header_id
          AND pricing_attribute94 = 'RAMPED_ONBOARDING'
          AND ROWNUM              = 1;
        EXCEPTION
        WHEN OTHERS THEN
          v_flag := 'N';
        END;
        IF v_flag                                                 = 'Y' THEN
          v_payload.LINES(v_payload.LINES.count).SPM_OLD_LINE_ID := '0';
        END IF;
      ELSE
        NULL;
      END IF;
    ELSE
      v_payload.LINES(v_payload.LINES.count).SPM_OLD_LINE_ID := '0';
    END IF;
  END IF;
  --SPM-5320 - OM to SPM Integration PAYG with Promotion SKU
  SELECT DECODE(MISONT_CLOUD_PUB2.get_cloud_servicegroup_tag(ordered_item,'SERVICE_GROUP'),'PROMOMB','Dollar and Time','0')
  INTO v_payload.LINES(v_payload.LINES.count).PROMOTION_TYPE
  FROM oe_order_lines_all
  WHERE line_id = i.line_id;
  --
  BEGIN
    SELECT 'Y'
    INTO v_payload.LINES(v_payload.LINES.count).PROMOTION_ORDER
    FROM DUAL
    WHERE EXISTS
      (SELECT 'Y'
      FROM oe_order_lines_all
      WHERE MISONT_CLOUD_PUB2.get_cloud_servicegroup_tag(ordered_item,'SERVICE_GROUP')= 'PROMOMB'
      AND header_id                                                                   = p_header_id
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_payload.LINES(v_payload.LINES.count).PROMOTION_ORDER := 'N';
  END;
  --Fetch Contract Type - At Line Level - For OCM Orders
/* ------------------------------------------SPM-7825---START---------------psarngal-----------------*/
  BEGIN
    IF  ((v_order_commit_model IS NOT NULL) OR ((v_payload.LINES(v_payload.LINES.count).OPERATION_TYPE ='CONVERT_TO_UCM' or v_payload.LINES(v_payload.LINES.count).OPERATION_TYPE = 'RENEW_TO_UCM'))) THEN
    --
      BEGIN
          BEGIN
            SELECT lookup_value
            INTO v_meaning
            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
            WHERE component  ='CONTRACT_TYPE'
            AND application = 'MISIMD_SPM_CLOUD_WF'
            AND LOOKUP_CODE  ='Plan/Line Level'
            AND enabled = 'Y';
            EXCEPTION WHEN OTHERS THEN
            v_meaning := 'Line';
          END;
      --
      --
          IF v_meaning = 'Plan' THEN
          v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Universal Subscriptions';
          ELSE
          BEGIN

              SELECT lookup_value INTO v_contract_type
              FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
              WHERE component ='PRICING_MODEL'
              AND application = 'MISIMD_SPM_CLOUD_WF'
              AND LOOKUP_CODE   = v_order_commit_model
              AND enabled  = 'Y';
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
              v_contract_type := 'Cloud Universal Subscriptions';
          WHEN OTHERS THEN
              v_contract_type := 'Cloud Universal Subscriptions';
          END;
          v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := (v_contract_type);
          END IF;

      END;
    --
    v_payload.CONTRACT_TYPE := v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE;
    --
    ELSE
       BEGIN
          -- CREATE Cloud Universal Subscriptions for OPCM orders SPM-10500
           IF ( v_count_extsite_lines > 0 ) THEN
              BEGIN
                v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Universal Subscriptions';
                v_payload.CONTRACT_TYPE := 'Cloud Universal Subscriptions';
              END;
           ELSIF (v_count_textura_lines >0 ) THEN
              BEGIN
                v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Evergreen Subscriptions';
                v_payload.CONTRACT_TYPE := v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE;
              END;
            v_payload.CONTRACT_TYPE := v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE;
           ELSE
          --Fetch Contract Type - At Line Level - For non-commit model flow
               BEGIN
                   IF is_metered_subscription(i.line_id) = 'Y' THEN
                    BEGIN
                      v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Evergreen Subscriptions';
                      v_payload.CONTRACT_TYPE := v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE;
                    END;
                   ELSIF is_universal_subscription(i.line_id) = 'Y' THEN
                    BEGIN
                      v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Universal Subscriptions';
                      v_payload.CONTRACT_TYPE := 'Cloud Universal Subscriptions';
                    END;
                   ELSIF v_payload.CONTRACT_TYPE = 'Cloud Evergreen Subscriptions' THEN
                      v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Evergreen Subscriptions';
                      v_payload.LINES(1).CONTRACT_TYPE := 'Cloud Evergreen Subscriptions';-- to set Cloud Evergreen Subscriptions in case first line is Cloud Renewal Subscriptions
                   ELSE
                    BEGIN
                      v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := 'Cloud Renewable Subscriptions';
                      v_payload.CONTRACT_TYPE := v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE;
                    END;
                   END IF;
                END;
           END IF;
       END;
    END IF;
 EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_contract_type := 'NO_DATA_FOUND';
    WHEN OTHERS THEN
        v_contract_type := 'EXCEPTION ENCOUNTERED';
  END;
 /* ---------------------------------------------SPM-7825---END---------------psarngal-----------------*/
  --LINE_NET_AMOUNT/TCLV
  BEGIN
    SELECT DISTINCT mcb.segment1,months_between(ol.service_end_date+1,ol.service_start_date)
    INTO v_item_cat,v_service_period
    FROM mtl_item_categories mic,
         mtl_categories_b mcb,
         oe_order_lines_all ol
    WHERE 1                    =1
    AND mic.category_id        = mcb.category_id
    AND mcb.enabled_flag       = 'Y'
    AND mic.organization_id    = 14354
    AND mic.category_set_id    = 1
    AND mic.inventory_item_id  = ol.inventory_item_id
    AND ol.line_id             = i.line_id;
    v_payload.LINES(v_payload.LINES.count).INV_CATEGORY := v_item_cat;
    BEGIN
      SELECT NVL(mcb.segment1,'A')
      INTO v_item_usage_billing
      FROM mtl_item_categories mic,
          mtl_categories_b mcb,
          MTL_CATEGORY_SETS_TL mctl,
          oe_order_lines_all ol
      WHERE 1                    =1
      AND mic.category_id        = mcb.category_id
      AND mctl.CATEGORY_SET_ID   = mic.CATEGORY_SET_ID
      AND mctl.LANGUAGE          = 'US'
     AND mcb.enabled_flag       = 'Y'
      AND mctl.CATEGORY_SET_NAME = 'Usage Billing'
      AND mic.organization_id    = 14354
      AND mic.inventory_item_id  = ol.inventory_item_id
      AND ol.line_id             = i.line_id;
      v_payload.LINES(v_payload.LINES.count).USAGE_BILLING := v_item_usage_billing;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    v_item_usage_billing := 'A';
    v_payload.LINES(v_payload.LINES.count).USAGE_BILLING := v_item_usage_billing;
    WHEN OTHERS THEN
    v_item_usage_billing := 'B';
    v_payload.LINES(v_payload.LINES.count).USAGE_BILLING := v_item_usage_billing;
    END;
    --Bug#20838492
    BEGIN
      SELECT lookup_code
      INTO v_item_cat
      FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
      WHERE component = 'ITEM_CATEGORY'
    AND application = 'MISIMD_SPM_CLOUD_WF'
      AND lookup_code   IN ('ONE_TIME_ITEM_CATEGORY','SUBSCRIPTION_ITEM_CATEGORY')
      AND lookup_value       = v_item_cat;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_item_cat := 'SUBSCRIPTION_ITEM_CATEGORY';
   WHEN OTHERS THEN
      v_item_cat := 'SUBSCRIPTION_ITEM_CATEGORY';
    END;
    --Bug#21042446 - Check for pooled items
    v_payload.LINES(v_payload.LINES.count).POOLED_ITEM := 'N';
    BEGIN
      SELECT distinct 'ONE_TIME_ITEM_CATEGORY', 'Y'
        into   v_item_cat, v_payload.LINES(v_payload.LINES.count).POOLED_ITEM
        from   qp_list_lines         qll,
               qp_pricing_attributes qpa,
               QP_PRICE_FORMULAS_TL  pf,
               oe_order_lines_all ool
        where ool.line_id IN (i.line_id)
        and qll.list_header_id              = ool.price_list_id--qlh.list_header_id
        and nvl(qll.end_date_active, sysdate) >= sysdate
        and qpa.list_header_id                = qll.list_header_id
        and qpa.list_line_id                  = qll.list_line_id
        and qll.price_by_formula_id           = pf.price_formula_id
        and pf.price_formula_id               = qll.price_by_formula_id
        and qpa.product_attribute             = 'PRICING_ATTRIBUTE1'
        and qpa.product_attribute_context     = 'ITEM'
        and qpa.product_attr_value = to_char(ool.inventory_item_id)
        and pf.language                       = 'US'
        and nvl(qll.context,'License')        = 'License'
        and pf.name                           = 'Pooled Service - No Renewal Uplift'
        AND QLL.PRICE_BREAK_TYPE_CODE IS NULL;
    EXCEPTION WHEN OTHERS THEN
    v_payload.LINES(v_payload.LINES.count).POOLED_ITEM := 'N';
    END;
    --
    IF v_item_cat = 'SUBSCRIPTION_ITEM_CATEGORY' THEN
    v_payload.LINES(v_payload.LINES.count).INV_CATEGORY := 'CLOUDSUBS';
    END IF;
    v_payload.LINES(v_payload.LINES.count).LINE_NET_AMOUNT := to_number(v_payload.LINES(v_payload.LINES.count).COMMITTED_QUANTITY) *
      to_number(v_payload.LINES(v_payload.LINES.count).CLOUD_FUTURE_MON_PRICE);
    v_item_cat := NULL;
    v_item_usage_billing := NULL;
    v_service_period := 1;
  EXCEPTION WHEN OTHERS THEN
    v_payload.LINES(v_payload.LINES.count).LINE_NET_AMOUNT := '0';
               --Bug#21659562
    --v_payload.LINES(v_payload.LINES.count).TCLV := '0';
    v_payload.LINES(v_payload.LINES.count).INV_CATEGORY := NULL;
    v_item_cat := NULL;
    v_item_usage_billing := NULL;
    v_service_period := 1;
  END;
  --CAP_TO_PRICELIST
   IF (v_payload.LINES(v_payload.LINES.count).USAGE_BILLING = 'METERED_BILLING'
    OR v_payload.LINES(v_payload.LINES.count).USAGE_BILLING = 'METERED_BURNDOWN'
    OR v_payload.LINES(v_payload.LINES.count).USAGE_BILLING = 'METERED_SUBCOMMIT')
  and to_number(v_payload.LINES(v_payload.LINES.count).CAP_TO_PRICELIST) >= 0
  THEN
  v_payload.LINES(v_payload.LINES.count).CAP_TO_PRICELIST := 'true';
  ELSE
  v_payload.LINES(v_payload.LINES.count).CAP_TO_PRICELIST := 'false';
  END IF;
  IF v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION_UOM = 'S' OR
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION_UOM IS NULL THEN
    v_payload.LINES(v_payload.LINES.count).SPLIT_ALLOWANCE := 'N';
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION := NULL;
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION_UOM := NULL;
  --SPLIT_ALLOWANCE--Commented as part of JIRA - SPM-5742
  /*
  ELSE
  BEGIN
    SELECT months_between(service_end_date+1,service_start_date),substr(service_period,1,1)
    INTO v_service_period, v_service_UOM
    FROM oe_order_lines_all
    WHERE line_id = i.line_id;
    IF v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION_UOM = 'Y' THEN
    v_service_period := v_service_period/12;
    END IF;
    IF v_service_period > v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION THEN
    v_payload.LINES(v_payload.LINES.count).SPLIT_ALLOWANCE := 'Y';
    ELSE
    v_payload.LINES(v_payload.LINES.count).SPLIT_ALLOWANCE := 'N';
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION := NULL;
    v_payload.LINES(v_payload.LINES.count).ALLOWANCE_SPLIT_DURATION_UOM := NULL;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_payload.LINES(v_payload.LINES.count).SPLIT_ALLOWANCE := NULL;
  END; */
  END IF;
  --PO_EXPIRY_DATE
  BEGIN
    /*SELECT (TO_CHAR(nvl(to_date(opa.PRICING_ATTRIBUTE73,'MM-DD-YYYY'),ol.service_end_date), 'YYYY-MM-DD')
      ||'T'
      ||TO_CHAR(nvl(to_date(opa.PRICING_ATTRIBUTE73,'MM-DD-YYYY'),ol.service_end_date), 'HH24:MI:SS')
      ||'.0Z') PO_EXPIRY_DATE*/
    /*SELECT (TO_CHAR(nvl(to_date(opa.PRICING_ATTRIBUTE73,'MM-DD-YYYY'),ol.service_end_date), 'YYYY-MM-DD')
      ||' '
      ||TO_CHAR(nvl(to_date(opa.PRICING_ATTRIBUTE73,'MM-DD-YYYY'),ol.service_end_date), 'HH24:MI:SS')
      ) PO_EXPIRY_DATE  */
    select to_char(max(coalesce(to_date(PRICING_ATTRIBUTE73, 'MM-DD-YYYY'), ol.service_end_date ))
      , 'YYYY-MM-DD HH24:MI:SS')
    INTO v_payload.LINES(v_payload.LINES.count).PO_EXPIRY_DATE
    FROM oe_order_lines_all ol,
      oe_order_price_attribs opa
    WHERE opa.line_id = ol.line_id
    AND ol.header_id   = p_header_id;

    IF v_payload.LINES(v_payload.LINES.count).PO_EXPIRY_DATE = 'T.0Z' THEN
    v_payload.LINES(v_payload.LINES.count).PO_EXPIRY_DATE := NULL;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_payload.LINES(v_payload.LINES.count).PO_EXPIRY_DATE := NULL;
  END;
  --BILL_TO - Line Level
  BEGIN
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetching <MISIMD_SPM_CUSTOMER> BILL_TO - Line Level',
    p_audit_level => 2,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --
  v_payload.LINES(v_payload.LINES.count).customers.extend (1);
  v_payload.LINES(v_payload.LINES.count).customers (1) := OSS_INTF_USER.MISIMD_SPM_CUSTOMER.NEW_INSTANCE();
  --
    SELECT OSS_INTF_USER.MISIMD_SPM_CUSTOMER (party.party_id,
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
      ), party.party_number, party.party_name, party.party_type,
      party.jgzz_fiscal_code, party.ORGANIZATION_NAME_PHONETIC, party.url,
      acct.cust_account_id, acct.account_number, party_site.party_site_id,
      party_site.party_site_number,cust_acct_site.CUST_ACCT_SITE_ID,
      loc.location_id, loc.address1, loc.address2, loc.city, loc.postal_code,
      NVL(loc.state,loc.province),loc.country
      /*(SELECT territory_short_name
      FROM fnd_territories_tl
      WHERE territory_code = loc.country
      AND language         = 'US'
      )*/
      , cust_site_use.site_use_code, cust_site_use.site_use_id,
      ool.INVOICE_TO_CONTACT_ID, hpc.person_first_name, hpc.person_last_name,
      (SELECT email_address
      FROM hz_contact_points hcpe
      WHERE hcpe.owner_table_id = hcar.party_id
      AND hcpe.owner_table_name = 'HZ_PARTIES'
      AND contact_point_type    = 'EMAIL'
      AND rownum                < 2
      ),
      (SELECT  REPLACE(REPLACE(REGEXP_REPLACE(
    (SELECT /*Warning: Reverse() is an undocumented Oracle SQL function*/
      reverse(to_char(transposed_phone_number))
      FROM hz_contact_points hcpe
      WHERE hcpe.owner_table_id = hcar.party_id
      AND hcpe.owner_table_name = 'HZ_PARTIES'
      AND contact_point_type    = 'PHONE'
      AND rownum                < 2
      ),'[^0-9]+', ''),'/','</'),'<<','<') from dual),
    hpc.party_id,hcar.cust_account_role_id,NULL, NULL, NULL,
      (SELECT NVL((SELECT 'true'  FROM hz_code_assignments
    WHERE owner_table_name = 'HZ_PARTIES'
    AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
    AND CLASS_CATEGORY = 'Oracle Public Sector Flag'
    AND class_code <> 'No'
    AND owner_table_id =  party.party_id),'false' ) FROM DUAL), --IS_PUBLIC_SECTOR
    (SELECT NVL((SELECT 'true' FROM hz_code_assignments
      WHERE owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND CLASS_CATEGORY = 'CHAIN'
      AND CLASS_CODE IS NOT NULL
      AND owner_table_id = party.party_id),'false') FROM DUAL), --IS_CHAIN_CUSTOMER
      (SELECT CLASS_CODE
      FROM hz_code_assignments
      WHERE CLASS_CATEGORY = 'CHAIN'
      AND owner_table_name = 'HZ_PARTIES'
      AND sysdate BETWEEN start_date_active AND COALESCE(end_date_active, sysdate )
      AND owner_table_id =party.party_id))  -- CUSTOMER_CHAIN_TYPE
    --KK INTO v_payload.customers (1)
    INTO v_payload.LINES(v_payload.LINES.count).customers (1)
    FROM hz_cust_site_uses_all cust_site_use,
      hz_cust_acct_sites_all cust_acct_site,
      hz_party_sites party_site,
      hz_cust_accounts acct,
      hz_parties party,
      hz_locations loc,
      oe_order_headers_all ooh,
      oe_order_lines_all ool,
      hz_cust_account_roles hcar,
      hz_relationships hr,
      hz_parties hpc
    WHERE 1                             = 1
    AND ool.invoice_to_org_id           = cust_site_use.site_use_id
    AND cust_site_use.site_use_code     = 'BILL_TO'
    AND cust_acct_site.cust_account_id  = acct.cust_account_id
    AND cust_site_use.cust_acct_site_id = cust_acct_site.cust_acct_site_id
    AND cust_acct_site.party_site_id    = party_site.party_site_id
    AND party_site.party_id             = party.party_id
    AND party_site.location_id          = loc.location_id
    AND ool.header_id                   = ooh.header_id
    AND ool.line_id                     = i.line_id
    AND ool.invoice_TO_CONTACT_ID       = hcar.cust_account_role_id(+)
    AND NVL(hcar.role_type,'CONTACT')   = 'CONTACT'
    AND hcar.party_id                   = hr.party_id(+)
    AND NVL(hr.relationship_code,'CONTACT_OF')   IN ( SELECT lookup_value
                            FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
                            WHERE component  ='RELATIONSHIP_CODE'
                            AND application = 'MISIMD_SPM_CLOUD_WF'
                            AND LOOKUP_CODE  ='RELATIONSHIP_CODE'
                            AND enabled = 'Y')
    AND hr.subject_id                   = hpc.party_id(+)
    AND NVL(hr.subject_type,'PERSON')   = 'PERSON';
  EXCEPTION WHEN OTHERS THEN
  NULL;
  END;
  --Fetch Sales Credit Data
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetch <SALES_CREDIT>',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --
  BEGIN
    SELECT DISTINCT line_id
    INTO v_sc_line_id
    FROM oe_sales_credits
    WHERE header_id   = p_header_id
    AND line_id       = i.line_id
    AND sales_credit_type_id = 1000
    AND percent        > 0;
  EXCEPTION WHEN OTHERS THEN
  v_sc_line_id := NULL;
  END;
  FOR sales_credit IN c_sales_credit (p_header_id,v_sc_line_id)
  LOOP
    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => 'Fetching <MISIMD_SPM_SALES_CREDIT>',
      p_audit_level => 2,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);

    v_payload.LINES(v_payload.LINES.count).sales_credit.extend;
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT)
    := OSS_INTF_USER.MISIMD_SPM_sales_credit.new_instance ();
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT).SALESREP_ID
    := sales_credit.SALESREP_ID;
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT).SALESREP_NUMBER
    := sales_credit.SALESREP_NUMBER;
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT).SALESREP_NAME
    := sales_credit.SALESREP_NAME;
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT).SALESREP_EMAIL
    := sales_credit.SALESREP_EMAIL;
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT).PERCENT
    := sales_credit.PERCENT;
    v_payload.LINES(v_payload.LINES.count).sales_credit (v_payload.LINES(v_payload.LINES.count).sales_credit.COUNT).SALES_CREDIT_TYPE_ID
    := sales_credit.SALES_CREDIT_TYPE_ID;

    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => '<MISIMD_SPM_SALES_CREDIT> Fetch Successful',
      p_audit_level => 2,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);
  END LOOP;
  --Fetch Optional Tiers Data
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetch <OPTIONAL_TIERS>',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  FOR optional_tiers IN c_otiers (p_header_id,i.line_id)
  LOOP
    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => 'Fetching <MISIMD_SPM_OPTIONAL_TIERS>',
      p_audit_level => 2,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);

    v_payload.LINES(v_payload.LINES.count).optional_tiers.extend;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT)
    := OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS.new_instance ();
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).INV_PART_NUMBER
    := optional_tiers.INV_PART_NUMBER;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).INV_PART_DESCRIPTION
    := optional_tiers.INV_PART_DESCRIPTION;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).INVENTORY_ITEM_ID
    := optional_tiers.INVENTORY_ITEM_ID;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).OPTIONAL_TIERS_RATE_CARD_ID
    := optional_tiers.OPTIONAL_TIERS_RATE_CARD_ID;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).PRICED_PRICE_LIST_ID
    := optional_tiers.PRICED_PRICE_LIST_ID;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).QUANTITY
    := optional_tiers.QUANTITY;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).UNIT_LIST_PRICE
    := optional_tiers.UNIT_LIST_PRICE;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).UNIT_SELLING_PRICE
    := optional_tiers.UNIT_SELLING_PRICE;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).PRICING_UOM
    := optional_tiers.PRICING_UOM;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).STANDARD_DISCOUNT_PERCENT
    := optional_tiers.STANDARD_DISCOUNT_PERCENT;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).MANUAL_DISCOUNT_PERCENT
   := optional_tiers.MANUAL_DISCOUNT_PERCENT;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).TOTAL_DISCOUNT_PERCENT
    := optional_tiers.TOTAL_DISCOUNT_PERCENT;
    /*v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).START_DATE
    := TO_CHAR(optional_tiers.START_DATE, 'YYYY-MM-DD')||'T'
      ||TO_CHAR(optional_tiers.START_DATE, 'HH24:MI:SS')||'.0Z';*/
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).START_DATE
    := TO_CHAR(optional_tiers.START_DATE, 'YYYY-MM-DD')||' '
      ||TO_CHAR(optional_tiers.START_DATE, 'HH24:MI:SS');
    /*v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).END_DATE
    := TO_CHAR(optional_tiers.END_DATE, 'YYYY-MM-DD')||'T'
      ||TO_CHAR(optional_tiers.END_DATE, 'HH24:MI:SS')||'.0Z';*/
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).END_DATE
    := TO_CHAR(optional_tiers.END_DATE, 'YYYY-MM-DD')||' '
      ||TO_CHAR(optional_tiers.END_DATE, 'HH24:MI:SS');
    SELECT decode(optional_tiers.SUB_OVERAGE_POLICY_TYPE,'Bill Overage at Price List','BOPL',
                                       'Bill Overage at Contract Price','BOCP',
                                       'Bill Overage at Specific Price','BOSP','BOPL')
    INTO v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).SUB_OVERAGE_POLICY_TYPE
    FROM dual;
    v_payload.LINES(v_payload.LINES.count).optional_tiers (v_payload.LINES(v_payload.LINES.count).optional_tiers.COUNT).SUB_OVERAGE_PRICE
    := optional_tiers.SUB_OVERAGE_PRICE;

    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => '<MISIMD_SPM_OPTIONAL_TIERS> Fetch Successful',
      p_audit_level => 2,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);
  END LOOP;
  --Fetch BOM Data
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetch <BOM_COMPONENTS>',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  FOR bom_component IN c_bom_components (i.line_id)
  LOOP
    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => 'Fetching <MISIMD_SPM_BOM_COMPONENT>',
      p_audit_level => 2,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);

    v_payload.LINES(v_payload.LINES.count).bom_components.extend;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) :=
    OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT.new_instance ();
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .INV_PART_NUMBER
    := bom_component.INV_PART_NUMBER;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT)
    .INV_PART_DESCRIPTION := bom_component.INV_PART_DESCRIPTION;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT)
    .INVENTORY_ITEM_ID := bom_component.INVENTORY_ITEM_ID;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT)
    .PRICE_BAND_ITEM_FLAG                                                  := bom_component.PRICE_BAND_ITEM_FLAG;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .PRICING_UOM :=
    bom_component.PRICING_UOM;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .RATE_CARD_ID :=
    bom_component.RATE_CARD_ID;
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .SPM_PRODUCT_ID
                                                                           := '0';
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .SPM_LINE_ID :=
    '0';
    v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .PRICE_PERIOD
    := bom_component.PRICE_PERIOD;

    --Fetch RATE_CARD
    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => 'Fetching <RATE_CARD>',
      p_audit_level => 3,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);

 SELECT CAST (collect (OSS_INTF_USER.MISIMD_SPM_RATE_CARD (
      L.FROM_BAND_QUANTITY, L.TO_BAND_QUANTITY, L.UNIT_LIST_PRICE,
      L.UNIT_SELLING_PRICE, L.UNIT_SELLING_PRICE_UOM ,L.OVERAGE_PRICE ,L.OVERAGE_PRICE_UOM,
      L.STANDARD_DISCOUNT_PERCENT , L.DISCR_DISCOUNT_PRCNT, L.DISCOUNT_CATEGORY , L.OVERAGE_DISCOUNT_PRCNT)) AS
      OSS_INTF_USER.MISIMD_SPM_RATE_CARD_TBL) RATE_CARD,
      MIN (NVL (L.PRICE_BAND_ITEM_FLAG, '0'))
    INTO v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT) .RATE_CARD,
      v_payload.LINES(v_payload.LINES.count).bom_components (v_payload.LINES(v_payload.LINES.count).bom_components.COUNT)
      .PRICE_BAND_ITEM_FLAG
    FROM MISQP_CLOUD_CREDITS_HDRS_ALL H,
      MISQP_CLOUD_CREDITS_LINES_ALL L,
      oe_order_lines_all ool
    WHERE H.TRANSACTION_HDR_ID = L.TRANSACTION_HDR_ID
    AND H.om_order_header_id   = ool.header_id
    AND l.inventory_item_id    = bom_component.INVENTORY_ITEM_ID
    AND ool.inventory_item_id  = l.parent_inventory_item_id --psarngal-- added for bug#26934150 fix
    AND ool.line_id            = i.line_id;

    insert_log(p_module =>'GET_BUS_EVENT_XML',
      p_audit_message => '<MISIMD_SPM_BOM_COMPONENT> Fetch Successful',
      p_audit_level => 2,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);
  END LOOP;

  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<BOM_COMPONENTS> fetch Successful',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  --Fetch Entitlement Component(license component) BOM details
  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => 'Fetch <ENTITLEMENT_COMPONENTS>',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);

  /*Note: Suppose item hierarchy is
  PartA
   - Child1
   - Child2
  We require final MISIMD_SPM_ENT_COMPONENT to look like
  PartA.Child1
  PartA.Child2
  PartA.PartA
  So we select the children first in PartA.Child1 format and then do a
  multiset union to PartA.PartA*/
 --MODIFIED THE QUERY for enhanced performance--
     SELECT CAST(multiset
      (SELECT OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT(sevenpart.inventory_item_id  -- IS PARENT_INVENTORY_ITEM_ID
        , sevenpart.segment1                                                      -- IS PARENT_PART_NUMBER
        , sevenpart.description                                                   -- IS PARENT_PART_DESCRIPTION
        , sevencpart.inventory_item_id                                            -- IS CHILD_INVENTORY_ITEM_ID
        , sevencpart.segment1                                                     -- IS CHILD_PART_NUMBER
        , sevencpart.description                                                  -- IS CHILD_PART_DESCRIPTION
        , to_number(bom_component.item_num)+10                                    -- IS LINE_NUMBER
        , mc.segment1                                                             -- IS LICENSE_METRIC
        , '0'                                                                     -- IS COMMITTED_QUANTITY
        , bom_component.attribute1                                                -- QUANTITY_CONSTRAINT
        , bom_component.attribute2                                                -- QUANTITY_MULTIPLIER
        , bom_component.attribute3                                                -- FIRST_PURCHASE
        , misimd_spm_cloud_wf.get_service_part(TO_CHAR(sevencpart.segment1))      -- SERVICE_PART_ID
        , misimd_spm_cloud_wf.get_service_part_desc(TO_CHAR(sevencpart.segment1)) -- SERVICE_PART_DESCRIPTION
        )
      FROM BOM_BILL_OF_MATERIALS_V bom,
        BOM_INVENTORY_COMPONENTS_V bom_component,
        mtl_system_items_b sevencpart,
        oe_order_lines_all oel,
        mtl_system_items_b sevenpart,
        mtl_item_categories mic,
        mtl_categories mc,
        MISONT_ORDER_LINE_ATTRIBS_EXT la
      WHERE 1                  = 1
      AND bom.assembly_item_id = oel.inventory_item_id
      AND oel.line_id          =
        (SELECT service_reference_line_id
        FROM oe_order_lines_all
        WHERE line_id = i.line_id --1408354829
        )
      AND sevenpart.organization_id                    = bom.organization_id
      AND sevenpart.inventory_item_id                  = oel.inventory_item_id
      AND bom.organization_id                          = 14354
      AND bom.bill_sequence_id                         = bom_component.BILL_SEQUENCE_ID
      AND sevencpart.inventory_item_id                 = bom_component.COMPONENT_ITEM_ID
      AND sevencpart.organization_id                   = bom.organization_id
      AND NVL(bom_component.disable_date, sysdate + 1) > sysdate
      AND mic.inventory_item_id                        = sevencpart.inventory_item_id
      AND sevencpart.organization_id                   = mic.organization_id
      AND mic.category_set_id                          = 1100026004
      AND mc.category_id                               = mic.category_id
        -- Change to restrict entitlements based on rate card (if populated) --4/5/2018
      AND oel.line_id                                           = la.line_id
      AND ( (sevencpart.segment1,sevencpart.inventory_item_id) IN
        ( SELECT DISTINCT qpp.pricing_attr_value_from sevenpart,
          sevenpart.inventory_item_id sevenpart_inv_id
        FROM misqp_cloud_credits_lines_all cloud,
          mtl_system_items_b bpart,
          mtl_system_items_b sevenpart,
          qp_list_lines qpl,
          qp_pricing_attributes qpp,
          qp_list_headers pl
        WHERE bpart.segment1            = cloud.inv_part_number
        AND qpp.product_attr_value      = bpart.inventory_item_id
        AND bpart.organization_id       = 14354
        AND qpp.pricing_attr_value_from = sevenpart.segment1
        AND sevenpart.organization_id   = 14354
        AND cloud.rate_card_id          = la.rate_card_id
        AND qpl.list_line_id            = qpp.list_line_id
        AND qpl.list_header_id          = pl.list_header_id
        AND TRUNC(SYSDATE) BETWEEN(TRUNC(NVL(qpl.start_date_active,SYSDATE) ) ) AND(TRUNC(NVL(qpl.end_date_active,SYSDATE + 1) ) )
        AND qpp.product_attribute           = 'PRICING_ATTRIBUTE1'
        AND qpp.product_attribute_context   = 'ITEM'
        AND qpp.list_header_id              = pl.list_header_id
        AND qpp.list_header_id              = qpl.list_header_id
        AND pl.list_type_code               = 'PRL'
        AND pl.currency_code                = 'USD'
        AND qpp.pricing_phase_id            = 1
        AND pl.name                                  IN( 'CURRENT COMMERCIAL','SUBSCRIPTION CURRENT COMMERCIAL','SUBSCRIPTION PRICE HOLD PRICE LIST' )
        AND qpp.qualification_ind                    IN( 4,6,20,22 )
        AND NVL(pl.end_date_active,SYSDATE) > SYSDATE - 1
        AND qpp.pricing_attribute_context   = 'PRICING ATTRIBUTE'
        )
      OR la.rate_card_id IS NULL)
        --
      ) AS OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL )
      into v_payload.LINES(v_payload.LINES.count).entitlement_components
    FROM dual;
  --

  select
  CAST(multiset
    (SELECT OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT(msi.inventory_item_id
      -- IS PARENT_INVENTORY_ITEM_ID
      , msi.segment1
      -- IS PARENT_PART_NUMBER
      , msi.description
      -- IS PARENT_PART_DESCRIPTION
      , msi.inventory_item_id
      -- IS CHILD_INVENTORY_ITEM_ID
      , msi.segment1
      -- IS CHILD_PART_NUMBER
      , msi.description
      -- IS CHILD_PART_DESCRIPTION
      --, (select nvl(max(LINE_NUMBER), 0) + 10
      --from table(v_payload.LINES(v_payload.LINES.count).entitlement_components))
      ,'10'
      -- IS LINE_NUMBER
      , mc.segment1
      -- IS LICENSE_METRIC
      , (SELECT committed_quantity
      FROM misont_order_line_attribs_ext
      WHERE line_id = i.line_id)
      -- IS COMMITTED_QUANTITY
      , bom_component.attribute1
      -- QUANTITY_CONSTRAINT
      , bom_component.attribute2
      -- QUANTITY_MULTIPLIER
      , bom_component.attribute3
      -- FIRST_PURCHASE
      , get_service_part(to_char(msi.segment1))
      -- SERVICE_PART_ID
      , get_service_part_desc(to_char(msi.segment1))
      -- SERVICE_PART_DESCRIPTION
      )
    FROM oe_order_lines_all oel,
      mtl_system_items_b msi,
      mtl_item_categories mic,
      mtl_categories mc,
      BOM_INVENTORY_COMPONENTS_V bom_component
    WHERE 1                   = 1
    AND msi.organization_id   = 14354
    AND mic.inventory_item_id = msi.inventory_item_id
    AND msi.organization_id = mic.organization_id
    AND mic.category_set_id   = 1100026004
    AND mc.category_id = mic.category_id
    AND oel.inventory_item_id = msi.inventory_item_id
    AND msi.inventory_item_id = bom_component.COMPONENT_ITEM_ID (+)
    AND NVL(bom_component.disable_date(+), sysdate + 1) > sysdate
    AND oel.line_id           =
      (SELECT service_reference_line_id
      FROM oe_order_lines_all
      WHERE line_id = i.line_id
      )
    and rownum < 2
    ) AS OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL)
  into v_parent_ent_comp
  from dual;

  --v_payload.LINES(v_payload.LINES.count).entitlement_components := v_payload.LINES(v_payload.LINES.count).entitlement_components
    --multiset union all v_parent_ent_comp;
  v_payload.LINES(v_payload.LINES.count).entitlement_components := v_parent_ent_comp
    multiset union all v_payload.LINES(v_payload.LINES.count).entitlement_components;

  --Update MISONT_ORDER_LINE_ATTRIBS_EXT
  MISIMD_SPM_CLOUD_WF.SET_SPM_INFO(p_line_id => i.line_id,
                                 p_SPM_INTERFACE_ERROR => 'Awaiting SPM Response');
  --START: SPM-9458
  IF p_spl_subs_plan_type IS NOT NULL THEN
  v_payload.CONTRACT_TYPE := p_spl_subs_plan_type;
  v_payload.LINES(v_payload.LINES.count).CONTRACT_TYPE := p_spl_subs_plan_type;
  END IF;
  IF p_spl_payload_num IS NOT NULL and p_spl_payload_num = 'UCM' THEN
  --
  v_payload.SUPERSEDED_PROJECT := v_old_spm_plan_spl;
  --
  v_payload.SPM_PLAN_NUMBER := '0';
  --
  v_payload.ATTRIBUTE1 := '';
  --
  END IF;
  --END: SPM-9458
  end loop;
  --Assign Plan Name: 06/29/2018 - CF 18.8
  IF p_spl_payload_num IS NOT NULL and p_spl_payload_num = 'UCM' THEN
  v_payload.ATTRIBUTE1 := v_payload.ORDER_NUMBER||'_CROSS_PLAN_RENEWAL_'||v_old_spm_plan_spl;
  ELSE
  v_payload.ATTRIBUTE1 := v_payload.ORDER_TYPE||'_'||v_payload.ORDER_NUMBER||'_'||substr(v_payload.CONTRACT_TYPE,7,1);
  END IF;

  --
  v_payload.ATTRIBUTE2 := v_old_spm_plan_spl; --Bug#28317355 Fix to get old plan number
  --


  --27815012 SRECHAND CHANGES BEGIN
  BEGIN
    SELECT lookup_value
    INTO l_lines_formed
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE component ='LINE_FORM_CHECK'
    AND application = 'MISIMD_SPM_CLOUD_WF'
    AND LOOKUP_CODE ='LINE_FORM_CHECK'
    AND enabled     = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    l_lines_formed := 'N';
  END;
  --27815012 SRECHAND CHANGES END
  --27691142 SRECHAND CHANGES BEGIN
  IF (v_payload_lines = 0 AND l_lines_formed = 'Y' ) THEN
   insert_log (p_module =>'PREPARE_NOTIFY_PAYLOAD(*)',
    p_audit_message => 'Error Raising Business Event. Check misimd_intf_error',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
   insert_error (p_error_code => 'BACKTRACE:',
    p_error_message => 'For the specific header_id and sub_id no lines returned',
    p_module => 'PREPARE_NOTIFY_PAYLOAD',
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id,
    p_context_name3 => 'For the specific header_id and sub_id no lines returned',
    p_context_id3=> 0);
    raise_application_error(-20104, 'NO LINES FORMED');
  END IF;
   --27691142 SRECHAND CHANGES END

  insert_log(p_module =>'GET_BUS_EVENT_XML',
    p_audit_message => '<ENTITLEMENT_COMPONENTS> fetch Successful',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);


  SELECT sys_xmlgen (v_payload, xmlformat.createformat (
    'MISIMD_SPM_SUBSCRIPTION'))
  INTO v_xml_payload
  FROM dual;

  insert_log (p_module =>'GET_BUS_EVENT_XML(-)',
    p_audit_message => 'Exit Function GET_BUS_EVENT_XML',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);

  RETURN v_xml_payload;

EXCEPTION
WHEN OTHERS THEN
  insert_log (p_module =>'GET_BUS_EVENT_XML(*)',
    p_audit_message => 'Error Generating XML. Check misimd_intf_error',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  insert_error (p_error_code => 'BACKTRACE:',
    p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => '',
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id,
    p_context_name3 => SUBSTR ('Error_Stack:'
      || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
    p_context_id3 => SQLCODE);
    raise;
END get_bus_event_xml;
--
PROCEDURE prepare_inflight_payload(
    p_header_id       IN NUMBER ,
    p_subscription_id IN NUMBER  DEFAULT NULL,
    resultout OUT nocopy VARCHAR2)
IS
l_paramlist_t wf_parameter_list_t := NULL;
l_order_data CLOB;
v_order_number VARCHAR2(50);
v_payload OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION :=
  OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION.NEW_INSTANCE();
v_xml_payload xmltype;
v_enabled VARCHAR2(10) := 'DISABLED';
BEGIN
  -- Check if Inflight Interface is Enabled
  BEGIN
    SELECT lookup_value
    INTO v_enabled
    FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
    WHERE component = 'INFLIGHT'
  AND application = 'MISIMD_SPM_CLOUD_WF'
    AND lookup_code   = 'INFLIGHT_INTERFACE';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_enabled := 'DISABLED';
  WHEN OTHERS THEN
    v_enabled := 'DISABLED';
  END;
  --
  IF v_enabled = 'ENABLED' THEN
    v_payload.INFLIGHT_ORDER           := 'Y';
    v_payload.ORDER_HEADER_ID          := p_header_id;
    v_payload.INFLIGHT_SUBSCRIPTION_ID := p_subscription_id;
    --
    SELECT salesOrderNum,
      ServiceStartDate,
      LineStatus
    INTO v_payload.ORDER_NUMBER,
      v_payload.INFLIGHT_SERVICE_START_DATE,
      v_payload.INFLIGHT_STATUS
    FROM
      (SELECT DISTINCT ooha.order_number salesOrderNum,
        MIN(oola.service_start_date) ServiceStartDate,
        oola.flow_status_code LineStatus
      FROM oe_order_price_attribs oopa ,
        oe_order_headers_all ooha,
        oe_order_lines_all oola
      WHERE ooha.header_id         = oola.header_id
      AND ooha.header_id           = oopa.header_id
      AND oopa.line_id             = oola.line_id
      AND oola.item_type_code      = 'SERVICE'
      AND oola.flow_status_code   <> 'CANCELLED'
      AND NVL(oopa.pricing_attribute92,'1') = NVL(p_subscription_id,'1')
      AND ooha.header_id           = p_header_id
      GROUP BY ooha.order_number,
        oola.flow_status_code
      )
    WHERE rownum=1;
    --
    insert_log (p_module =>'PREPARE_INFLIGHT_PAYLOAD(+)',
      p_audit_message => 'Raise event misimd.om.notify.spm',
      p_audit_level => 1,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);
    --
    SELECT sys_xmlgen (v_payload, xmlformat.createformat (
      'MISIMD_SPM_SUBSCRIPTION'))
    INTO v_xml_payload
    FROM dual;
    l_order_data := v_xml_payload.getClobVal();
    --
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    --
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    --
    insert_log (p_module =>'PREPARE_INFLIGHT_PAYLOAD(-)',
      p_audit_message => 'Event Raised Successfully',
      p_audit_level => 1,
      p_context_name1 => 'order_number',
      p_context_id1 => v_order_number,
      p_context_name2 => 'subscription_id',
      p_context_id2 => p_subscription_id);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  insert_log (p_module =>'PREPARE_INFLIGHT_PAYLOAD(*)',
    p_audit_message => 'Error Raising Business Event. Check misimd_intf_error',
    p_audit_level => 1,
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id);
  insert_error (p_error_code => 'BACKTRACE:',
    p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => 'PREPARE_INFLIGHT_PAYLOAD',
    p_context_name1 => 'order_number',
    p_context_id1 => v_order_number,
    p_context_name2 => 'subscription_id',
    p_context_id2 => p_subscription_id,
    p_context_name3 => SUBSTR ('Error_Stack:'
      || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
    p_context_id3 => SQLCODE);
  raise;
END prepare_inflight_payload;
--
FUNCTION get_subscription_type (
    p_header_id IN NUMBER)
  RETURN VARCHAR2
AS
  l_subscription_type VARCHAR2 (100) := 'Cloud Renewable Subscriptions';
  l_count NUMBER := 0;
  l_count_M NUMBER := 0;
  l_count_U NUMBER := 0;
BEGIN
  -- Total Count
  SELECT count(line_id)
  INTO l_count
  FROM oe_order_lines_all ol
  WHERE item_type_code = 'SERVICE'
  AND header_id        = p_header_id
  AND flow_status_code <> 'CANCELLED'
  AND is_spm_eligible(ol.line_id) ='Y'
  AND EXISTS
    (SELECT 1
    FROM mtl_system_items_b
    WHERE organization_id         = 14354
    AND segment1                  = ol.ordered_item
    AND SERVICEABLE_PRODUCT_FLAG <> 'Y'
    );
  -- Metered Lines Count
  SELECT count(line_id)
  INTO l_count_M
  FROM oe_order_lines_all ol
  WHERE item_type_code = 'SERVICE'
  AND header_id        = p_header_id
  AND flow_status_code <> 'CANCELLED'
  AND is_spm_eligible(ol.line_id) ='Y'
  AND EXISTS
    (SELECT 1
    FROM mtl_system_items_b
    WHERE organization_id         = 14354
    AND segment1                  = ol.ordered_item
    AND SERVICEABLE_PRODUCT_FLAG <> 'Y'
    )
  AND is_metered_subscription(line_id) = 'Y';
  --Universal Lines Count
  SELECT count(line_id)
  INTO l_count_U
  FROM oe_order_lines_all ol
  WHERE item_type_code = 'SERVICE'
  AND header_id        = p_header_id
  AND flow_status_code <> 'CANCELLED'
  AND is_spm_eligible(ol.line_id) ='Y'
  AND EXISTS
    (SELECT 1
    FROM mtl_system_items_b
    WHERE organization_id         = 14354
    AND segment1                  = ol.ordered_item
    AND SERVICEABLE_PRODUCT_FLAG <> 'Y'
    )
  AND is_universal_subscription(line_id) = 'Y';
  --
  IF l_count = l_count_M THEN
  l_subscription_type := 'Cloud Evergreen Subscriptions';
  ELSIF l_count = l_count_U THEN
  l_subscription_type := 'Cloud Universal Subscriptions';
  ELSE
  l_subscription_type := 'Cloud Renewable Subscriptions';
  END IF;
  RETURN l_subscription_type;
EXCEPTION
WHEN OTHERS THEN
  l_subscription_type := 'Cloud Renewable Subscriptions';
  RETURN l_subscription_type;
END get_subscription_type;
--
FUNCTION is_metered_subscription (
    p_line_id IN NUMBER)
  RETURN VARCHAR2
AS
  l_is_metered_billing VARCHAR2 (100) := 'N';
BEGIN
  BEGIN
/*    SELECT 'Y'
    INTO l_is_metered_billing
    FROM mtl_categories mc,
      mtl_item_categories mic,
      MTL_CATEGORY_SETS MCS
    WHERE mic.inventory_item_id IN
      (SELECT inventory_item_id
      FROM oe_order_lines_all
      WHERE (line_id IN
        (SELECT line_id
        FROM oe_order_price_attribs
        WHERE pricing_attribute92 =
          (SELECT pricing_attribute92
          FROM oe_order_price_attribs
          WHERE line_id = p_line_id
          )
        )
        OR line_id =  p_line_id)
      )
    AND mcs.category_set_id = mic.category_set_id
    AND mc.category_id      = mic.category_id
    AND MIC.ORGANIZATION_ID = 14354
    AND LOWER (CATEGORY_SET_NAME) LIKE 'usage%billing%'
    AND MC.SEGMENT1 = 'METERED_BILLING'
    AND rownum      = 1; */

--Bug 25341009 HIGH IO: dyzg9hzqtcpsx, 5w1cz6kx54c5v - APPS.MISIMD_SPM_CLOUD_WF - rdnagara
                              SELECT /*+ leading(z) */ 'Y'
               INTO l_is_metered_billing
               from
                 (select /*+ NO_MERGE leading(y) */ category_set_id, category_id
                 from mtl_item_categories mic,
                  (SELECT /*+ leading(x) use_nl(oel) */ distinct INVENTORY_ITEM_ID
                   FROM OE_ORDER_LINES_ALL oel,
                    (SELECT LINE_ID FROM OE_ORDER_PRICE_ATTRIBS
                      WHERE PRICING_ATTRIBUTE92 = (SELECT PRICING_ATTRIBUTE92
                      FROM OE_ORDER_PRICE_ATTRIBS
                       WHERE LINE_ID = p_line_id )
               UNION
                  select p_line_id from dual ) x
                  WHERE oel.LINE_ID = x.line_id) y
                  where mic.organization_id = 14354 and
                  mic.inventory_item_id = y.inventory_item_id ) z,
                  MTL_CATEGORIES MC,
                  MTL_CATEGORY_SETS MCS
                  WHERE
                   MCS.CATEGORY_SET_ID = z.CATEGORY_SET_ID AND
                   MC.CATEGORY_ID = z.CATEGORY_ID AND
      LOWER (mcs.CATEGORY_SET_NAME) LIKE 'usage%billing%' AND
                   MC.SEGMENT1 = 'METERED_BILLING' AND
                   ROWNUM = 1;
  EXCEPTION
  WHEN OTHERS THEN
    l_is_metered_billing := 'N';
  END;
  RETURN l_is_metered_billing;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END is_metered_subscription;
--
FUNCTION is_universal_subscription (
    p_line_id IN NUMBER)
  RETURN VARCHAR2
AS
  l_is_metered_subscription VARCHAR2 (100) := 'N';
BEGIN
  BEGIN
/*    SELECT 'Y'
    INTO l_is_metered_subscription
    FROM mtl_categories mc,
      mtl_item_categories mic,
      MTL_CATEGORY_SETS MCS
    WHERE mic.inventory_item_id IN
      (SELECT inventory_item_id
      FROM oe_order_lines_all
      WHERE line_id IN
        (SELECT line_id
        FROM oe_order_price_attribs
        WHERE pricing_attribute92 =
          (SELECT pricing_attribute92
          FROM oe_order_price_attribs
          WHERE line_id = p_line_id
          )
        )
      )
    AND mcs.category_set_id = mic.category_set_id
    AND mc.category_id      = mic.category_id
    AND MIC.ORGANIZATION_ID = 14354
    AND MC.SEGMENT1 = 'METERED_SUBSCRIPTION'
    AND rownum      = 1;  */

-- Bug    25341009 HIGH IO: dyzg9hzqtcpsx, 5w1cz6kx54c5v - APPS.MISIMD_SPM_CLOUD_WF - rdnagara
               SELECT 'Y' into l_is_metered_subscription
FROM (select distinct inventory_item_id from OE_ORDER_LINES_ALL
  WHERE LINE_ID IN (SELECT LINE_ID
FROM OE_ORDER_PRICE_ATTRIBS
WHERE PRICING_ATTRIBUTE92 = (SELECT PRICING_ATTRIBUTE92
FROM OE_ORDER_PRICE_ATTRIBS
WHERE LINE_ID = p_line_id ) ) ) x,
MTL_CATEGORIES MC,
MTL_ITEM_CATEGORIES MIC,
MTL_CATEGORY_SETS MCS
WHERE MIC.INVENTORY_ITEM_ID = x.inventory_item_id and
MCS.CATEGORY_SET_ID = MIC.CATEGORY_SET_ID AND
MC.CATEGORY_ID = MIC.CATEGORY_ID AND
MIC.ORGANIZATION_ID = 14354 AND
MC.SEGMENT1 = 'METERED_SUBSCRIPTION' AND
ROWNUM = 1;
  EXCEPTION
  WHEN OTHERS THEN
    l_is_metered_subscription := 'N';
  END;
  RETURN l_is_metered_subscription;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END is_universal_subscription;
--
FUNCTION is_spm_eligible(
    p_line_id IN NUMBER)
  RETURN VARCHAR2
AS
  v_is_spm_eligible VARCHAR2 (10) := 'N';
BEGIN
/*  BEGIN
    SELECT 'Y'
    INTO v_is_spm_eligible
    FROM mtl_item_categories_v mic,
      oe_order_lines_all ol
    WHERE mic.inventory_item_id = ol.inventory_item_id
    AND ol.line_id              = p_line_id
    AND organization_id         = 101
    AND mic.category_set_id     =
      (SELECT category_set_id
      FROM mtl_category_sets_v
      WHERE structure_name = 'APPLICATION_ENABLED'
      )
    AND EXISTS
      (SELECT 1
      FROM mtl_categories
      WHERE category_id = mic.category_id
      AND segment1      = 'SPM'
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_is_spm_eligible := 'N';
  END; */
  SELECT  misont_cloud_pub2.is_spm_eligible(p_line_id) INTO  v_is_spm_eligible FROM DUAL;-- BUG#26176194 fix removed  from 17.6-- removed for SPM_PROV Project
  RETURN v_is_spm_eligible;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END is_spm_eligible;

PROCEDURE init
IS
  v_delay       NUMBER;
  v_trace_level NUMBER;
BEGIN
  --
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS= ''.,'' ';
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_LANGUAGE = ''AMERICAN'' ';
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE = ''AMERICAN'' ';
  END;
  --
  IF G_TRACE_ENABLED = 'Y' THEN
    RETURN;
  ENd IF;

  SELECT NVL (to_number (MAX (lookup_value)), 12)
  INTO v_trace_level
  FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
  WHERE application       = 'GSI-SPM CLOUD BRIDGE'
  AND component           = 'MISIMD_SPM_CLOUD_WF'
  AND upper (lookup_code) = 'TRACE_LEVEL'
  AND enabled             = 'Y';

  --Fetch global log_level to determine granularity of Logging
  SELECT NVL (to_number (MAX (lookup_value)), 3)
  INTO g_log_level
  FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
  WHERE application       = 'GSI-SPM CLOUD BRIDGE'
  AND component           = 'MISIMD_SPM_CLOUD_WF'
  AND upper (lookup_code) = 'LOG_LEVEL'
  AND enabled             = 'Y';

  SELECT DECODE (fnd_global.conc_request_id, - 1, to_number (TO_CHAR (
    systimestamp, 'DDMMYYYYHH24MISSFF')), fnd_global.conc_request_id)
  INTO g_trxn_reference
  FROM dual;

  SELECT NVL ( (MAX (lookup_value)), 'N')
  INTO G_TRACE_ENABLED
  FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
  WHERE application       = 'GSI-SPM CLOUD BRIDGE'
  AND component           = 'MISIMD_SPM_CLOUD_WF'
  AND upper (lookup_code) = 'TRACE_ENABLED'
  AND enabled             = 'Y';

  SELECT NVL (to_number (MAX (lookup_value)), 0)
  INTO v_delay
  FROM OSS_INTF_USER.MISIMD_INTF_LOOKUP
  WHERE application       = 'GSI-SPM CLOUD BRIDGE'
  AND component           = 'MISIMD_SPM_CLOUD_WF'
  AND upper (lookup_code) = 'TIME_DELAY'
  AND enabled             = 'Y';
  --sleep for g_delay seconds
  --  DBMS_LOCK.SLEEP(v_delay);
  IF G_TRACE_ENABLED = 'Y' THEN
    MISIMD_AUDIT.enable_trace (v_trace_level, g_tracefile_identifier);
  END IF;
  insert_log (p_module =>'INIT', p_audit_message =>
  'Initialize Logging FWK ...', p_audit_level => 1, p_context_name1 =>
  'Requestor', p_context_id1 => fnd_global.user_id);
EXCEPTION
WHEN OTHERS THEN
  NULL;
END init;

PROCEDURE insert_log (
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
    p_application => 'GSI-SPM CLOUD BRIDGE', p_component=>
    'MISIMD_SPM_CLOUD_WF', p_module => p_module, p_timestamp => systimestamp,
    p_context_name1 => p_context_name1, p_context_id1 => p_context_id1,
    p_context_name2 => p_context_name2, p_context_id2 => p_context_id2,
    p_context_name3 => p_context_name3, p_context_id3 => p_context_id3,
    p_platform => 'Oracle Database', p_audit_attachment => p_audit_attachment,
    errbuf => x_dummy);
  END IF;
END insert_log;

PROCEDURE insert_error (
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

  MISIMD_AUDIT.intf_error (p_transaction_reference =>g_trxn_reference,
  p_error_code => p_error_code, p_error_message => p_error_message,
  p_application => 'GSI-SPM CLOUD BRIDGE', p_component =>
  'MISIMD_SPM_CLOUD_WF', p_module => p_module, p_timestamp => systimestamp,
  p_context_name1 => p_context_name1, p_context_id1 => p_context_id1,
  p_context_name2 => p_context_name2, p_context_id2 => p_context_id2,
  p_context_name3 => p_context_name3, p_context_id3 => p_context_id3,
  p_platform => 'Oracle Database', p_log_details =>'Tracefile Identifier:' ||
  g_tracefile_identifier, errbuf => x_dummy);
END insert_error;

PROCEDURE Set_SPM_info ( p_line_id in number ,
                         p_OPC_CUSTOMER_NAME                   in varchar2 default null ,
                         p_SPM_PLAN_NUMBER                     in varchar2 default null ,
                         p_SPM_PLAN_STATUS                     in varchar2 default null ,
                         p_SPM_INTERFACE_STATUS                in varchar2 default null ,
                         p_SPM_INTERFACE_ERROR                 in varchar2 default null ,
                         p_SPM_CREATION_DATE                   in DATE     default null ,
                         p_SPM_INTERFACE_UPDATE_DATE           in DATE     default null ,
                         p_INVOICE_NUMBER                      in varchar2 default null )
IS
  l_line_number number;
  l_header_id number ;
  l_result    VARCHAR2(1000);
  l_count NUMBER;
  l_responsibility_id NUMBER;
  l_application_id    NUMBER;
  l_user_id           NUMBER;
  l_request_id        NUMBER;
CURSOR c1(p_header_id NUMBER)
IS
  SELECT DISTINCT header_id, subscription_id
  FROM MISONT_ORDER_LINE_ATTRIBS_EXT a
  WHERE SPM_INTERFACE_STATUS = 'WAITING FOR MASTER SUBS INTF'
  AND subscription_id IS NOT NULL
  AND header_id = p_header_id
  ORDER BY subscription_id;
BEGIN
    begin
        select  line_number , header_id
        into    l_line_number , l_header_id
        from    oe_order_lines_all
        where   line_id = p_line_id  ;
-- rdnagara

   insert_log (p_module =>'Set_SPM_info',
      p_audit_message => 'Updating MISONT table',
      p_audit_level => 1,
      p_context_name1 => 'Line_number',
      p_context_id1 => p_line_id);
        update misont_order_line_attribs_ext
        set    SPM_PLAN_NUMBER           = nvl ( p_SPM_PLAN_NUMBER           , SPM_PLAN_NUMBER      ) ,
               OPC_CUSTOMER_NAME         = nvl ( p_OPC_CUSTOMER_NAME         , OPC_CUSTOMER_NAME    ) ,
               SPM_PLAN_STATUS           = nvl ( p_SPM_PLAN_STATUS           , SPM_PLAN_STATUS      ) ,
               SPM_INTERFACE_STATUS      = nvl ( p_SPM_INTERFACE_STATUS      , SPM_INTERFACE_STATUS ) ,
               SPM_INTERFACE_ERROR       = nvl ( p_SPM_INTERFACE_ERROR       , SPM_INTERFACE_ERROR ) ,
               SPM_CREATION_DATE         = nvl ( p_SPM_CREATION_DATE         , SPM_CREATION_DATE    ) ,
               SPM_INTERFACE_UPDATE_DATE = nvl ( p_SPM_INTERFACE_UPDATE_DATE , SPM_INTERFACE_UPDATE_DATE    ) ,
               INVOICE_NUMBER            = nvl ( p_INVOICE_NUMBER            , INVOICE_NUMBER       ),
               LAST_UPDATE_DATE          = DECODE(p_SPM_INTERFACE_ERROR, 'Awaiting SPM Response', SYSDATE, LAST_UPDATE_DATE)
        where  header_id = l_header_id
        --and    NVL(SPM_INTERFACE_STATUS,'X') <> 'SPM_INTERFACED'
        and    line_id in (select line_id from oe_order_lines_all where header_id = l_header_id and line_number = l_line_number);
            --rdnagara
    IF p_SPM_INTERFACE_STATUS = 'SPM_INTERFACED' THEN
    BEGIN
      FOR i IN c1(l_header_id)
      LOOP
        MISIMD_SPM_CLOUD_WF.prepare_notify_payload (i.header_id,i.subscription_id,l_result ) ;
      END LOOP;
    END;
    END IF;
    IF p_SPM_INTERFACE_STATUS = 'SPM_INTERFACE_FAILED' THEN
      BEGIN
        INSERT INTO ONT_ERROR_MESSAGES  (ORDER_ID,SOURCE,BRIEF_MESSAGE,FULL_MESSAGE,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY)
        VALUES (l_header_id,'SPM',p_line_id,p_SPM_INTERFACE_ERROR,SYSDATE,'4110846',SYSDATE,'4110846');
      END;
    END IF;
    --SPM-9458 -- Enhance OM to SPM Process to Move Specific Renewals to Universal Plan
    SELECT count(1)
    INTO l_count
    FROM misont_order_line_attribs_ext
    WHERE SPM_INTERFACE_ERROR = 'Awaiting SPM Response'
    AND header_id = l_header_id;
    --
    IF p_SPM_INTERFACE_STATUS = 'SPM_INTERFACE_FAILED' and (p_SPM_INTERFACE_ERROR like '%SPM-0001:UCM_CONVERSION_FAILED%' OR p_SPM_INTERFACE_ERROR like '%SPM-0002:PLAN_TYPE_MISMATCHED%')
    AND l_count = 0 THEN
    --
    BEGIN
      --
      SELECT DISTINCT frtl.responsibility_id,
        fresp.application_id
      INTO l_responsibility_id,
        l_application_id
      FROM fnd_responsibility fresp,
        fnd_responsibility_tl frtl
      WHERE frtl.responsibility_id = fresp.responsibility_id
      AND frtl.responsibility_name LIKE 'ADIT_INTEGRATION';
      --
      SELECT user_id INTO l_user_id FROM fnd_user WHERE user_name = 'MISIMD-FUSION-BRIDGE_WW@ORACLE.COM';
      --
      fnd_global.apps_initialize (l_user_id,l_responsibility_id,l_application_id);
      --

      l_request_id := fnd_request.submit_request ( application => 'MISIMD', program => 'MISIMDSPMPROVRETRY',
                                                   description => 'Special Case Execution',
                                                   start_time => sysdate, sub_request => FALSE,
                                                   argument1 => 'SPECIAL',
                                                   argument2 => l_header_id);
      --
      --COMMIT;
      --
      IF l_request_id = 0 THEN
        insert_log (p_module =>'Set_SPM_info',
          p_audit_message => 'Special Case - Concurrent request failed to submit',
          p_audit_level => 1,
          p_context_name1 => 'Header_Id',
          p_context_id1 => l_header_id);
      ELSE
        insert_log (p_module =>'Set_SPM_info',
          p_audit_message => 'Special Case - Successfully Submitted the Concurrent Request',
          p_audit_level => 1,
          p_context_name1 => 'Header_Id',
          p_context_id1 => l_header_id);
      END IF;
      --
    EXCEPTION
    WHEN OTHERS THEN
      insert_log (p_module =>'Set_SPM_info',
        p_audit_message => 'Error While Submitting Concurrent Request '||TO_CHAR(SQLCODE)||'-'||sqlerrm,
        p_audit_level => 1,
        p_context_name1 => 'Header_Id',
        p_context_id1 => l_header_id);
    END;
    --
    END IF;
    --
    insert_log (p_module =>'Set_SPM_info',
      p_audit_message => 'Successfully updated MISONT table',
      p_audit_level => 1,
      p_context_name1 => 'Line_number',
      p_context_id1 => p_line_id);

    exception when others then
        --rdnagara
    insert_error (p_error_code => 'BACKTRACE:',
    p_error_message => SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023),
    p_module => 'Set_SPM_info',
    p_context_name1 => 'Line_number',
    p_context_id1 => p_line_id,
    p_context_name3 => SUBSTR ('Error_Stack:'
      || DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127),
    p_context_id3 => SQLCODE);
    end ;
END ;
--
FUNCTION GET_SERVICE_PART(
    P_LICENSE_ITEM IN VARCHAR2)
  RETURN VARCHAR2
IS
  v_srv_part VARCHAR2(300);
BEGIN
  SELECT msi.segment1 service_part
  INTO v_srv_part
  FROM qp_list_headers_all qlha,
    qp_list_lines qll ,
    qp_pricing_attributes qpa,
    mtl_system_items_b msi
  WHERE (qlha.name='CURRENT COMMERCIAL'
  OR qlha.name LIKE 'SUBSCRIPTION%')
  AND qlha.list_header_id                = qll.list_header_id
  AND qlha.list_header_id                = qpa.list_header_id
  AND qll.list_line_id                   = qpa.list_line_id
  AND qpa.pricing_attribute             IS NOT NULL
  AND qpa.pricing_attribute_context      ='PRICING ATTRIBUTE'
  AND NVL(QLL.END_DATE_ACTIVE, sysdate) >= sysdate
  AND qpa.pricing_attr_value_from        = P_LICENSE_ITEM
  AND msi.inventory_item_id              = to_number(qpa.product_attr_value)
  AND msi.organization_id                =14354
  AND ROWNUM                             = 1;
  RETURN v_srv_part;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END get_service_part;
--
FUNCTION GET_SERVICE_PART_DESC(
    P_LICENSE_ITEM IN VARCHAR2)
  RETURN VARCHAR2
IS
  v_srv_part_desc VARCHAR2(1000);
BEGIN
  SELECT msi.description service_part_desc
  INTO v_srv_part_desc
  FROM qp_list_headers_all qlha,
    qp_list_lines qll ,
    qp_pricing_attributes qpa,
    mtl_system_items_b msi
  WHERE (qlha.name='CURRENT COMMERCIAL'
  OR qlha.name LIKE 'SUBSCRIPTION%')
  AND qlha.list_header_id                = qll.list_header_id
  AND qlha.list_header_id                = qpa.list_header_id
  AND qll.list_line_id                   = qpa.list_line_id
  AND qpa.pricing_attribute             IS NOT NULL
  AND qpa.pricing_attribute_context      ='PRICING ATTRIBUTE'
  AND NVL(QLL.END_DATE_ACTIVE, sysdate) >= sysdate
  AND qpa.pricing_attr_value_from        = P_LICENSE_ITEM
  AND msi.inventory_item_id              = to_number(qpa.product_attr_value)
  AND msi.organization_id                =14354
  AND ROWNUM                             = 1;
  RETURN v_srv_part_desc;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END get_service_part_desc;
--
PROCEDURE RETRY_SPM_PROV_ORDER(
    p_errbuf OUT NOCOPY  VARCHAR2,
    p_retcode OUT NOCOPY VARCHAR2,
    p_retry_type IN VARCHAR2 DEFAULT 'SINGLE',
    p_header_id IN NUMBER DEFAULT NULL)
IS
  v_resultout VARCHAR2(1000);
  v_flag      VARCHAR2(2)           := 'N';
  l_paramlist_t wf_parameter_list_t := NULL;
  l_order_data CLOB;
  v_spl_subs_plan_type VARCHAR2(100);
  v_ucm_count NUMBER;
  v_other_onb_count NUMBER;
  v_other_non_onb_count NUMBER;
BEGIN
IF p_retry_type = 'SINGLE' and p_header_id IS NOT NULL THEN
  --Check for valid header_id
  BEGIN
   SELECT 'Y'
    INTO v_flag
    FROM DUAL
    WHERE EXISTS (SELECT COUNT(*) FROM oe_order_lines_all    WHERE header_id = p_header_id);
  EXCEPTION WHEN OTHERS THEN
  v_flag := 'N';
  END;
  IF v_flag = 'Y' THEN
  --SPM Provisioning flow for NULL Subscription Id
  insert_log (p_module =>'PREPARE_NOTIFY_PAYLOAD(+)',
      p_audit_message => 'Raise event misimd.om.notify.spm',
      p_audit_level => 1,
      p_context_name1 => 'Order Header ID',
      p_context_id1 => p_header_id);
  --
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL).getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Retry Type: SINGLE, Header Id: '||p_header_id||' successfully sent to SPM');
    COMMIT;
  ELSE
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Retry Type: SINGLE, Header Id: '||p_header_id||' is INVALID');
  END IF;
END IF;
IF p_retry_type = 'BULK' THEN
  FOR i IN
  (SELECT DISTINCT header_id
  FROM MISONT_ORDER_LINE_ATTRIBS_EXT
  WHERE SPM_INTERFACE_ERROR LIKE '%SPM_PROV_FLOW:AUTOMATED_FLOW is not Enabled%'
  )
  LOOP
    misimd_spm_cloud_wf.prepare_notify_payload ( p_header_id => i.header_id , p_subscription_id => NULL, resultout => v_resultout);
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Retry Type: BULK, Header Id: '||i.header_id||' successfully sent to SPM');
  END LOOP;
--
END IF;
IF p_retry_type = 'SPECIAL' THEN
--
    UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT olae
    SET spm_interface_error =
      (SELECT DECODE(olae.ADDITIONAL_COLUMN42,NULL,'OTHER:'
        ||oopa.pricing_attribute94,'UCM:'
        ||oopa.pricing_attribute94)
      FROM oe_order_price_attribs oopa
      WHERE oopa.line_id = olae.line_id
      AND oopa.header_id = olae.header_id
      )||'--'||spm_interface_error
    WHERE header_id = p_header_id
    AND  SPM_INTERFACE_ERROR <>  'Awaiting SPM Response' ;
    --Expected Plan Type
    SELECT SUBSTR(spm_interface_error,(instr(spm_interface_error,'Plan Subscription Type='))+23,
          (instr(spm_interface_error,'Subscriptions',-1))-instr(spm_interface_error,'Plan Subscription Type=')-10)
    INTO v_spl_subs_plan_type
    FROM MISONT_ORDER_LINE_ATTRIBS_EXT
    WHERE 1=1
    AND header_id = p_header_id
    and rownum = 1;
    --
    IF v_spl_subs_plan_type = 'Cloud Universal Subscriptions' THEN
    --Send all lines as Universal
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL,NULL,'Cloud Universal Subscriptions').getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    ELSE
    SELECT count(1)
    INTO v_ucm_count
    FROM MISONT_ORDER_LINE_ATTRIBS_EXT
    WHERE spm_interface_error like '%UCM:%'
    AND header_id = p_header_id;
    --
    SELECT count(1)
    INTO v_other_non_onb_count
    FROM MISONT_ORDER_LINE_ATTRIBS_EXT
    WHERE spm_interface_error like '%OTHER:%'
    AND spm_interface_error NOT like '%OTHER:ONBOARDING%'
    AND spm_interface_error NOT like '%OTHER:UPDATE%'
    AND header_id = p_header_id;
    --
    SELECT count(1)
    INTO v_other_onb_count
    FROM MISONT_ORDER_LINE_ATTRIBS_EXT
    WHERE (spm_interface_error like '%OTHER:ONBOARDING%'
    OR spm_interface_error like '%OTHER:UPDATE%'
    OR spm_interface_error like '%OTHER:REPLENISH%') --28637153
    AND header_id = p_header_id;
    --
    --CASE 1: Orders with UCM Onboarding + SaaS Renewal
    IF v_ucm_count > 0 AND v_other_non_onb_count > 0 AND v_other_onb_count = 0 THEN
    --
    UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
    SET spm_plan_status = 'UCM'
    WHERE header_id = p_header_id;
    --Send all lines as Universal
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL,'UCM','Cloud Universal Subscriptions').getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    END IF;
    --CASE 2: Order with UCM Onboarding + SaaS Co term OB + SaaS Renewal + CASE 3: Order with UCM Onboarding + SaaS Update
    IF v_ucm_count > 0 AND v_other_onb_count > 0 THEN
    --
    UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
    SET spm_plan_status = 'UCM'
    WHERE spm_interface_error like '%UCM:%'
    AND header_id = p_header_id;
    --Send UCM lines as Universal
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL,'UCM','Cloud Universal Subscriptions').getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    --
    UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
    SET spm_plan_status = 'OTHER'
    WHERE spm_interface_error like '%OTHER:%'
    AND header_id = p_header_id;
    --Send UCM lines as Universal
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL,'OTHER',v_spl_subs_plan_type).getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    END IF;
    --CASE 4: Orders with UCM RENEW_TO_COMMIT
    IF v_ucm_count > 0 AND v_other_non_onb_count = 0 AND v_other_onb_count = 0 THEN
    --
    UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
    SET spm_plan_status = 'UCM'
    WHERE header_id = p_header_id;
    --Send all lines as Universal
    l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL,'UCM','Cloud Universal Subscriptions').getClobVal();
    l_order_data := SUBSTR (l_order_data, 1,
      instr (l_order_data, '>', 1, 2) - 1)
      || ' xmlns="http://www.oracle.com/spm">'
      || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
    wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
      p_event_key => systimestamp,
      p_event_data => l_order_data,
      p_parameters => l_paramlist_t,
      p_send_date => sysdate);
    END IF;
    --CASE 5: OCC Renewal with no UCM v_other_onb_count >0
    IF  v_other_onb_count > 0 THEN
        UPDATE MISONT_ORDER_LINE_ATTRIBS_EXT
        SET spm_plan_status = 'OTHER'
        WHERE spm_interface_error like '%OTHER:%'
        AND header_id = p_header_id;

        l_order_data := misimd_SPM_cloud_wf.get_bus_event_xml(p_header_id,NULL,NULL,'OTHER',v_spl_subs_plan_type).getClobVal();
        l_order_data := SUBSTR (l_order_data, 1,
          instr (l_order_data, '>', 1, 2) - 1)
          || ' xmlns="http://www.oracle.com/spm">'
          || SUBSTR (l_order_data, instr (l_order_data, '>', 1, 2) + 1);
        wf_event.RAISE (p_event_name => 'misimd.om.notify.spm',
          p_event_key => systimestamp,
          p_event_data => l_order_data,
          p_parameters => l_paramlist_t,
          p_send_date => sysdate);
        END IF;
    --
    END IF;
--
END IF;
--
IF p_retry_type NOT IN ('SINGLE','BULK','SPECIAL') THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'Retry Type: '||p_retry_type||' is not correct. Kindly use SINGLE with valid header_id or BULK');
END IF;
--
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,SUBSTR ('Error_Stack:'|| DBMS_UTILITY.FORMAT_ERROR_STACK, 0, 127));
  FND_FILE.PUT_LINE(FND_FILE.LOG,SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 0, 1023));
END RETRY_SPM_PROV_ORDER;
--
END MISIMD_SPM_CLOUD_WF;
/

commit;
exit;
