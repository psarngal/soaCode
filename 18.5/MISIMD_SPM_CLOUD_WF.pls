rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls \
rem dbdrv: checkfile:~PROD:~PATH:~FILE

set verify off

whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback
DECLARE
  v_count NUMBER;
  v_sql   VARCHAR2(2000);
BEGIN
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_SUBSCRIPTION'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_LINES_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_LINES_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_LINES'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_LINES FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_CUSTOMER_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_CUSTOMER'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_CUSTOMER FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_BOM_COMPONENT_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_BOM_COMPONENT'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_OPTIONAL_TIERS_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_OPTIONAL_TIERS'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_SALES_CREDIT_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_SALES_CREDIT'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_ENT_COMPONENT_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_ENT_COMPONENT'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_RATE_CARD_TBL'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_RATE_CARD_TBL FORCE';
    EXECUTE immediate v_sql;
  END IF;
  SELECT COUNT(object_name)
  INTO v_count
  FROM sys.dba_objects
  WHERE object_name = 'MISIMD_SPM_RATE_CARD'
  AND object_type   = 'TYPE';
  IF v_count       <> 0 THEN
    v_sql          := 'DROP TYPE OSS_INTF_USER.MISIMD_SPM_RATE_CARD FORCE';
    EXECUTE immediate v_sql;
  END IF;
END;
/

CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_RATE_CARD
AS
  OBJECT
  (
    FROM_BAND_QUANTITY        VARCHAR2(1000) ,
    TO_BAND_QUANTITY          VARCHAR2(1000) ,
    UNIT_LIST_PRICE           VARCHAR2(1000) ,
    UNIT_SELLING_PRICE        VARCHAR2(1000) ,
    UNIT_SELLING_PRICE_UOM    VARCHAR2(1000) ,
    OVERAGE_PRICE             VARCHAR2(1000) ,
    OVERAGE_PRICE_UOM         VARCHAR2(1000) ,
    STANDARD_DISCOUNT_PERCENT VARCHAR2(1000) ,
    DISCR_DISCOUNT_PRCNT      VARCHAR2(1000) ,
    DISCOUNT_CATEGORY         VARCHAR2(1000) ,
    OVERAGE_DISCOUNT_PRCNT    VARCHAR2(1000) ,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_RATE_CARD );
