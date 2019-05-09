rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls+91 \
rem dbdrv: checkfile:~PROD:~PATH:~FILE
rem 
rem Copyright (c) 2005, 2017 Oracle and/or its affiliates.
rem   All rights reserved.
rem Version 12.0.0
rem	Purpose:
rem
set verify off

whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback
CREATE OR REPLACE PACKAGE misimd_tas_cloud_wf AUTHID DEFINER AS
  -- $Header: MISIMD_TAS_CLOUD_WF.pls 120.31 2017/07/05 19:53:24 vetsrini noship $
  -- ===========================================================================
  -- Incident Bug #:13521955
  --
  -- Purpose:
  --
  --   This package is used to progress  onboarding and tas provisioning for cloud interface.
  --
  -- Notes:
  --
  -- Modifications:
  --
  --   File     Date in
  --   Version  Production  Author    Modification
  --   =======  ==========  ========  ==========================================
  --   120.0    2011/09/08  gautam - created
  --   120.66   2015/Dec/16 yuchandr - updated for CPQ grouping Logic.--
  --   120.67   2015/Dec/17 yuchandr - updated for added additional signature for paygen support for getpayload.--
  --   120.23   2016-04-13  vetsrini - added code for consolidation/split logic
  --   120.24   2016-04-13  vetsrini - correcting gsc warning
  --   120.25   2016-07-25  vetsrini - 16.7 release changes
  --   120.26   2016-09-21  vetsrini  Bug 24692394 - 16.10 release change for TAS Provisioning
  --                SPM-5446/SPM-4240/SPM-5368
  --   120.27   2016-10-17  vetsrini  Bug 24907893 - 16.10 release change for TAS Provisioning
  --                SPM-5446/SPM-4240/SPM-5368
  --   120.28   2016-11-13  kahirem  - 16.12 changes
  --   120.29   2016-07-25  vetsrini - 17.6 release changes
  --   120.32   2018-08-04  psarngal - CF 18.8-- added new procedure update_rebate_table
  -- ===========================================================================
    PROCEDURE onboarding (
        itemtype    IN VARCHAR2,
        itemkey     IN VARCHAR2,
        actid       IN NUMBER,
        funcmode    IN VARCHAR2,
        resultout   IN OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    PROCEDURE tenant_activated (
        orderdetails   IN misimd_cloud_order_tab,
        resultout      OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    PROCEDURE prepare_notify_payload (
        p_header_id   IN NUMBER,
        resultout     OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    PROCEDURE tenant_provisioned (
        orderdetails      IN misimd_cloud_order_tab,
        om_status_check   IN VARCHAR2,
        resultout         OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    PROCEDURE contracts_migration (
        p_chr_id          IN NUMBER,
        p_service_group   IN VARCHAR2,
        resultout         OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    PROCEDURE migrate_subscriptions (
        p_chr_id    IN NUMBER,
        resultout   OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    PROCEDURE updatetransaction (
        transaction_id_in   IN VARCHAR2,
        p_request_source    IN VARCHAR2 DEFAULT NULL
    );
    PROCEDURE testingharness (
        p_quote_number    IN NUMBER,
        p_quote_version   IN NUMBER,
        resultout         OUT NOCOPY
      /* file.sql.39 change */ VARCHAR2
    );
    FUNCTION get_migration_servicegroup (
        p_hdr_id   IN NUMBER,
        p_sub_id   IN VARCHAR2
    ) RETURN VARCHAR2;
    FUNCTION get_aso_servicegroup ( p_line_id   IN NUMBER ) RETURN VARCHAR2;
    FUNCTION get_incremental_properties ( p_chr_id   IN NUMBER ) RETURN VARCHAR2;
  --FUNCTION get_bus_event_xml ( p_header_id in number ,p_sub_id varchar2 ,p_TAS_OR_EMAIL in VARCHAR) return xmltype ;
    FUNCTION get_bus_event_xml (
        p_header_id      IN NUMBER,
        p_sub_id         VARCHAR2,
        p_tas_or_email   IN VARCHAR,
        p_line_ids       IN VARCHAR2 DEFAULT NULL
    ) RETURN XMLTYPE;
    FUNCTION get_covered_line_metrics (
        p_line_id   IN VARCHAR2,
        p_metric    IN VARCHAR2
    ) RETURN VARCHAR2;
    FUNCTION get_unique_instance_id ( p_line_id   IN NUMBER ) RETURN NUMBER;
    FUNCTION check_provisioned_product ( p_item_id   IN NUMBER ) RETURN VARCHAR2;
    FUNCTION is_metered_subscription ( p_line_id   IN NUMBER ) RETURN VARCHAR2;
    FUNCTION is_combined_payload ( p_hdr_id   IN NUMBER ) RETURN VARCHAR2;
  --function get_payload (p_header_id in number,p_sub_id in varchar2,p_line_id in number,request_source in varchar2 default 'GSI') return xmltype;
    FUNCTION get_payload (
        p_header_id        IN NUMBER,
        p_sub_id           IN VARCHAR2,
        p_line_id          IN NUMBER,
        request_source     IN VARCHAR2 DEFAULT 'GSI',
        p_operation_type   IN VARCHAR2 DEFAULT NULL,
        p_line_ids         IN VARCHAR2 DEFAULT NULL
    ) RETURN XMLTYPE;
  --function get_payload (p_header_id in number,p_sub_id in varchar2,p_line_id in number,request_source in varchar2 default 'GSI',p_line_ids IN
  -- VARCHAR2) return xmltype;
    FUNCTION get_rule_values (
        p_rule_set     IN VARCHAR2,
        p_rule_value   IN VARCHAR2
    ) RETURN VARCHAR2;
    FUNCTION get_associated_sub_id ( p_line_id   IN NUMBER ) RETURN VARCHAR2;
    PROCEDURE insert_error (
        p_error_code      IN VARCHAR2,
        p_error_message   IN VARCHAR2,
        g_module          IN VARCHAR2,
        g_context_name2   IN VARCHAR2,
        g_context_id      IN NUMBER,
        errbuf            OUT NOCOPY VARCHAR2
    );
    PROCEDURE insert_log (
        g_audit_message      IN VARCHAR2,
        g_audit_level        IN NUMBER,
        g_module             IN VARCHAR2,
        g_context_name2      IN VARCHAR2,
        g_context_id         IN NUMBER,
        g_audit_attachment   IN CLOB
    );
    PROCEDURE init ( p_errror_flag   OUT NOCOPY VARCHAR2 );
    PROCEDURE tas_cpq_grp_process (
        p_header_id        IN NUMBER,
        p_operation_type   IN VARCHAR2,
        p_trx_id           OUT NOCOPY NUMBER,
        p_request_source   IN VARCHAR2 DEFAULT 'GSI'
    );
    PROCEDURE split_initiate_send (
        errbuf        OUT NOCOPY VARCHAR2,
        retcode       OUT NOCOPY VARCHAR2,
        p_trx_id      IN NUMBER DEFAULT NULL,
        p_source      IN VARCHAR2 DEFAULT 'SPLIT_SEND',
        p_header_id   IN NUMBER DEFAULT NULL,
        p_line_ids    IN VARCHAR2 DEFAULT NULL,
        p_optype      IN VARCHAR2 DEFAULT NULL,
        p_dbms_flag   IN VARCHAR2 DEFAULT 'N'
    );
    PROCEDURE split_prepare_split_lines (
        p_header_id              IN NUMBER,
        p_sub_id                 IN VARCHAR2,
        p_line_ids IN OUT NOCOPY VARCHAR2,
        p_line_ids_changed_flg   OUT NOCOPY VARCHAR2
    );
    PROCEDURE split_insert_split_line (
        p_line_id                  IN VARCHAR2,
        p_waiting_on               IN VARCHAR2,
        p_staging_operation_type   IN VARCHAR2,
        p_hold                     IN VARCHAR2,
        p_fullfillment_chg         IN VARCHAR2,
        p_transaction_id           IN NUMBER
    );
    FUNCTION split_create_line_list (
        p_header_id   IN NUMBER,
        p_sub_id      IN VARCHAR2
    ) RETURN VARCHAR2;
    PROCEDURE split_send_split_payload (
        p_line_ids    IN VARCHAR2 DEFAULT NULL,
        p_trx_id      IN NUMBER DEFAULT NULL,
        p_dbms_flag   IN VARCHAR2 DEFAULT 'N'
    );
    PROCEDURE split_concurrent_pgm ( p_transaction_id   NUMBER );
    FUNCTION get_cd_rate ( p_trans_curr_code   IN VARCHAR2 ) RETURN NUMBER;
    FUNCTION return_parent_line_id (
        p_line_id   IN NUMBER,
        p_type      IN VARCHAR2
    ) RETURN NUMBER;
    PROCEDURE manage_tas_lines (
        p_tas_outbound_payload   IN XMLTYPE,
        p_header_id              IN NUMBER,
        p_source                 IN VARCHAR,
        p_status                 OUT NOCOPY VARCHAR,
        p_message                OUT NOCOPY VARCHAR
    );
    FUNCTION get_provisioning_system (
        p_service_group   IN VARCHAR2 DEFAULT NULL,
        p_line_id         IN VARCHAR2 DEFAULT NULL,
        p_line_ids        IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;
    FUNCTION append_iot_lines ( p_payload   XMLTYPE ) RETURN XMLTYPE;
    FUNCTION get_subscription_info ( spmsub   misimd_subid_collection ) RETURN misimd_subid_collection;
	PROCEDURE update_rebate_table(
    p_header_id      IN NUMBER ,
    p_line_id        IN NUMBER ,
    p_sub_id         IN NUMBER ,
    p_prov_date      IN VARCHAR2,
    p_status OUT NOCOPY VARCHAR,
    p_message OUT NOCOPY VARCHAR );
END misimd_tas_cloud_wf;
/
commit;
exit