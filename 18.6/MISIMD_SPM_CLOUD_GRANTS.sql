rem $Header: MISIMD_SPM_CLOUD_GRANTS.sql 120.41 2017/09/25 06:34:45 psarngal noship $
rem Copyright (c) 2005, 2018  Oracle and/or its affiliates.
rem All rights reserved.
rem Version 12.0.0
rem dbdrv: sql ~PROD ~PATH ~FILE none none none sql &phase=last \
rem dbdrv: checkfile:~PROD:~PATH:~FILE \
rem dbdrv: &un_misimd &pw_misimd
rem
rem ==========================================================================
rem Incident Bug #:13521955 
rem
rem Purpose:
rem
rem   This file gives execute grant to MISBPEL schema for custom package
rem
rem Notes:
rem
rem   o NA
rem
rem   o NA
rem
rem Modifications:
rem
rem   File     Date in
rem   Version  Production  Author    Modification
rem   =======  ==========  ========  =========================================
rem   120.0    2014-06-13  nitesaxe  - created
rem
rem
rem ==========================================================================

set verify off

whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback

connect &1/&2;

grant all on OSS_INTF_USER.MISIMD_SPM_SUBSCRIPTION to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_CUSTOMER_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_CUSTOMER to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_LINES_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_LINES to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_ENT_COMPONENT to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_SALES_CREDIT to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_OPTIONAL_TIERS to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_BOM_COMPONENT to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_RATE_CARD_TBL to apps,misbpel;
grant all on OSS_INTF_USER.MISIMD_SPM_RATE_CARD to apps,misbpel;

rem ad_error_handling: remove 1434
rem ad_error_handling: remove 4043
rem ad_error_handling: remove 955


commit;
exit;