/
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_RATE_CARD
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_RATE_CARD
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_RATE_CARD;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_RATE_CARD ( 
  FROM_BAND_QUANTITY        => NULL ,
  TO_BAND_QUANTITY          => NULL ,
  UNIT_LIST_PRICE           => NULL ,
  UNIT_SELLING_PRICE        => NULL ,
  UNIT_SELLING_PRICE_UOM    => NULL ,
  OVERAGE_PRICE             => NULL ,
  OVERAGE_PRICE_UOM         => NULL ,
  STANDARD_DISCOUNT_PERCENT => NULL ,
  DISCR_DISCOUNT_PRCNT      => NULL ,
  DISCOUNT_CATEGORY         => NULL ,
  OVERAGE_DISCOUNT_PRCNT    => NULL 
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_RATE_CARD_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_RATE_CARD;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT
AS
  OBJECT
  (
    INV_PART_NUMBER         VARCHAR2(1000) ,
    INV_PART_DESCRIPTION    VARCHAR2(1000) ,
    INVENTORY_ITEM_ID       VARCHAR2(1000) ,
    PRICE_BAND_ITEM_FLAG    VARCHAR2(1000) ,
    PRICING_UOM             VARCHAR2(1000) ,
    RATE_CARD_ID            VARCHAR2(1000) ,
    SPM_PRODUCT_ID          VARCHAR2(1000) ,
    SPM_LINE_ID       	    VARCHAR2(1000) ,
    PRICE_PERIOD            VARCHAR2(1000) ,
    RATE_CARD OSS_INTF_USER.MISIMD_SPM_RATE_CARD_TBL,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT );
/
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT ( 
  INV_PART_NUMBER          => NULL ,
  INV_PART_DESCRIPTION     => NULL ,
  INVENTORY_ITEM_ID        => NULL ,
  PRICE_BAND_ITEM_FLAG     => NULL ,
  PRICING_UOM              => NULL ,
  RATE_CARD_ID             => NULL ,
  SPM_PRODUCT_ID           => NULL ,
  SPM_LINE_ID              => NULL ,
  PRICE_PERIOD             => NULL ,
  RATE_CARD             => OSS_INTF_USER.MISIMD_SPM_RATE_CARD_TBL()
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS
AS
  OBJECT
  (
    INV_PART_NUMBER             VARCHAR2(1000) ,
    INV_PART_DESCRIPTION        VARCHAR2(1000) ,
    INVENTORY_ITEM_ID           VARCHAR2(1000) ,
    OPTIONAL_TIERS_RATE_CARD_ID VARCHAR2(1000) ,
    PRICED_PRICE_LIST_ID        VARCHAR2(1000) ,
    QUANTITY                    VARCHAR2(1000) ,
    UNIT_LIST_PRICE             VARCHAR2(1000) ,
    UNIT_SELLING_PRICE          VARCHAR2(1000) ,
    PRICING_UOM                 VARCHAR2(1000) ,
    STANDARD_DISCOUNT_PERCENT   VARCHAR2(1000) ,
    MANUAL_DISCOUNT_PERCENT     VARCHAR2(1000) ,
    TOTAL_DISCOUNT_PERCENT      VARCHAR2(1000) ,
    START_DATE                  VARCHAR2(1000) ,
    END_DATE                    VARCHAR2(1000) ,
    SUB_OVERAGE_POLICY_TYPE     VARCHAR2(1000) ,
    SUB_OVERAGE_PRICE           VARCHAR2(1000) ,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS );
  /
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS ( 
  INV_PART_NUMBER               => NULL ,
  INV_PART_DESCRIPTION          => NULL ,
  INVENTORY_ITEM_ID             => NULL ,
  OPTIONAL_TIERS_RATE_CARD_ID   => NULL ,
  PRICED_PRICE_LIST_ID          => NULL ,
  QUANTITY                      => NULL ,
  UNIT_LIST_PRICE               => NULL ,
  UNIT_SELLING_PRICE            => NULL ,
  PRICING_UOM                   => NULL ,
  STANDARD_DISCOUNT_PERCENT     => NULL ,
  MANUAL_DISCOUNT_PERCENT       => NULL ,
  TOTAL_DISCOUNT_PERCENT        => NULL ,
  START_DATE                    => NULL ,
  END_DATE                      => NULL ,
  SUB_OVERAGE_POLICY_TYPE       => NULL ,
  SUB_OVERAGE_PRICE             => NULL
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT
AS
  OBJECT
  (
    PARENT_INVENTORY_ITEM_ID VARCHAR2(1000) ,
    PARENT_PART_NUMBER       VARCHAR2(1000) ,
    PARENT_PART_DESCRIPTION  VARCHAR2(1000) ,
    CHILD_INVENTORY_ITEM_ID  VARCHAR2(1000) ,
    CHILD_PART_NUMBER        VARCHAR2(1000) ,
    CHILD_PART_DESCRIPTION   VARCHAR2(1000) ,
    LINE_NUMBER              VARCHAR2(1000) ,
    LICENSE_METRIC           VARCHAR2(1000) ,
    COMMITTED_QUANTITY       VARCHAR2(1000) ,
    QUANTITY_CONSTRAINT      VARCHAR2(1000) ,
    QUANTITY_MULTIPLIER      VARCHAR2(1000) ,
    FIRST_PURCHASE           VARCHAR2(1000) ,
    SERVICE_PART_ID          VARCHAR2(1000) ,
    SERVICE_PART_DESCRIPTION VARCHAR2(1000) , 
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT );
  /
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT ( 
  PARENT_INVENTORY_ITEM_ID    => NULL,
  PARENT_PART_NUMBER          => NULL,
  PARENT_PART_DESCRIPTION     => NULL,
  CHILD_INVENTORY_ITEM_ID     => NULL,
  CHILD_PART_NUMBER           => NULL,
  CHILD_PART_DESCRIPTION      => NULL,
  LINE_NUMBER                 => NULL,
  LICENSE_METRIC              => NULL,
  COMMITTED_QUANTITY          => NULL,
  QUANTITY_CONSTRAINT         => NULL,
  QUANTITY_MULTIPLIER         => NULL,
  FIRST_PURCHASE              => NULL,
  SERVICE_PART_ID             => NULL,
  SERVICE_PART_DESCRIPTION    => NULL  
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT
AS
  OBJECT
  (
    SALESREP_ID          VARCHAR2(1000) ,
    SALESREP_NUMBER      VARCHAR2(1000) ,
    SALESREP_NAME        VARCHAR2(1000) ,
    SALESREP_EMAIL       VARCHAR2(1000) ,
    PERCENT              VARCHAR2(1000) ,
    SALES_CREDIT_TYPE_ID VARCHAR2(1000) ,
    SPM_SALESREP_ID      VARCHAR2(1000) ,
    SPM_AD_USER_ID       VARCHAR2(1000) ,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT );
  /
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT ( 
  SALESREP_ID             => NULL,
  SALESREP_NUMBER         => NULL,
  SALESREP_NAME           => NULL,
  SALESREP_EMAIL          => NULL,
  PERCENT                 => NULL,
  SALES_CREDIT_TYPE_ID    => NULL,
  SPM_SALESREP_ID         => '0',
  SPM_AD_USER_ID          => '0'
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_CUSTOMER
AS
  OBJECT
  (
    PARTY_ID                  VARCHAR2(1000) ,
    PARENT_PARTY_ID           VARCHAR2(1000) ,
    PARTY_NUMBER              VARCHAR2(1000) ,
    PARTY_NAME                VARCHAR2(1000) ,
    PARTY_TYPE                VARCHAR2(1000) ,
    TAX_ID                    VARCHAR2(1000) ,
    TRANSLATED_NAME           VARCHAR2(1000) ,
    URL                       VARCHAR2(1000) ,
    TCA_CUST_ACCOUNT_ID       VARCHAR2(1000) ,
    CUST_ACCOUNT_NUMBER       VARCHAR2(1000) ,
    PARTY_SITE_ID             VARCHAR2(1000) ,
    PARTY_SITE_NUMBER         VARCHAR2(1000) ,
    CUST_ACCT_SITE_ID         VARCHAR2(1000) ,
    LOCATION_ID               VARCHAR2(1000) ,
    ADDRESS1                  VARCHAR2(1000) ,
    ADDRESS2                  VARCHAR2(1000) ,
    CITY                      VARCHAR2(1000) ,
    POSTAL_CODE               VARCHAR2(1000) ,
    STATE                     VARCHAR2(1000) ,
    COUNTRY                   VARCHAR2(1000) ,
    SITE_USE_TYPE             VARCHAR2(1000) ,
    SITE_USE_ID               VARCHAR2(1000) ,
    CONTACT_ID                VARCHAR2(1000) ,
    CONTACT_FIRST_NAME        VARCHAR2(1000) ,
    CONTACT_LAST_NAME         VARCHAR2(1000) ,
    CONTACT_EMAIL             VARCHAR2(1000) ,
    CONTACT_PHONE             VARCHAR2(1000) ,
    CONTACT_PARTY_ID          VARCHAR2(1000) ,
    CONTACT_CUST_ACCT_ROLE_ID VARCHAR2(1000) ,
    CONTACT_CUST_ACCT_SITE_ID VARCHAR2(1000) ,
    BILL_TO_SITE_USE_ID       VARCHAR2(1000) ,
    SHIP_TO_SITE_USE_ID       VARCHAR2(1000) ,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_CUSTOMER );
  /
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_CUSTOMER
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_CUSTOMER
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_CUSTOMER;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_CUSTOMER (
  PARTY_ID            => NULL ,
  PARENT_PARTY_ID     => NULL ,
  PARTY_NUMBER        => NULL ,
  PARTY_NAME          => NULL ,
  PARTY_TYPE          => NULL ,
  TAX_ID              => NULL ,
  TRANSLATED_NAME     => NULL ,
  URL                 => NULL ,
  TCA_CUST_ACCOUNT_ID => NULL ,
  CUST_ACCOUNT_NUMBER => NULL ,
  PARTY_SITE_ID       => NULL ,
  PARTY_SITE_NUMBER   => NULL ,
  CUST_ACCT_SITE_ID   => NULL ,
  LOCATION_ID         => NULL ,
  ADDRESS1            => NULL ,
  ADDRESS2            => NULL ,
  CITY                => NULL ,
  POSTAL_CODE         => NULL ,
  STATE               => NULL ,
  COUNTRY             => NULL ,
  SITE_USE_TYPE       => NULL ,
  SITE_USE_ID         => NULL ,
  CONTACT_ID          => NULL ,
  CONTACT_FIRST_NAME  => NULL ,
  CONTACT_LAST_NAME   => NULL ,
  CONTACT_EMAIL       => NULL ,
  CONTACT_PHONE       => NULL ,
  CONTACT_PARTY_ID    => NULL ,
  CONTACT_CUST_ACCT_ROLE_ID    => NULL ,
  CONTACT_CUST_ACCT_SITE_ID    => NULL ,
  BILL_TO_SITE_USE_ID          => NULL ,
  SHIP_TO_SITE_USE_ID          => NULL  
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_CUSTOMER;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_LINES
AS
  OBJECT
  (
    ORDER_LINE_ID                VARCHAR2(1000),
    ORDER_LINE_NUMBER            VARCHAR2(1000),
    METERED_SUBSCRIPTION         VARCHAR2(1000),
    CSI                          VARCHAR2(1000),
    GSI_SYSTEM_ID                VARCHAR2(1000),
    OVERAGE_ENABLED              VARCHAR2(1000),
    OVERAGE_THRESHOLD            VARCHAR2(1000),
    OVERAGE_BILLING_TERM         VARCHAR2(1000),
    OVERAGE_POLICY               VARCHAR2(1000),
    OVERAGE_PRICE                VARCHAR2(1000),
    SPLIT_ALLOWANCE              VARCHAR2(1000),
    ALLOWANCE_SPLIT_DURATION     VARCHAR2(1000),
    ALLOWANCE_SPLIT_DURATION_UOM VARCHAR2(1000),
    IS_SUBSCRIPTION_ENABLED      VARCHAR2(1000),
    SUBSCRIPTION_ID              VARCHAR2(1000),
    OPERATION_TYPE               VARCHAR2(1000),
    CLOUD_RENEWAL_FLAG           VARCHAR2(1000),
    CLOUD_RENEWAL_FLAG_MEANING   VARCHAR2(1000),
    INV_PART_NUMBER              VARCHAR2(1000),
    INVENTORY_ITEM_ID            VARCHAR2(1000),
    INV_PART_DESCRIPTION         VARCHAR2(1000),
    USER_ITEM_DESCRIPTION        VARCHAR2(1000),
    INV_CATEGORY                 VARCHAR2(1000),
    USAGE_BILLING                VARCHAR2(1000),
    ITEM_TYPE_CODE               VARCHAR2(1000),
    START_DATE                   VARCHAR2(1000),
    END_DATE                     VARCHAR2(1000),
    DURATION                     VARCHAR2(1000),
    DURATION_UNIT                VARCHAR2(1000),
    QUANTITY                     VARCHAR2(1000),
    COMMITTED_QUANTITY           VARCHAR2(1000),
    LINE_NET_AMOUNT              VARCHAR2(1000),
    TCLV                         VARCHAR2(1000),
    CLOUD_FUTURE_MON_PRICE       VARCHAR2(1000),
    CLOUD_DATA_CENTER_REGION     VARCHAR2(1000),
    CLOUD_DATA_CENTER_REGION_M   VARCHAR2(1000),
    CLOUD_ACC_ADMIN_EMAIL        VARCHAR2(1000),
    SERVICE_LINE_AMOUNT          VARCHAR2(1000),
    OPC_CUSTOMER_NAME            VARCHAR2(1000),
    SPMIST4C                     VARCHAR2(1000),
    PROVISIONING_STATUS          VARCHAR2(1000),
    PROVISIONING_DATE            VARCHAR2(1000),
    PO_EXPIRY_DATE               VARCHAR2(1000),
    CAP_TO_PRICELIST             VARCHAR2(1000),
    SPM_MASTER_LINE_ID           VARCHAR2(1000),
    SPM_PRODUCT_ID               VARCHAR2(1000),
    SPM_OLD_LINE_ID              VARCHAR2(1000),
    ENTITLEMENT_COUNTRYCODE      VARCHAR2(1000),
    ENTITLEMENT_PHONENUMBER      VARCHAR2(1000),
    BASE_ORDER_LINE_ID           VARCHAR2(1000),
    HAS_PROMOTION                VARCHAR2(1000),
    REBALANCE_OPTED              VARCHAR2(1000),
    FULFILLMENT_SET              VARCHAR2(1000),
    POOLED_ITEM                  VARCHAR2(1000),
    REPLACE_REASON_CODE          VARCHAR2(1000),
    SUPERSEDE_NOTES              VARCHAR2(1000),
    REPLACE_SUBSCRIPTION_ID      VARCHAR2(1000),
    SUPERSEDED_SET_ID            VARCHAR2(1000),
    PARENT_LINE_ID               VARCHAR2(1000),
    IS_UNIFIED                   VARCHAR2(1000),
    UNIFIED_REVENUE_QUOTA        VARCHAR2(1000),
    UNIFIED_REVENUE_AMOUNT       VARCHAR2(1000),
    PRICE_PERIOD                 VARCHAR2(1000),
    RENEWAL                      VARCHAR2(1000),
    UPSELL                       VARCHAR2(1000),
    CROSSSELL                    VARCHAR2(1000),
    DOWNSELL                     VARCHAR2(1000),
    CLOUD_ACCOUNT_ID             VARCHAR2(1000),
    CLOUD_ACCOUNT_NAME           VARCHAR2(1000),
    ASSOCIATE_SUB_ID             VARCHAR2(1000),
    CONTRACT_TYPE                VARCHAR2(1000),
    ORIGINAL_PROMO_AMT           VARCHAR2(1000),
    PROMOTION_ORDER              VARCHAR2(1000),
    PROMOTION_TYPE               VARCHAR2(1000),
	  PROMOTION_TYPE_VAL			     VARCHAR2(1000),--SPM-13797
    PARTNER_TRANSACTION_TYPE     VARCHAR2(1000),
    IS_CREDIT_ENABLED            VARCHAR2(1000),
    CREDIT_PERCENTAGE            VARCHAR2(1000),
    OVERAGE_BILL_TO              VARCHAR2(1000),
    RATE_CARD_DIS_PER            VARCHAR2(1000),
    PAYG_POLICY                  VARCHAR2(1000),
    INTENT_TO_PAY                VARCHAR2(1000), --SPM-6637
    DEPLOYMENT_TYPE		           VARCHAR2(1000), --SPM-7586
    DEPLOYMENT_NAME              VARCHAR2(1000), --SPM-7586
    COMMIT_MODEL                 VARCHAR2(1000), --SPM-7835
    OVERAGE_DISCOUNT_PRCNT       VARCHAR2(1000), --Bug#26133321,
    ASSC_REV_SUBSC_MAP           VARCHAR2(1000), --SPM-6780
    PROVISIONING_SOURCE          VARCHAR2(1000), --SPM-9560
    COMP_SALES_REP				       VARCHAR2(1000), --SPM-9566
    PARTNER_CREDIT_VALUE         VARCHAR2(1000), --SPM-10101
    COMMIT_SCHEDULE              VARCHAR2(1000), --SPM-10446
    --Changes for SPM-9570 - SPMPROV
    CLOUD_PROVISION_SEQ_NUM      VARCHAR2(1000),
    CLOUD_PO_TERM                VARCHAR2(1000),
    CLOUD_PO_TERM_UOM            VARCHAR2(1000),
    CLOUD_BACK_DATED_CONTRACT    VARCHAR2(1000),
    CLOUD_STORE_SSO_USERNAME     VARCHAR2(1000),
    CLOUD_REF_SUBSCRIPTION_ID    VARCHAR2(1000),
    CUSTOMERS_CRM_CHOICE         VARCHAR2(1000),
    ADMIN_FIRST_NAME             VARCHAR2(1000),
    ADMIN_LAST_NAME              VARCHAR2(1000),
    CUSTOMER_CODE                VARCHAR2(1000),
    LANGUAGE_PACK                VARCHAR2(1000),
    TALEO_CONSULTING_METHODOLOGY VARCHAR2(1000),
    AUTO_CLOSE_FOR_PROVISIONING  VARCHAR2(1000),
    CHANNEL_OPTION               VARCHAR2(1000),
    PARTNER_ID                   VARCHAR2(1000),
    RAVELLO_TOKEN_ID             VARCHAR2(1000),
   --Changes for SPM-9570 - SPMPROV
   --Changes for SPM-11135 begin- SPMPROV
    CLOUD_BACK_DATED_FLAG		     VARCHAR2(1000),
    PILOT_TYPE					         VARCHAR2(1000),
    FIXED_END_DATE_FLAG			     VARCHAR2(1000),
    NCER_ZONE					           VARCHAR2(1000),
    NCER_TYPE					           VARCHAR2(1000),
    --Changes for SPM-11135 end- SPMPROV
    SPECIAL_HANDLING_FLAG		     VARCHAR2(1000), --SPM-11120 
    LINE_OF_BUSINESS			       VARCHAR2(1000), --SPM-11396
    TEXTURA_TOKEN_ID			       VARCHAR2(1000), --SPM-11366
    APIARY_TOKEN_ID				       VARCHAR2(1000), --SPM-12114
    CUSTOMER_READINESS_DATE		   VARCHAR2(1000), --SPM-12007
    DEDICATED_COMPUTE_CAPACITY	 VARCHAR2(1000), --SPM-12114
    ESTIMATED_PROV_DATE          VARCHAR2(1000), --SPM-12007  
	  COST_CENTER					         VARCHAR2(1000), --SPM-12837
	  COST_CENTER_DESCRIPTION		   VARCHAR2(1000), --SPM-12837
	  PROGRAM_TYPE				         VARCHAR2(1000), --SPM-12837
	  AGREEMENT_ID             	   VARCHAR2(1000), --SPM-12871
	  START_DATE_TYPE				       VARCHAR2(1000), --SPM-13062 
	  AGREEMENT_NAME				       VARCHAR2(1000), --SPM-13242 
	  SALES_SCENARIO				       VARCHAR2(1000), --SPM-13142
    BOM_COMPONENTS OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT_TBL,
    ENTITLEMENT_COMPONENTS OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL,
    OPTIONAL_TIERS OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS_TBL,
    SALES_CREDIT OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT_TBL,
    CUSTOMERS OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_LINES );
  /
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_LINES
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_LINES
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_LINES;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_LINES (
    ORDER_LINE_ID                 => NULL,
    ORDER_LINE_NUMBER             => NULL,
    METERED_SUBSCRIPTION          => NULL,
    CSI                           => NULL,
    GSI_SYSTEM_ID                 => NULL,
    OVERAGE_ENABLED               => NULL,
    OVERAGE_THRESHOLD             => NULL,
    OVERAGE_BILLING_TERM          => NULL,
    OVERAGE_POLICY                => NULL,
    OVERAGE_PRICE                 => NULL,
    SPLIT_ALLOWANCE               => NULL,
    ALLOWANCE_SPLIT_DURATION      => NULL,
    ALLOWANCE_SPLIT_DURATION_UOM  => NULL,
    IS_SUBSCRIPTION_ENABLED       => NULL,
    SUBSCRIPTION_ID               => NULL,
    OPERATION_TYPE                => NULL,
    CLOUD_RENEWAL_FLAG            => NULL,
    CLOUD_RENEWAL_FLAG_MEANING	  => NULL,
    INV_PART_NUMBER               => NULL,
    INVENTORY_ITEM_ID             => NULL,
    INV_PART_DESCRIPTION          => NULL,
    USER_ITEM_DESCRIPTION         => NULL,
    INV_CATEGORY                  => NULL,
    USAGE_BILLING                 => NULL,
    ITEM_TYPE_CODE                => NULL,	
    START_DATE                    => NULL,
    END_DATE                      => NULL,
    DURATION                      => NULL,
    DURATION_UNIT                 => NULL,
    QUANTITY                      => NULL,
    COMMITTED_QUANTITY            => NULL,
    LINE_NET_AMOUNT               => NULL,
    TCLV                          => NULL,
    CLOUD_FUTURE_MON_PRICE        => NULL,
    CLOUD_DATA_CENTER_REGION      => NULL,
    CLOUD_DATA_CENTER_REGION_M	  => NULL,
    CLOUD_ACC_ADMIN_EMAIL         => NULL,
    SERVICE_LINE_AMOUNT           => NULL,
    OPC_CUSTOMER_NAME             => NULL,
    SPMIST4C                      => NULL,
    PROVISIONING_STATUS           => NULL,
    PROVISIONING_DATE             => NULL,
    PO_EXPIRY_DATE                => NULL,
    CAP_TO_PRICELIST              => NULL,	
    SPM_MASTER_LINE_ID            => '0',
    SPM_PRODUCT_ID                => '0',
    SPM_OLD_LINE_ID            	  => '0',
    ENTITLEMENT_COUNTRYCODE       => NULL,
    ENTITLEMENT_PHONENUMBER       => NULL,
    BASE_ORDER_LINE_ID            => NULL,
    HAS_PROMOTION                 => NULL,
    REBALANCE_OPTED               => NULL,
    FULFILLMENT_SET               => NULL,
    POOLED_ITEM                   => NULL,
    REPLACE_REASON_CODE           => NULL,
    SUPERSEDE_NOTES               => NULL,
    REPLACE_SUBSCRIPTION_ID       => NULL,
    SUPERSEDED_SET_ID             => NULL,
    PARENT_LINE_ID                => NULL,
    IS_UNIFIED                    => NULL,
    UNIFIED_REVENUE_QUOTA         => NULL,
    UNIFIED_REVENUE_AMOUNT        => NULL,
    PRICE_PERIOD                  => NULL,
    RENEWAL                       => NULL,
    UPSELL                        => NULL,
    CROSSSELL                     => NULL,
    DOWNSELL                      => NULL,
    CLOUD_ACCOUNT_ID              => NULL,
    CLOUD_ACCOUNT_NAME            => NULL,
    ASSOCIATE_SUB_ID              => NULL,
    CONTRACT_TYPE                 => NULL,
    ORIGINAL_PROMO_AMT            => NULL,
    PROMOTION_ORDER               => NULL,
    PROMOTION_TYPE                => NULL,
	  PROMOTION_TYPE_VAL            => NULL,-- SPM-13797
    PARTNER_TRANSACTION_TYPE      => NULL,
    IS_CREDIT_ENABLED             => NULL,
    CREDIT_PERCENTAGE             => NULL,
    OVERAGE_BILL_TO               => NULL,
    RATE_CARD_DIS_PER             => NULL,
    PAYG_POLICY                   => NULL,
    INTENT_TO_PAY                 => NULL,--SPM-6637
    DEPLOYMENT_TYPE		          => NULL,--SPM-7586
    DEPLOYMENT_NAME		          => NULL,--SPM-7586
    COMMIT_MODEL                  => NULL,--SPM-7835
    OVERAGE_DISCOUNT_PRCNT        => NULL,--Bug#26133321
    ASSC_REV_SUBSC_MAP            => NULL,--SPM-6780
    PROVISIONING_SOURCE           => NULL,--SPM-9560
    COMP_SALES_REP				  => NULL,--SPM-9566
    PARTNER_CREDIT_VALUE          => NULL,--SPM-10101 
    COMMIT_SCHEDULE               => NULL,--SPM-10446
        --Changes for SPM-9570 - SPMPROV
    CLOUD_PROVISION_SEQ_NUM       => NULL,
    CLOUD_PO_TERM                 => NULL,
    CLOUD_PO_TERM_UOM             => NULL,
    CLOUD_BACK_DATED_CONTRACT     => NULL,
    CLOUD_STORE_SSO_USERNAME      => NULL,
    CLOUD_REF_SUBSCRIPTION_ID     => NULL,
    CUSTOMERS_CRM_CHOICE          => NULL,
    ADMIN_FIRST_NAME              => NULL,
    ADMIN_LAST_NAME               => NULL,
    CUSTOMER_CODE                 => NULL,
    LANGUAGE_PACK                 => NULL,
    TALEO_CONSULTING_METHODOLOGY  => NULL,
    AUTO_CLOSE_FOR_PROVISIONING   => NULL,
    CHANNEL_OPTION                => NULL,
    PARTNER_ID                    => NULL,
    RAVELLO_TOKEN_ID              => NULL,
	--Changes for SPM-11135 begin- SPMPROV
    CLOUD_BACK_DATED_FLAG		       => NULL,
    PILOT_TYPE					           => NULL,
    FIXED_END_DATE_FLAG			       => NULL,
    NCER_ZONE					             => NULL,
    NCER_TYPE					             => NULL,
    --Changes for SPM-11135 end- SPMPROV
    SPECIAL_HANDLING_FLAG		       => NULL, --SPM-11120 
    LINE_OF_BUSINESS			         => NULL, --SPM-11396
    TEXTURA_TOKEN_ID			         => NULL, --SPM-11366
    APIARY_TOKEN_ID				         => NULL, --SPM-12114
    CUSTOMER_READINESS_DATE		     => NULL, --SPM-12007
    DEDICATED_COMPUTE_CAPACITY	   => NULL, --SPM-12114
    ESTIMATED_PROV_DATE       	   => NULL, --SPM-12007
	  COST_CENTER					           => NULL, --SPM-12837
	  COST_CENTER_DESCRIPTION		     => NULL, --SPM-12837
	  PROGRAM_TYPE				           => NULL, --SPM-12837
	  AGREEMENT_ID				           => NULL, --SPM-12871
	  START_DATE_TYPE				         => NULL, --SPM-13062 
	  AGREEMENT_NAME				         => NULL, --SPM-13242 
	  SALES_SCENARIO				         => NULL, --SPM-13142
    BOM_COMPONENTS                => OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT_TBL(),
    ENTITLEMENT_COMPONENTS        => OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL(),
    OPTIONAL_TIERS                => OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS_TBL(),
    SALES_CREDIT                  => OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT_TBL(),
    CUSTOMERS                     => OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL()
  );
  RETURN l_instance;
END new_instance;
END;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_LINES_TBL
AS
  TABLE OF OSS_INTF_USER.MISIMD_SPM_LINES;
/
CREATE OR REPLACE TYPE OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION
AS
  OBJECT
  (
    ORDER_HEADER_ID               VARCHAR2(1000),
    ORGANIZATION_ID               VARCHAR2(1000),
    ORGANIZATION_NAME             VARCHAR2(1000),
    ORDER_NUMBER                  VARCHAR2(1000),
    ORDER_DATE                    VARCHAR2(1000),
    ORDER_TYPE                    VARCHAR2(1000),
    ORDER_TYPE_COMPLEX            VARCHAR2(1000),
    OPERATIONTYPE                 VARCHAR2(1000),
    USAGE_BILLING                 VARCHAR2(1000),
    START_DATE                    VARCHAR2(1000),
    END_DATE                      VARCHAR2(1000),
    DURATION                      VARCHAR2(1000),
    DURATION_UOM                  VARCHAR2(1000),
    SALES_REPS                    VARCHAR2(2000),
    PRIMARY_SALESREP_ID           VARCHAR2(1000),
    SALESREP_NUMBER               VARCHAR2(1000),
    SALESREP_NAME                 VARCHAR2(2000),
    SALESREP_EMAIL                VARCHAR2(2000),
    SALES_CHANNEL                 VARCHAR2(1000),
    IS_AUTO_RENEWED               VARCHAR2(1000),
    ORDER_CREATED_BY_AUTO_RENEWAL VARCHAR2(1000),
    ORDER_SOURCE                  VARCHAR2(1000),
    PAYMENT_TERMS                 VARCHAR2(1000),
    PAYMENT_TERMS_DAYS_DUE        VARCHAR2(2000),
    PAYMENT_TERMS_ID              VARCHAR2(2000),
    CURRENCY                      VARCHAR2(1000),
    PRICE_LIST                    VARCHAR2(1000),
    PAYMENT_METHOD                VARCHAR2(1000),
    PO_NUMBER                     VARCHAR2(1000),
    INVOICE_SCHEDULE              VARCHAR2(1000),
    IS_INDIRECT                   VARCHAR2(1000),
    CONTRACT_TYPE                 VARCHAR2(1000),
    CC_TOKEN_REF                  VARCHAR2(1000),
    CC_EXPIRY_DATE                VARCHAR2(1000),
    CRM_OPTY_NUM                  VARCHAR2(1000),
    CRM_TARGET_PARTY_ID           VARCHAR2(1000),
    ISPUBLICSECTOR                VARCHAR2(1000),
    COST_CENTER                   VARCHAR2(1000),
    COST_CENTER_DESCRIPTION       VARCHAR2(1000),
    SUPERSEDED_PROJECT            VARCHAR2(1000),
    BUYER_EMAIL_ID                VARCHAR2(1000),
    RELATED_GROUP_PLAN_ID         VARCHAR2(1000),
    PLAN_CLASSIFICATION           VARCHAR2(1000),
    REKEY_TYPE                    VARCHAR2(1000),
    INFLIGHT_ORDER                VARCHAR2(1000),
    INFLIGHT_SERVICE_START_DATE   VARCHAR2(1000),
    INFLIGHT_STATUS               VARCHAR2(1000),
    INFLIGHT_SUBSCRIPTION_ID      VARCHAR2(1000),
    --Attributes Reserved for SPM BPEL processing
    ATTRIBUTE1                    VARCHAR2(1000),
    ATTRIBUTE2                    VARCHAR2(1000),
    ATTRIBUTE3                    VARCHAR2(1000),
    ATTRIBUTE4                    VARCHAR2(1000),
    ATTRIBUTE5                    VARCHAR2(1000),
    SPM_ORG_ID                    VARCHAR2(1000),
    SPM_PROJECT_ID                VARCHAR2(1000),
    SPM_PLAN_NUMBER               VARCHAR2(1000),
    SPM_PAYMENT_METHOD_ID         VARCHAR2(1000),
    SPM_BUSINESS_PARTNER_ID       VARCHAR2(1000),
    SPM_BUSINESS_PARTNER_LOC_ID   VARCHAR2(1000),
    SPM_CONTACT_ID                VARCHAR2(1000),
    SPM_BP_CATEGORY_ID            VARCHAR2(1000),
    SPM_LANGUAGE_ID               VARCHAR2(1000),
    SPM_COUNTRY_ID                VARCHAR2(1000),
    SPM_REGION_ID                 VARCHAR2(1000),
    SPM_PAYMENT_TERM_ID           VARCHAR2(1000),
    SPM_PRIMARY_SALESREP_ID       VARCHAR2(1000),
    SPM_ADUSER_ID                 VARCHAR2(1000),
    SPM_CURRENCY_ID               VARCHAR2(1000),
    SPM_PRICE_LIST_ID             VARCHAR2(1000),
    SPM_INVOICE_SCHEDULE_ID       VARCHAR2(1000),
    SPM_CONTRACT_TYPE_ID          VARCHAR2(1000),
    SPM_SHIPTO_BP_ID              VARCHAR2(1000),
    SPM_SHIPTO_BP_LOC_ID          VARCHAR2(1000),
    SPM_SHIPTO_CONTACT_ID         VARCHAR2(1000),
    SPM_SHIPTO_COUNTRY_ID         VARCHAR2(1000),
    SPM_SHIPTO_REGION_ID          VARCHAR2(1000),
    SPM_SOLDTO_BP_ID              VARCHAR2(1000),
    CUSTOMERS OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL,
    LINES OSS_INTF_USER.MISIMD_SPM_LINES_TBL,
    STATIC
  FUNCTION new_instance
    RETURN OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION );
  /
CREATE OR REPLACE TYPE BODY OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION
AS
  /**
  * Creates empty instance of the type.
  */
  STATIC
FUNCTION new_instance
  RETURN OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION
IS
  l_instance OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION;
BEGIN
  l_instance := OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION ( 
  ORDER_HEADER_ID               => NULL,
  ORGANIZATION_ID               => NULL,
  ORGANIZATION_NAME             => NULL,
  ORDER_NUMBER                  => NULL,
  ORDER_DATE                    => NULL,
  ORDER_TYPE                    => NULL,
  ORDER_TYPE_COMPLEX            => NULL,
  OPERATIONTYPE                 => NULL,
  USAGE_BILLING                 => NULL,
  START_DATE                    => NULL,
  END_DATE                      => NULL,
  DURATION                      => NULL,
  DURATION_UOM                  => NULL,
  SALES_REPS                    => NULL,
  PRIMARY_SALESREP_ID           => NULL,
  SALESREP_NUMBER               => NULL,
  SALESREP_NAME                 => NULL,
  SALESREP_EMAIL                => NULL,
  SALES_CHANNEL                 => NULL,
  IS_AUTO_RENEWED               => NULL,
  ORDER_CREATED_BY_AUTO_RENEWAL => NULL,
  ORDER_SOURCE                  => NULL,
  PAYMENT_TERMS                 => NULL, 
  PAYMENT_TERMS_DAYS_DUE        => NULL,
  PAYMENT_TERMS_ID              => NULL,
  CURRENCY                      => NULL,
  PRICE_LIST                    => NULL,
  PAYMENT_METHOD                => NULL,
  PO_NUMBER                     => NULL,
  INVOICE_SCHEDULE              => NULL,
  IS_INDIRECT                   => NULL,
  CONTRACT_TYPE                 => NULL,
  CC_TOKEN_REF                  => NULL,
  CC_EXPIRY_DATE                => NULL,
  CRM_OPTY_NUM                  => '0',		
  CRM_TARGET_PARTY_ID           => '0',
  ISPUBLICSECTOR                => NULL,
  COST_CENTER                   => NULL,
  COST_CENTER_DESCRIPTION       => NULL,
  SUPERSEDED_PROJECT            => NULL,
  BUYER_EMAIL_ID                => NULL,
  RELATED_GROUP_PLAN_ID         => NULL,
  PLAN_CLASSIFICATION           => NULL,
  REKEY_TYPE                    => NULL,  
  INFLIGHT_ORDER                => NULL,
  INFLIGHT_SERVICE_START_DATE   => NULL,
  INFLIGHT_STATUS               => NULL,
  INFLIGHT_SUBSCRIPTION_ID      => NULL,
  --Attributes Reserved for SPM BPEL processing
  ATTRIBUTE1                    => '0',
  ATTRIBUTE2                    => '0',
  ATTRIBUTE3                    => '0',
  ATTRIBUTE4                    => '0',
  ATTRIBUTE5                    => '0',
  SPM_ORG_ID                    => '0',
  SPM_PROJECT_ID                => '0',
  SPM_PLAN_NUMBER               => '0',
  SPM_PAYMENT_METHOD_ID         => '0',
  SPM_BUSINESS_PARTNER_ID       => '0',
  SPM_BUSINESS_PARTNER_LOC_ID   => '0',
  SPM_CONTACT_ID                => '0',
  SPM_BP_CATEGORY_ID            => '0',
  SPM_LANGUAGE_ID               => '0',
  SPM_COUNTRY_ID                => '0',
  SPM_REGION_ID                 => '0',
  SPM_PAYMENT_TERM_ID           => '0',
  SPM_PRIMARY_SALESREP_ID       => '0',
  SPM_ADUSER_ID                 => '0',
  SPM_CURRENCY_ID             	=> '0',
  SPM_PRICE_LIST_ID             => '0',
  SPM_INVOICE_SCHEDULE_ID       => '0',
  SPM_CONTRACT_TYPE_ID          => '0',
  SPM_SHIPTO_BP_ID              => '0',
  SPM_SHIPTO_BP_LOC_ID          => '0',
  SPM_SHIPTO_CONTACT_ID         => '0',
  SPM_SHIPTO_COUNTRY_ID         => '0',
  SPM_SHIPTO_REGION_ID          => '0',
  SPM_SOLDTO_BP_ID              => '0',
  CUSTOMERS                     => OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL(),
  LINES                         => OSS_INTF_USER.MISIMD_SPM_LINES_TBL()
  );
  RETURN l_instance;
END new_instance;
END;
/

create or replace PACKAGE           MISIMD_SPM_CLOUD_WF AUTHID DEFINER AS
-- $Header: MISIMD_SPM_CLOUD_WF.pls 120.46 2018/01/29 10:50:53 psarngal noship $
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
--   120.32   2017/01/14  psarngal - SPM-6637
--   120.33   2017/04/11  psarngal - SPM-7586 and SPM-7546 changes
--   120.46   2018/02/02  psarngal - CF 18.2
-- ===========================================================================

  PROCEDURE prepare_notify_payload (
    p_header_id IN NUMBER ,
    p_subscription_id IN NUMBER DEFAULT NULL,
    resultout OUT nocopy VARCHAR2);
  FUNCTION get_bus_event_xml(
      p_header_id NUMBER ,
      p_subscription_id NUMBER DEFAULT NULL,
      p_operation_type VARCHAR2 DEFAULT NULL)
    RETURN xmltype;
  FUNCTION is_metered_subscription(
      p_line_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION is_spm_eligible(
      p_line_id IN NUMBER)
	RETURN VARCHAR2;
  PROCEDURE set_spm_info (
      p_line_id                     IN   NUMBER,
      p_opc_customer_name           IN   VARCHAR2 DEFAULT NULL,
      p_spm_plan_number             IN   VARCHAR2 DEFAULT NULL,
      p_spm_plan_status             IN   VARCHAR2 DEFAULT NULL,
      p_spm_interface_status        IN   VARCHAR2 DEFAULT NULL,
      p_spm_interface_error         IN   VARCHAR2 DEFAULT NULL,
      p_spm_creation_date           IN   DATE DEFAULT NULL,
      p_spm_interface_update_date   IN   DATE DEFAULT NULL,
      p_invoice_number              IN   VARCHAR2 DEFAULT NULL
   );
  FUNCTION get_subscription_type(
      p_header_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION is_universal_subscription(
      p_line_id IN NUMBER)
    RETURN VARCHAR2;
  PROCEDURE prepare_inflight_payload (
    p_header_id IN NUMBER ,
    p_subscription_id IN NUMBER DEFAULT NULL,
    resultout OUT nocopy VARCHAR2);
  FUNCTION GET_SERVICE_PART(
    P_LICENSE_ITEM IN VARCHAR2)
  RETURN VARCHAR2;
  FUNCTION GET_SERVICE_PART_DESC(
    P_LICENSE_ITEM IN VARCHAR2)
  RETURN VARCHAR2;
  PROCEDURE RETRY_SPM_PROV_ORDER(
    p_errbuf OUT NOCOPY  VARCHAR2,
    p_retcode OUT NOCOPY VARCHAR2,
    p_retry_type IN VARCHAR2 DEFAULT 'SINGLE',
    p_header_id IN NUMBER DEFAULT NULL);
END MISIMD_SPM_CLOUD_WF ;
/
commit;
exit;
