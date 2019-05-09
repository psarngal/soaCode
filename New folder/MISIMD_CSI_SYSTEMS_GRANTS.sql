rem $Header: MISIMD_CSI_SYSTEMS_GRANTS.sql 120.56 2018/07/18 05:08:11 psarngal noship $
rem Copyright (c) 2005, 2018  Oracle and/or its affiliates.
rem All rights reserved.
rem Version 12.0.0
rem dbdrv: sql ~PROD ~PATH ~FILE none none none sql &phase=last \
rem dbdrv: checkfile:~PROD:~PATH:~FILE \
rem dbdrv: &un_misimd &pw_misimd
rem
rem ==========================================================================
rem Incident Bug #: 
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
rem   120.0    2018-09-13  sbollaba  - created
rem
rem
rem ==========================================================================

set verify off

whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback

connect &1/&2;

grant all on APPS.MISIMD_CSI_SYSTEMS_WRAPPER to apps,misbpel;

rem ad_error_handling: remove 1434
rem ad_error_handling: remove 4043
rem ad_error_handling: remove 955


commit;
exit;


