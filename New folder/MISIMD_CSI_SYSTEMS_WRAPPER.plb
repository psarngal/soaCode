rem dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
rem dbdrv: checkfile:~PROD:~PATH:~FILE

set verify off
whenever sqlerror exit failure rollback
whenever oserror  exit failure rollback
create or replace PACKAGE BODY  MISIMD_CSI_SYSTEMS_WRAPPER AS
-- $Header: MISIMD_CSI_SYSTEMS_WRAPPER.plb 120.5 2018/09/12 12:19:05 sbollaba noship $ 
-- Copyright (c) 2005, 2018  Oracle and/or its affiliates.
-- All rights reserved.
-- Start of Comments
-- Package name     : MISIMD_CSI_SYSTEMS_WRAPPER
-- Purpose          : Create a new system_id when a customer gets converted from promo to Pay as you Go version and change the Customer.
-- History          :
--   File     Date in
--   Version  Production  Author    Modification
--   =======  ==========  ========  ==========================================
--   120.0    2014/04/07  sbollaba - created
--   120.6    2018/8/23   sbollaba 
-- NOTE             :
-- END of Comments




G_PKG_NAME CONSTANT VARCHAR2(30):= 'MISIMD_CSI_SYSTEMS_WRAPPER';
G_FILE_NAME CONSTANT VARCHAR2(30) := 'misimd_csi_systems_wrapper.pls';

g_system_type_code    csi_systems_b.system_type_code%TYPE := 1000;
g_transaction_type_id csi_transactions.transaction_type_id%TYPE := 51;
g_inventory_org_id mtl_system_items_b.organization_id%TYPE;



PROCEDURE create_system(
    p_cust_account_id            IN     NUMBER,
    p_cust_acct_site_id          IN     NUMBER,
    p_cust_acct_role_id          IN     NUMBER,
    p_order_header_id            IN     NUMBER,
    x_system_id                  OUT NOCOPY    NUMBER,
    x_return_status              OUT NOCOPY    VARCHAR2,
    x_msg_count                  OUT NOCOPY    NUMBER,
    x_msg_data                   OUT NOCOPY    VARCHAR2
    )

 is
