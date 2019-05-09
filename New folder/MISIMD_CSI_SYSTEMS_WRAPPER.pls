rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls \
rem dbdrv: checkfile:~PROD:~PATH:~FILE

set verify off

whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback

create or replace PACKAGE      MISIMD_CSI_SYSTEMS_WRAPPER AUTHID DEFINER AS 
-- $Header: MISIMD_CSI_SYSTEMS_WRAPPER.pls 120.2 2018/09/07 11:20:37 sbollaba noship $ 
-- Copyright (c) 2005, 2018  Oracle and/or its affiliates.
-- All rights reserved.
-- Start of Comments
-- Package name     : MISIMD_CSI_SYSTEMS_WRAPPER
-- Purpose          : Create a new system_id when a customer gets converted from promo to Pay as you Go version and change the Customer.
-- History          : 
-- NOTE             :
-- END of Comments

PROCEDURE create_system(
    p_cust_account_id            IN   NUMBER,
    p_cust_acct_site_id          IN   NUMBER,
    p_cust_acct_role_id          IN   NUMBER,
    p_order_header_id            IN     NUMBER,
    x_system_id                  OUT NOCOPY  NUMBER,
    x_return_status              OUT NOCOPY  VARCHAR2,
    x_msg_count                  OUT NOCOPY  NUMBER,
    x_msg_data                   OUT NOCOPY  VARCHAR2
    );
  /* TODO enter package declarations (types, exceptions, methods etc) here */ 



END MISIMD_CSI_SYSTEMS_WRAPPER;
/

/
commit;
exit;