l_debug_level number;
l_transaction_id number;
l_party_id number;
l_party_site_id number;
l_contact_id number;
l_invoice_site_use_id number;
l_ship_site_use_id  number;
p_system_rec       csi_datastructures_pub.system_rec;
p_txn_rec  csi_datastructures_pub.transaction_rec;
l_category_set_id        mtl_category_sets.category_set_id%TYPE := 1;
l_order_lines_ramped_cnt NUMBER;
CURSOR c_order_lines IS
      SELECT lines.*
        FROM oe_order_lines_all     lines,
             mtl_system_items_b     msi,
             mtl_item_categories    mic,
             mtl_categories         mc,
             oe_order_price_attribs pr
       WHERE lines.inventory_item_id = msi.inventory_item_id
         AND msi.inventory_item_id = mic.inventory_item_id
         AND mc.category_id = mic.category_id
         AND msi.organization_id = 14354
         AND mic.organization_id = 14354
         AND mic.category_set_id = l_category_set_id
         AND lines.header_id = p_order_header_id
         and pr.header_id = lines.header_id
         and pr.line_id = lines.line_id
         AND msi.comms_nl_trackable_flag = 'Y'
         and pr.PRICING_ATTRIBUTE94 <> 'RAMPED_UPDATE';
  
    CURSOR c_order_lines_ramped_cnt IS
      SELECT count(1)
        FROM oe_order_lines_all     lines,
             mtl_system_items_b     msi,
             mtl_item_categories    mic,
             mtl_categories         mc,
             oe_order_price_attribs pr
       WHERE lines.inventory_item_id = msi.inventory_item_id
         AND msi.inventory_item_id = mic.inventory_item_id
         AND mc.category_id = mic.category_id
         AND msi.organization_id = 14354
         AND mic.organization_id = 14354
         AND mic.category_set_id = l_category_set_id
         AND lines.header_id = p_order_header_id
         and pr.PRICING_ATTRIBUTE94 = 'RAMPED_UPDATE'
         and pr.header_id = lines.header_id
         and pr.line_id = lines.line_id
         AND msi.comms_nl_trackable_flag = 'Y';
 BEGIN
 l_debug_level :=1;



        ----------------------------------------------------------------------------
        -- Set values in p_system_rec
        ----------------------------------------------------------------------------
        --Assign customer account id
        p_system_rec.system_type_code := g_system_type_code;
        p_system_rec.customer_id      := p_cust_account_id;

      --Assign customer contacts
       SELECT c.party_id
        INTO l_contact_id
        FROM hz_cust_account_roles a, hz_relationships b, hz_parties c
       WHERE a.cust_account_role_id = p_cust_acct_role_id
         AND b.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
         AND b.OBJECT_TABLE_NAME = 'HZ_PARTIES'
         AND b.DIRECTIONAL_FLAG = 'F'
         AND a.party_id = b.party_id
         AND b.subject_id = c.party_id;

        p_system_rec.technical_contact_id     := l_contact_id;
        p_system_rec.service_admin_contact_id := l_contact_id;
        p_system_rec.bill_to_contact_id := l_contact_id;
        p_system_rec.ship_to_contact_id := l_contact_id;

        --Assign site and siteUses
        select party_site_id into l_party_site_id
        from hz_cust_acct_sites_all
        where cust_acct_site_id = p_cust_acct_site_id;

        select site_use_id into l_invoice_site_use_id from hz_cust_site_uses_all
        where cust_acct_site_id = p_cust_acct_site_id
        and site_use_code like 'BILL_TO';

        select site_use_id into l_ship_site_use_id from hz_cust_site_uses_all
        where cust_acct_site_id = p_cust_acct_site_id
        and site_use_code like 'SHIP_TO';


        p_system_rec.install_site_use_id := l_party_site_id;
        p_system_rec.bill_to_site_use_id := l_invoice_site_use_id;
        p_system_rec.ship_to_site_use_id :=  l_ship_site_use_id;

        

        select org_id into  p_system_rec.operating_unit_id 
        from hz_cust_acct_sites_all
        where cust_acct_site_id = p_cust_acct_site_id;

         /*p_system_rec.operating_unit_id   := 1001; */  
        /*TO_NUMBER(SUBSTR(SYS_CONTEXT('USERENV', 'CLIENT_INFO'),1,10));*/
        /*TO_NUMBER(SUBSTR(USERENV('CLIENT_INFO'),
                                                             1,
                                                             10));*/
        select attribute3 into
        p_system_rec.attribute12
        from oe_order_headers_all where
        header_id = p_order_header_id;


    ----------------------------------------------------------------------------
        -- Set values in p_transaction_rec
        ----------------------------------------------------------------------------
        p_txn_rec.transaction_type_id     := g_transaction_type_id;
        p_txn_rec.source_header_ref       := 'OE_ORDER_HEADERS_ALL';
        p_txn_rec.source_header_ref_id    := p_order_header_id;
        select ordered_date into
        p_txn_rec.source_transaction_date
        from oe_order_headers_all where header_id = p_order_header_id;

        csi_systems_pub.create_system(p_api_version      => 1.0,
                                      p_commit           => fnd_api.G_FALSE,
                                      p_init_msg_list    => fnd_api.G_TRUE,
                                      p_validation_level => 100,
                                      p_system_rec       => p_system_rec,
                                      p_txn_rec          => p_txn_rec,
                                      x_system_id        => x_system_id,
                                      x_return_status    => x_return_status,
                                      x_msg_count        => x_msg_count,
                                      x_msg_data         => x_msg_data);

        IF x_return_status = 'S' THEN
          l_transaction_id := p_txn_rec.transaction_id;
        /* IF l_debug_level > 0 THEN
            dbms_output.putline('Succesfully Created CSI_SYSTEM ' ||
                             x_system_id,
                             1);
          END IF;*/

        ELSE
            x_system_id := null;
        /*          IF l_debug_level > 0 THEN
            dbms_output.putline('Errored in Call API to create csi_systems_b and csi_transactions' ||
                             x_return_status || ' ' || x_msg_count || ' ' ||
                             x_msg_data,
                             1);
          END IF;*/

        END IF;
        
        --Create installation records
        
        IF X_SYSTEM_ID is not null THEN
            Begin
        
          SELECT party_id
            INTO l_party_id
            FROM hz_cust_accounts
           WHERE cust_account_id = p_cust_account_id;
        
        Exception
          WHEN NO_DATA_FOUND THEN
            l_party_id := null;
          WHEN OTHERS THEN
            l_party_id := null;
          
        End;
       /* IF l_debug_level > 0 THEN
          OE_DEBUG_PUB.Add('Creating Installation Details for CSI ' ||
                           l_order_header.header_id || ' ' || l_system_id || ' ' ||
                           l_party_id || ' ' || l_sold_to_contact_party_id || ' ' ||
                           l_technical_contact_party_id,
                           1);
        END IF;*/
      
        --get value for inventory _org_id
        begin
        
          select master_organization_id
            into g_inventory_org_id
            from oe_system_parameters
           where org_id = (select org_id from oe_order_headers_all where header_id = p_order_header_id);
        
        Exception
          WHEN NO_DATA_FOUND THEN
            g_inventory_org_id := null;
          WHEN OTHERS THEN
            g_inventory_org_id := null;
          
        End;
        
        FOR l_order_line IN c_order_lines LOOP
          misont_csi.process_order_lines(p_order_header_id,
                              l_order_line.line_id,
                              x_system_id,
                              l_party_id,
                              l_party_site_id);
        
        END LOOP;
      
        BEGIN
          open c_order_lines_ramped_cnt;
          fetch c_order_lines_ramped_cnt
            into l_order_lines_ramped_cnt;
          close c_order_lines_ramped_cnt;
          IF l_order_lines_ramped_cnt > 0 THEN
		--amadlur : adding nvl to set PA95 for Bug 27890630 
            UPDATE oe_order_price_attribs oopa
               set oopa.PRICING_ATTRIBUTE95 = nvl (oopa.PRICING_ATTRIBUTE95,x_system_id)
             where oopa.PRICING_ATTRIBUTE94 = 'RAMPED_UPDATE'
               and oopa.header_id = p_order_header_id;
            COMMIT;
          
          ELSE
          l_order_lines_ramped_cnt := 0;
           /* IF l_debug_level > 0 THEN
              OE_DEBUG_PUB.Add('RAMPED UPDATE COUNT IS ZERO', 1);
            END IF;*/
          END IF;
        END;
      
        
        ELSE
        x_system_id := null;
        --No need to create installation record if the csi creation not returned anything
         
        END IF;
        
END create_system;

END misimd_csi_systems_wrapper;

/

commit;
exit;
