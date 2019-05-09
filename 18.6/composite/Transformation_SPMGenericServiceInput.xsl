<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:msg_in_out="http://www.oracle.com/spm/generic/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:pc="http://xmlns.oracle.com/pcbpel/"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:ph="http://xmlns.oracle.com/pcbpel/adapter/aq/headers/payloadheaders/"
                xmlns:plt="http://schemas.xmlsoap.org/ws/2003/05/partner-link/"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:tns="http://xmlns.oracle.com/pcbpel/adapter/AQ/SPM/MISIMDOMNotifySPM/DequeueOrderDetailsForSPM"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:obj1="http://xmlns.oracle.com/xdb/APPS"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath" xmlns:ns1="http://www.oracle.com/spm"
                xmlns:jca="http://xmlns.oracle.com/pcbpel/wsdl/jca/"
                xmlns:ns0="http://xmlns.oracle.com/pcbpel/adapter/http/SPM/MISIMDOMNotifySPM/SPMGenericWS"
                xmlns:med="http://schemas.oracle.com/mediator/xpath" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:missemXMLContentFunctions="http://www.oracle.com/XSL/Transform/java/com.oracle.missem.contentmgmt.XMLContentHandler"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                xmlns:oracle-xsl-mapper="http://www.oracle.com/xsl/mapper/schemas"
                xmlns:oraxsl="http://www.oracle.com/XSL/Transform/java"
                exclude-result-prefixes="xsi oracle-xsl-mapper oraxsl xsl msg_in_out pc ph plt wsdl tns obj1 ns1 jca xsd ns0 xp20 bpws bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref ldap"
                xmlns:ns2="http://www.oracle.com/spm/generic/"
                xmlns:ns3="http://xmlns.oracle.com/oih/oracle_integration_message">
  <oracle-xsl-mapper:schema>
    <oracle-xsl-mapper:mapSources>
      <oracle-xsl-mapper:source type="XSD">
        <oracle-xsl-mapper:schema location="../xsd/OM_SPM.xsd"/>
        <oracle-xsl-mapper:rootElement name="MISIMD_SPM_SUBSCRIPTION" namespace="http://www.oracle.com/spm"/>
      </oracle-xsl-mapper:source>
    </oracle-xsl-mapper:mapSources>
    <oracle-xsl-mapper:mapTargets>
      <oracle-xsl-mapper:target type="XSD">
        <oracle-xsl-mapper:schema location="../xsd/SPMSubscription.xsd"/>
        <oracle-xsl-mapper:rootElement name="ORACLE_INTEGRATION_MESSAGE"
                                       namespace="http://xmlns.oracle.com/oih/oracle_integration_message"/>
      </oracle-xsl-mapper:target>
    </oracle-xsl-mapper:mapTargets>
  </oracle-xsl-mapper:schema>
  <xsl:variable name="varContactIdentifier"
                select='concat("_",substring (/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CONTRACT_TYPE,7, 1 ))'/>
  <xsl:template match="/">
    <msg_in_out:ORACLE_INTEGRATION_MESSAGE>
      <msg_in_out:DOCUMENT_NAME>
        <xsl:text disable-output-escaping="no">GENERIC_SPM_CREATE_UPDATE</xsl:text>
      </msg_in_out:DOCUMENT_NAME>
      <msg_in_out:DOCUMENT_NUMBER>
        <xsl:value-of select='concat (/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_NUMBER, "-", /ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES[1]/ns1:ORDER_LINE_ID, "-", /ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES/ns1:OPERATION_TYPE,$varContactIdentifier)'/>
      </msg_in_out:DOCUMENT_NUMBER>
      <msg_in_out:DOCUMENT_TYPE>
        <xsl:text disable-output-escaping="no">CREATE_UPDATE_SUBSCRIPTION</xsl:text>
      </msg_in_out:DOCUMENT_TYPE>
      <msg_in_out:FROM_SYSTEM>
        <xsl:text disable-output-escaping="no">GSI-OM</xsl:text>
      </msg_in_out:FROM_SYSTEM>
      <msg_in_out:TO_SYSTEM>
        <xsl:text disable-output-escaping="no">SPM</xsl:text>
      </msg_in_out:TO_SYSTEM>
      <msg_in_out:PAYLOAD>
        <msg_in_out:SPM>
          <msg_in_out:Subscription>
            <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER = "0"'>
              <msg_in_out:Name>
                <xsl:value-of select='concat(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_TYPE,"_",/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_NUMBER,$varContactIdentifier)'/>
              </msg_in_out:Name>
            </xsl:if>
            <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER != "0"'>
              <msg_in_out:SearchKey>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER"/>
              </msg_in_out:SearchKey>
            </xsl:if>
            <xsl:choose>
              <xsl:when test='substring-before(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SUBSCRIPTION_SOURCE,"-") = "CRMOD"'>
                <msg_in_out:SubscriptionSource>
                  <xsl:text disable-output-escaping="no">SPM</xsl:text>
                </msg_in_out:SubscriptionSource>
              </xsl:when>
              <xsl:when test='substring-before(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SUBSCRIPTION_SOURCE,"-") = "SPM"'>
                <msg_in_out:SubscriptionSource>
                  <xsl:text disable-output-escaping="no">SPM</xsl:text>
                </msg_in_out:SubscriptionSource>
              </xsl:when>
              <xsl:when test='substring-before(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SUBSCRIPTION_SOURCE,"-") = "OKS"'>
                <msg_in_out:SubscriptionSource>
                  <xsl:text disable-output-escaping="no">OKS</xsl:text>
                </msg_in_out:SubscriptionSource>
              </xsl:when>
              <xsl:otherwise>
                <msg_in_out:SubscriptionSource/>
              </xsl:otherwise>
            </xsl:choose>
            <msg_in_out:Organization>
              <msg_in_out:SearchKey>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
              </msg_in_out:SearchKey>
            </msg_in_out:Organization>
            <!--xsl:if test='(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER = "0") or /ns1:MISIMD_SPM_SUBSCRIPTION/ns1:OPERATIONTYPE = "EXTENSION" or /ns1:MISIMD_SPM_SUBSCRIPTION/ns1:OPERATIONTYPE = "RAMPED_EXTENSION" or /ns1:MISIMD_SPM_SUBSCRIPTION/ns1:OPERATIONTYPE = "PILOT_CONVERSION"'-->
            <!--Removed for bug#27384142-->
            <msg_in_out:SubscriptionType>
              <msg_in_out:Name>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CONTRACT_TYPE"/>
              </msg_in_out:Name>
            </msg_in_out:SubscriptionType>
            <!--/xsl:if-->
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='ns1:SITE_USE_TYPE = "SOLD_TO"'>
                <msg_in_out:Sold2Customer>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">0</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TcaCustAccountId>
                    <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                  </msg_in_out:TcaCustAccountId>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="ns1:CUST_ACCOUNT_NUMBER"/>
                  </msg_in_out:SearchKey>
                  <msg_in_out:Name>
                    <xsl:value-of select="ns1:PARTY_NAME"/>
                  </msg_in_out:Name>
                  <msg_in_out:CustomerEnglishName>
                    <xsl:value-of select="ns1:TRANSLATED_NAME"/>
                  </msg_in_out:CustomerEnglishName>
                  <msg_in_out:BusinessPartnerCategory>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">CUSTOMER</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:BusinessPartnerCategory>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCAPartyNumber>
                    <xsl:value-of select="ns1:PARTY_NUMBER"/>
                  </msg_in_out:TCAPartyNumber>
                  <msg_in_out:IsChainCustomer>
                    <xsl:value-of select="ns1:IS_CHAIN_CUSTOMER"/>
                  </msg_in_out:IsChainCustomer>
                  <msg_in_out:IsPublicSector>
                    <xsl:value-of select="ns1:IS_PUBLIC_SECTOR"/>
                  </msg_in_out:IsPublicSector>
                  <msg_in_out:CustomerChainType>
                    <xsl:value-of select="ns1:CUSTOMER_CHAIN_TYPE"/>
                  </msg_in_out:CustomerChainType>
                </msg_in_out:Sold2Customer>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "SOLD_TO") and ns1:CONTACT_CUST_ACCT_ROLE_ID'>
                <msg_in_out:Sold2Contact>
                  <msg_in_out:TCACustAccRoleId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                  </msg_in_out:TCACustAccRoleId>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Name>
                    <xsl:value-of select='concat(ns1:CONTACT_FIRST_NAME," ",ns1:CONTACT_LAST_NAME)'/>
                  </msg_in_out:Name>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:FirstName>
                    <xsl:value-of select="ns1:CONTACT_FIRST_NAME"/>
                  </msg_in_out:FirstName>
                  <msg_in_out:LastName>
                    <xsl:value-of select="ns1:CONTACT_LAST_NAME"/>
                  </msg_in_out:LastName>
                  <msg_in_out:Email>
                    <xsl:value-of select="ns1:CONTACT_EMAIL"/>
                  </msg_in_out:Email>
                  <msg_in_out:Phone>
                    <xsl:value-of select="ns1:CONTACT_PHONE"/>
                  </msg_in_out:Phone>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:CONTACT_PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCACustAccSiteId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccSiteId>
                </msg_in_out:Sold2Contact>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='ns1:SITE_USE_TYPE = "BILL_TO"'>
                <msg_in_out:Bill2Customer>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">0</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TcaCustAccountId>
                    <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                  </msg_in_out:TcaCustAccountId>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="ns1:CUST_ACCOUNT_NUMBER"/>
                  </msg_in_out:SearchKey>
                  <msg_in_out:Name>
                    <xsl:value-of select="ns1:PARTY_NAME"/>
                  </msg_in_out:Name>
                  <msg_in_out:CustomerEnglishName>
                    <xsl:value-of select="ns1:TRANSLATED_NAME"/>
                  </msg_in_out:CustomerEnglishName>
                  <msg_in_out:BusinessPartnerCategory>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">CUSTOMER</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:BusinessPartnerCategory>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCAPartyNumber>
                    <xsl:value-of select="ns1:PARTY_NUMBER"/>
                  </msg_in_out:TCAPartyNumber>
                  <msg_in_out:IsChainCustomer>
                    <xsl:value-of select="ns1:IS_CHAIN_CUSTOMER"/>
                  </msg_in_out:IsChainCustomer>
                  <msg_in_out:IsPublicSector>
                    <xsl:value-of select="ns1:IS_PUBLIC_SECTOR"/>
                  </msg_in_out:IsPublicSector>
                   <msg_in_out:CustomerChainType>
                    <xsl:value-of select="ns1:CUSTOMER_CHAIN_TYPE"/>
                  </msg_in_out:CustomerChainType>
                </msg_in_out:Bill2Customer>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "BILL_TO") and ns1:CUST_ACCT_SITE_ID'>
                <msg_in_out:Bill2Address>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TCACustAccntSiteId>
                    <xsl:value-of select="ns1:CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccntSiteId>
                  <msg_in_out:PartySiteNumber>
                    <xsl:value-of select="ns1:PARTY_SITE_NUMBER"/>
                  </msg_in_out:PartySiteNumber>
                  <msg_in_out:Name>
                    <xsl:value-of select='substring(concat(ns1:CITY,", ",ns1:ADDRESS1),1.0,60.0)'/>
                  </msg_in_out:Name>
                  <msg_in_out:IsInvoice2Address>
                    <xsl:text disable-output-escaping="no">true</xsl:text>
                  </msg_in_out:IsInvoice2Address>
                  <msg_in_out:GeographyLocation>
                    <msg_in_out:TcaLocationId>
                      <xsl:value-of select="ns1:LOCATION_ID"/>
                    </msg_in_out:TcaLocationId>
                    <msg_in_out:AddressLine1>
                      <xsl:value-of select="ns1:ADDRESS1"/>
                    </msg_in_out:AddressLine1>
                    <msg_in_out:AddressLine2>
                      <xsl:value-of select="ns1:ADDRESS2"/>
                    </msg_in_out:AddressLine2>
                    <msg_in_out:PostalCode>
                      <xsl:value-of select="ns1:POSTAL_CODE"/>
                    </msg_in_out:PostalCode>
                    <msg_in_out:CityName>
                      <xsl:value-of select="ns1:CITY"/>
                    </msg_in_out:CityName>
                    <xsl:if test="ns1:STATE">
                      <msg_in_out:Region>
                        <msg_in_out:Name>
                          <xsl:value-of select="ns1:STATE"/>
                        </msg_in_out:Name>
                        <msg_in_out:Country>
                          <msg_in_out:Code>
                            <xsl:value-of select="ns1:COUNTRY"/>
                          </msg_in_out:Code>
                        </msg_in_out:Country>
                      </msg_in_out:Region>
                    </xsl:if>
                    <msg_in_out:Country>
                      <msg_in_out:Code>
                        <xsl:value-of select="ns1:COUNTRY"/>
                      </msg_in_out:Code>
                    </msg_in_out:Country>
                  </msg_in_out:GeographyLocation>
                  <msg_in_out:Bill2SiteUseId>
                    <xsl:value-of select="ns1:SITE_USE_ID"/>
                  </msg_in_out:Bill2SiteUseId>
                </msg_in_out:Bill2Address>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "BILL_TO") and ns1:CONTACT_CUST_ACCT_ROLE_ID'>
                <msg_in_out:BillingContact>
                  <msg_in_out:TCACustAccRoleId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                  </msg_in_out:TCACustAccRoleId>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Name>
                    <xsl:value-of select='concat(ns1:CONTACT_FIRST_NAME," ",ns1:CONTACT_LAST_NAME)'/>
                  </msg_in_out:Name>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:FirstName>
                    <xsl:value-of select="ns1:CONTACT_FIRST_NAME"/>
                  </msg_in_out:FirstName>
                  <msg_in_out:LastName>
                    <xsl:value-of select="ns1:CONTACT_LAST_NAME"/>
                  </msg_in_out:LastName>
                  <msg_in_out:Email>
                    <xsl:value-of select="ns1:CONTACT_EMAIL"/>
                  </msg_in_out:Email>
                  <msg_in_out:Phone>
                    <xsl:value-of select="ns1:CONTACT_PHONE"/>
                  </msg_in_out:Phone>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:CONTACT_PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCACustAccSiteId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccSiteId>
                </msg_in_out:BillingContact>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='ns1:SITE_USE_TYPE = "SHIP_TO"'>
                <msg_in_out:Service2Customer>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">0</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TcaCustAccountId>
                    <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                  </msg_in_out:TcaCustAccountId>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="ns1:CUST_ACCOUNT_NUMBER"/>
                  </msg_in_out:SearchKey>
                  <msg_in_out:Name>
                    <xsl:value-of select="ns1:PARTY_NAME"/>
                  </msg_in_out:Name>
                  <msg_in_out:CustomerEnglishName>
                    <xsl:value-of select="ns1:TRANSLATED_NAME"/>
                  </msg_in_out:CustomerEnglishName>
                  <msg_in_out:BusinessPartnerCategory>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">CUSTOMER</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:BusinessPartnerCategory>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCAPartyNumber>
                    <xsl:value-of select="ns1:PARTY_NUMBER"/>
                  </msg_in_out:TCAPartyNumber>
                  <msg_in_out:IsChainCustomer>
                    <xsl:value-of select="ns1:IS_CHAIN_CUSTOMER"/>
                  </msg_in_out:IsChainCustomer>
                  <msg_in_out:IsPublicSector>
                    <xsl:value-of select="ns1:IS_PUBLIC_SECTOR"/>
                  </msg_in_out:IsPublicSector>
                   <msg_in_out:CustomerChainType>
                    <xsl:value-of select="ns1:CUSTOMER_CHAIN_TYPE"/>
                  </msg_in_out:CustomerChainType>
                </msg_in_out:Service2Customer>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "SHIP_TO") and ns1:CUST_ACCT_SITE_ID'>
                <msg_in_out:Service2Address>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TCACustAccntSiteId>
                    <xsl:value-of select="ns1:CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccntSiteId>
                  <msg_in_out:PartySiteNumber>
                    <xsl:value-of select="ns1:PARTY_SITE_NUMBER"/>
                  </msg_in_out:PartySiteNumber>
                  <msg_in_out:Name>
                    <xsl:value-of select='substring(concat(ns1:CITY,", ",ns1:ADDRESS1),1.0,60.0)'/>
                  </msg_in_out:Name>
                  <msg_in_out:IsInvoice2Address>
                    <xsl:text disable-output-escaping="no">true</xsl:text>
                  </msg_in_out:IsInvoice2Address>
                  <msg_in_out:GeographyLocation>
                    <msg_in_out:TcaLocationId>
                      <xsl:value-of select="ns1:LOCATION_ID"/>
                    </msg_in_out:TcaLocationId>
                    <msg_in_out:AddressLine1>
                      <xsl:value-of select="ns1:ADDRESS1"/>
                    </msg_in_out:AddressLine1>
                    <msg_in_out:AddressLine2>
                      <xsl:value-of select="ns1:ADDRESS2"/>
                    </msg_in_out:AddressLine2>
                    <msg_in_out:PostalCode>
                      <xsl:value-of select="ns1:POSTAL_CODE"/>
                    </msg_in_out:PostalCode>
                    <msg_in_out:CityName>
                      <xsl:value-of select="ns1:CITY"/>
                    </msg_in_out:CityName>
                    <xsl:if test="ns1:STATE">
                      <msg_in_out:Region>
                        <msg_in_out:Name>
                          <xsl:value-of select="ns1:STATE"/>
                        </msg_in_out:Name>
                        <msg_in_out:Country>
                          <msg_in_out:Code>
                            <xsl:value-of select="ns1:COUNTRY"/>
                          </msg_in_out:Code>
                        </msg_in_out:Country>
                      </msg_in_out:Region>
                    </xsl:if>
                    <msg_in_out:Country>
                      <msg_in_out:Code>
                        <xsl:value-of select="ns1:COUNTRY"/>
                      </msg_in_out:Code>
                    </msg_in_out:Country>
                  </msg_in_out:GeographyLocation>
                  <msg_in_out:Service2SiteUseId>
                    <xsl:value-of select="ns1:SITE_USE_ID"/>
                  </msg_in_out:Service2SiteUseId>
                </msg_in_out:Service2Address>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "SHIP_TO") and ns1:CONTACT_CUST_ACCT_ROLE_ID'>
                <msg_in_out:Service2Contact>
                  <msg_in_out:TCACustAccRoleId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                  </msg_in_out:TCACustAccRoleId>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Name>
                    <xsl:value-of select='concat(ns1:CONTACT_FIRST_NAME," ",ns1:CONTACT_LAST_NAME)'/>
                  </msg_in_out:Name>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:FirstName>
                    <xsl:value-of select="ns1:CONTACT_FIRST_NAME"/>
                  </msg_in_out:FirstName>
                  <msg_in_out:LastName>
                    <xsl:value-of select="ns1:CONTACT_LAST_NAME"/>
                  </msg_in_out:LastName>
                  <msg_in_out:Email>
                    <xsl:value-of select="ns1:CONTACT_EMAIL"/>
                  </msg_in_out:Email>
                  <msg_in_out:Phone>
                    <xsl:value-of select="ns1:CONTACT_PHONE"/>
                  </msg_in_out:Phone>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:CONTACT_PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCACustAccSiteId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccSiteId>
                </msg_in_out:Service2Contact>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='ns1:SITE_USE_TYPE = "END_USER"'>
                <msg_in_out:EndUserCustomer>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">0</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TcaCustAccountId>
                    <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                  </msg_in_out:TcaCustAccountId>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="ns1:CUST_ACCOUNT_NUMBER"/>
                  </msg_in_out:SearchKey>
                  <msg_in_out:Name>
                    <xsl:value-of select="ns1:PARTY_NAME"/>
                  </msg_in_out:Name>
                  <msg_in_out:CustomerEnglishName>
                    <xsl:value-of select="ns1:TRANSLATED_NAME"/>
                  </msg_in_out:CustomerEnglishName>
                  <msg_in_out:BusinessPartnerCategory>
                    <msg_in_out:SearchKey>
                      <xsl:text disable-output-escaping="no">CUSTOMER</xsl:text>
                    </msg_in_out:SearchKey>
                  </msg_in_out:BusinessPartnerCategory>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCAPartyNumber>
                    <xsl:value-of select="ns1:PARTY_NUMBER"/>
                  </msg_in_out:TCAPartyNumber>
                  <msg_in_out:IsChainCustomer>
                    <xsl:value-of select="ns1:IS_CHAIN_CUSTOMER"/>
                  </msg_in_out:IsChainCustomer>
                  <msg_in_out:IsPublicSector>
                    <xsl:value-of select="ns1:IS_PUBLIC_SECTOR"/>
                  </msg_in_out:IsPublicSector>
                   <msg_in_out:CustomerChainType>
                    <xsl:value-of select="ns1:CUSTOMER_CHAIN_TYPE"/>
                  </msg_in_out:CustomerChainType>
                </msg_in_out:EndUserCustomer>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "END_USER") and ns1:CUST_ACCT_SITE_ID'>
                <msg_in_out:EndUserAddress>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:TCACustAccntSiteId>
                    <xsl:value-of select="ns1:CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccntSiteId>
                  <msg_in_out:PartySiteNumber>
                    <xsl:value-of select="ns1:PARTY_SITE_NUMBER"/>
                  </msg_in_out:PartySiteNumber>
                  <msg_in_out:Name>
                    <xsl:value-of select='substring(concat(ns1:CITY,", ",ns1:ADDRESS1),1.0,60.0)'/>
                  </msg_in_out:Name>
                  <msg_in_out:IsInvoice2Address>
                    <xsl:text disable-output-escaping="no">false</xsl:text>
                  </msg_in_out:IsInvoice2Address>
                  <msg_in_out:GeographyLocation>
                    <msg_in_out:TcaLocationId>
                      <xsl:value-of select="ns1:LOCATION_ID"/>
                    </msg_in_out:TcaLocationId>
                    <msg_in_out:AddressLine1>
                      <xsl:value-of select="ns1:ADDRESS1"/>
                    </msg_in_out:AddressLine1>
                    <msg_in_out:AddressLine2>
                      <xsl:value-of select="ns1:ADDRESS2"/>
                    </msg_in_out:AddressLine2>
                    <msg_in_out:PostalCode>
                      <xsl:value-of select="ns1:POSTAL_CODE"/>
                    </msg_in_out:PostalCode>
                    <msg_in_out:CityName>
                      <xsl:value-of select="ns1:CITY"/>
                    </msg_in_out:CityName>
                    <xsl:if test="ns1:STATE">
                      <msg_in_out:Region>
                        <msg_in_out:Name>
                          <xsl:value-of select="ns1:STATE"/>
                        </msg_in_out:Name>
                        <msg_in_out:Country>
                          <msg_in_out:Code>
                            <xsl:value-of select="ns1:COUNTRY"/>
                          </msg_in_out:Code>
                        </msg_in_out:Country>
                      </msg_in_out:Region>
                    </xsl:if>
                    <msg_in_out:Country>
                      <msg_in_out:Code>
                        <xsl:value-of select="ns1:COUNTRY"/>
                      </msg_in_out:Code>
                    </msg_in_out:Country>
                  </msg_in_out:GeographyLocation>
                </msg_in_out:EndUserAddress>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <xsl:if test='(ns1:SITE_USE_TYPE = "END_USER") and ns1:CONTACT_CUST_ACCT_ROLE_ID'>
                <msg_in_out:EndUserContact>
                  <msg_in_out:TCACustAccRoleId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                  </msg_in_out:TCACustAccRoleId>
                  <msg_in_out:BusinessPartner>
                    <msg_in_out:TcaCustAccountId>
                      <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                    </msg_in_out:TcaCustAccountId>
                  </msg_in_out:BusinessPartner>
                  <msg_in_out:Name>
                    <xsl:value-of select='concat(ns1:CONTACT_FIRST_NAME," ",ns1:CONTACT_LAST_NAME)'/>
                  </msg_in_out:Name>
                  <msg_in_out:Org>
                    <msg_in_out:SearchKey>
                      <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                    </msg_in_out:SearchKey>
                  </msg_in_out:Org>
                  <msg_in_out:FirstName>
                    <xsl:value-of select="ns1:CONTACT_FIRST_NAME"/>
                  </msg_in_out:FirstName>
                  <msg_in_out:LastName>
                    <xsl:value-of select="ns1:CONTACT_LAST_NAME"/>
                  </msg_in_out:LastName>
                  <msg_in_out:Email>
                    <xsl:value-of select="ns1:CONTACT_EMAIL"/>
                  </msg_in_out:Email>
                  <msg_in_out:Phone>
                    <xsl:value-of select="ns1:CONTACT_PHONE"/>
                  </msg_in_out:Phone>
                  <msg_in_out:TCAPartyId>
                    <xsl:value-of select="ns1:CONTACT_PARTY_ID"/>
                  </msg_in_out:TCAPartyId>
                  <msg_in_out:TCACustAccSiteId>
                    <xsl:value-of select="ns1:CONTACT_CUST_ACCT_SITE_ID"/>
                  </msg_in_out:TCACustAccSiteId>
                </msg_in_out:EndUserContact>
              </xsl:if>
            </xsl:for-each>
            <msg_in_out:SalesRepresentative>
              <msg_in_out:Name>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SALESREP_NAME"/>
              </msg_in_out:Name>
              <msg_in_out:Org>
                <msg_in_out:SearchKey>
                  <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                </msg_in_out:SearchKey>
              </msg_in_out:Org>
              <msg_in_out:Email>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SALESREP_EMAIL"/>
              </msg_in_out:Email>
              <msg_in_out:BusinessPartner>
                <msg_in_out:Org>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                  </msg_in_out:SearchKey>
                </msg_in_out:Org>
                <msg_in_out:JTFSalesRepId>
                  <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PRIMARY_SALESREP_ID"/>
                </msg_in_out:JTFSalesRepId>
                <msg_in_out:SearchKey>
                  <xsl:value-of select='concat(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SALESREP_NUMBER,"-",/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID)'/>
                </msg_in_out:SearchKey>
                <msg_in_out:Name>
                  <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SALESREP_NAME"/>
                </msg_in_out:Name>
                <msg_in_out:IsSalesRepresentative>
                  <xsl:text disable-output-escaping="no">true</xsl:text>
                </msg_in_out:IsSalesRepresentative>
                <msg_in_out:IsCustomer>
                  <xsl:text disable-output-escaping="no">false</xsl:text>
                </msg_in_out:IsCustomer>
                <msg_in_out:BusinessPartnerCategory>
                  <msg_in_out:SearchKey>
                    <xsl:text disable-output-escaping="no">Employee</xsl:text>
                  </msg_in_out:SearchKey>
                </msg_in_out:BusinessPartnerCategory>
              </msg_in_out:BusinessPartner>
            </msg_in_out:SalesRepresentative>
            <msg_in_out:AgreementDate>
              <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_DATE"/>
            </msg_in_out:AgreementDate>
            <msg_in_out:StartDate>
              <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:START_DATE"/>
            </msg_in_out:StartDate>
            <msg_in_out:Duration>
              <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:DURATION"/>
            </msg_in_out:Duration>
            <msg_in_out:DurationUnit>
              <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:DURATION_UOM"/>
            </msg_in_out:DurationUnit>
            <xsl:choose>
              <xsl:when test='/ns1:MISIMD_SPM_SUBSCRIPTION[ns1:CONTRACT_TYPE="Cloud Evergreen Subscriptions"]/ns1:LINES/ns1:MISIMD_SPM_LINES[ns1:ITEM_TYPE_CODE = "SERVICE" and ns1:CLOUD_DATA_CENTER_REGION = "EXTSITE"]/ns1:CLOUD_DATA_CENTER_REGION'>
                <msg_in_out:SubscriptionSchedule>
                  <msg_in_out:Name>
                    <xsl:text disable-output-escaping="no">Pay In Full / Monthly Usage</xsl:text>
                  </msg_in_out:Name>
                </msg_in_out:SubscriptionSchedule>
              </xsl:when>
              <xsl:otherwise>
                <msg_in_out:SubscriptionSchedule>
                  <msg_in_out:Name>
                    <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:INVOICE_SCHEDULE"/>
                  </msg_in_out:Name>
                </msg_in_out:SubscriptionSchedule>
              </xsl:otherwise>
            </xsl:choose>
            <msg_in_out:IsAutomaticRenewal>
              <xsl:text disable-output-escaping="no">false</xsl:text>
            </msg_in_out:IsAutomaticRenewal>
            <xsl:choose>
              <xsl:when test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES/ns1:OVERAGE_BILLING_TERM'>
                <msg_in_out:OverageBillingTerm>
                  <xsl:value-of select='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES/ns1:OVERAGE_BILLING_TERM'/>
                </msg_in_out:OverageBillingTerm>
              </xsl:when>
              <xsl:otherwise>
                <msg_in_out:OverageBillingTerm>
                  <xsl:text disable-output-escaping="no">No Overage</xsl:text>
                </msg_in_out:OverageBillingTerm>
              </xsl:otherwise>
            </xsl:choose>
            <msg_in_out:PriceList>
              <msg_in_out:Name>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PRICE_LIST"/>
              </msg_in_out:Name>
              <msg_in_out:Currency>
                <msg_in_out:ISOCode>
                  <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CURRENCY"/>
                </msg_in_out:ISOCode>
              </msg_in_out:Currency>
            </msg_in_out:PriceList>
            <msg_in_out:Currency>
              <msg_in_out:ISOCode>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CURRENCY"/>
              </msg_in_out:ISOCode>
            </msg_in_out:Currency>
            <msg_in_out:PaymentTerms>
              <msg_in_out:SearchKey>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PAYMENT_TERMS_ID"/>
              </msg_in_out:SearchKey>
              <msg_in_out:Name>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PAYMENT_TERMS"/>
              </msg_in_out:Name>
              <msg_in_out:PaymentTermsDaysDue>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PAYMENT_TERMS_DAYS_DUE"/>
              </msg_in_out:PaymentTermsDaysDue>
            </msg_in_out:PaymentTerms>
            <msg_in_out:PaymentMethod>
              <msg_in_out:Name>
                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PAYMENT_METHOD"/>
              </msg_in_out:Name>
            </msg_in_out:PaymentMethod>
            <xsl:choose>
              <xsl:when test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES/ns1:OVERAGE_ENABLED = "Y"'>
                <msg_in_out:IsAllowOverage>
                  <xsl:text disable-output-escaping="no">Yes</xsl:text>
                </msg_in_out:IsAllowOverage>
              </xsl:when>
              <xsl:otherwise>
                <msg_in_out:IsAllowOverage>
                  <xsl:text disable-output-escaping="no">No</xsl:text>
                </msg_in_out:IsAllowOverage>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES/ns1:CSI'>
              <msg_in_out:CSI>
                <xsl:value-of select='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES/ns1:CSI'/>
              </msg_in_out:CSI>
            </xsl:if>
            <msg_in_out:ProjectCategory>
              <xsl:text disable-output-escaping="no">OBCNTR_CONTRACT</xsl:text>
            </msg_in_out:ProjectCategory>
            <xsl:if test="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SUPERSEDED_PROJECT">
              <msg_in_out:SupersededProject>
                <msg_in_out:SearchKey>
                  <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SUPERSEDED_PROJECT"/>
                </msg_in_out:SearchKey>
              </msg_in_out:SupersededProject>
            </xsl:if>
            <msg_in_out:RelatedGrpPlanIdf>
              <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:RELATED_GROUP_PLAN_ID"/>
            </msg_in_out:RelatedGrpPlanIdf>
            <msg_in_out:PlanClassification>
              <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:PLAN_CLASSIFICATION"/>
            </msg_in_out:PlanClassification>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES[ns1:CONTRACT_TYPE=../../ns1:CONTRACT_TYPE]">
              <msg_in_out:SubscribedService>
                <msg_in_out:Product>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="ns1:INV_PART_NUMBER"/>
                  </msg_in_out:SearchKey>
                </msg_in_out:Product>
                <msg_in_out:StartDate>
                  <xsl:value-of select="ns1:START_DATE"/>
                </msg_in_out:StartDate>
                <msg_in_out:EndDate>
                  <xsl:value-of select="ns1:END_DATE"/>
                </msg_in_out:EndDate>
                <msg_in_out:PricePeriod>
                  <xsl:value-of select="ns1:PRICE_PERIOD"/>
                </msg_in_out:PricePeriod>
                <msg_in_out:Quantity>
                  <xsl:value-of select="ns1:QUANTITY"/>
                </msg_in_out:Quantity>
                <msg_in_out:CommittedQuantity>
                  <xsl:value-of select="ns1:COMMITTED_QUANTITY"/>
                </msg_in_out:CommittedQuantity>
                <msg_in_out:NetUnitPrice>
                  <xsl:value-of select="ns1:CLOUD_FUTURE_MON_PRICE"/>
                </msg_in_out:NetUnitPrice>
                <xsl:choose>
                  <xsl:when test='(ns1:INV_CATEGORY = "CLDSUBSFEE") or (ns1:USAGE_BILLING = "A") or (ns1:USAGE_BILLING = "METERED_OVERAGE")'>
                    <msg_in_out:IsAllowance>
                      <xsl:text disable-output-escaping="no">false</xsl:text>
                    </msg_in_out:IsAllowance>
                  </xsl:when>
                  <xsl:otherwise>
                    <msg_in_out:IsAllowance>
                      <xsl:text disable-output-escaping="no">true</xsl:text>
                    </msg_in_out:IsAllowance>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="ns1:ALLOWANCE_SPLIT_DURATION_UOM">
                  <msg_in_out:SplitQty>
                    <xsl:value-of select="ns1:ALLOWANCE_SPLIT_DURATION"/>
                  </msg_in_out:SplitQty>
                </xsl:if>
                <xsl:if test="ns1:ALLOWANCE_SPLIT_DURATION_UOM">
                  <msg_in_out:SplitUOM>
                    <xsl:value-of select="ns1:ALLOWANCE_SPLIT_DURATION_UOM"/>
                  </msg_in_out:SplitUOM>
                </xsl:if>
                <msg_in_out:TCLV>
                  <xsl:value-of select="ns1:TCLV"/>
                </msg_in_out:TCLV>
                <msg_in_out:Cap2Pricelist>
                  <xsl:value-of select="ns1:CAP_TO_PRICELIST"/>
                </msg_in_out:Cap2Pricelist>
                <xsl:choose>
                  <xsl:when test='ns1:USAGE_BILLING = "METERED_OVERAGE"'>
                    <msg_in_out:OveragePolicy>
                      <xsl:text disable-output-escaping="no">BOPL</xsl:text>
                    </msg_in_out:OveragePolicy>
                  </xsl:when>
                  <xsl:otherwise>
                    <msg_in_out:OveragePolicy>
                      <xsl:value-of select="ns1:OVERAGE_POLICY"/>
                    </msg_in_out:OveragePolicy>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="string(ns1:DEPLOYMENT_TYPE)">
                  <msg_in_out:DeploymentType>
                    <xsl:value-of select="ns1:DEPLOYMENT_TYPE"/>
                  </msg_in_out:DeploymentType>
                </xsl:if>
                <xsl:if test="string(ns1:COMMIT_MODEL)">
                  <msg_in_out:PricingModel>
                    <xsl:value-of select="ns1:COMMIT_MODEL"/>
                  </msg_in_out:PricingModel>
                </xsl:if>
                <xsl:if test="string(ns1:DEPLOYMENT_NAME)">
                  <msg_in_out:DeploymentName>
                    <xsl:value-of select="ns1:DEPLOYMENT_NAME"/>
                  </msg_in_out:DeploymentName>
                </xsl:if>
                <xsl:if test="string(ns1:INTENT_TO_PAY)">
                  <msg_in_out:IntentToPay>
                    <xsl:value-of select="ns1:INTENT_TO_PAY"/>
                  </msg_in_out:IntentToPay>
                </xsl:if>
                <xsl:if test="string(ns1:OVERAGE_DISCOUNT_PRCNT)">
                  <msg_in_out:OverageDiscountPercentage>
                    <xsl:value-of select="ns1:OVERAGE_DISCOUNT_PRCNT"/>
                  </msg_in_out:OverageDiscountPercentage>
                </xsl:if>
                <!--START -->
                <!--SPM-6780 ,SPM-9560 , SPM-10101 -->
                <xsl:if test="string(ns1:PARTNER_CREDIT_VALUE)">
                  <msg_in_out:PartnerCreditValue>
                    <xsl:value-of select="ns1:PARTNER_CREDIT_VALUE"/>
                  </msg_in_out:PartnerCreditValue>
                </xsl:if>
                <xsl:if test="string(ns1:ASSC_REV_SUBSC_MAP)">
                  <msg_in_out:AssociatedRevenueSubscriptionMap>
                    <xsl:value-of select="ns1:ASSC_REV_SUBSC_MAP"/>
                  </msg_in_out:AssociatedRevenueSubscriptionMap>
                </xsl:if>
                <msg_in_out:ProvisioningSource>
                  <msg_in_out:SourceHeader>
                    <msg_in_out:Value>SPM_PROVISIONING_SOURCE</msg_in_out:Value>
                  </msg_in_out:SourceHeader>
                  <msg_in_out:Value>
                    <xsl:value-of select="ns1:PROVISIONING_SOURCE"/>
                  </msg_in_out:Value>
                </msg_in_out:ProvisioningSource>
                <xsl:if test='ns1:PROVISIONING_SOURCE = "SPM"'>
                  <msg_in_out:CompRepsList>
                    <xsl:value-of select="ns1:COMP_SALES_REP"/>
                  </msg_in_out:CompRepsList>
                </xsl:if>
                <xsl:if test="string(ns1:COMMIT_SCHEDULE)">
                  <msg_in_out:CommitScheduleId>
                    <xsl:value-of select="ns1:COMMIT_SCHEDULE"/>
                  </msg_in_out:CommitScheduleId>
                </xsl:if>
                <xsl:if test="string(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:REKEY_TYPE)">
                  <msg_in_out:RekeyType>
                    <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:REKEY_TYPE"/>
                  </msg_in_out:RekeyType>
                </xsl:if>
                <!--SPM-6780 ,SPM-9560 , SPM-10101 -->
                <!-- END-->
                <!--Changes for SPM-9570 - SPMPROV START -->
                <xsl:if test="string(ns1:CLOUD_PROVISION_SEQ_NUM)">
                  <msg_in_out:ProvSequenceNumber>
                    <xsl:value-of select="ns1:CLOUD_PROVISION_SEQ_NUM"/>
                  </msg_in_out:ProvSequenceNumber>
                </xsl:if>
                <xsl:if test="string(ns1:CLOUD_PO_TERM)">
                  <msg_in_out:CloudPoTerm>
                    <xsl:value-of select="ns1:CLOUD_PO_TERM"/>
                  </msg_in_out:CloudPoTerm>
                </xsl:if>
                <xsl:if test="string(ns1:CLOUD_BACK_DATED_CONTRACT)">
                  <msg_in_out:CloudBackDatedContract>
                    <xsl:value-of select="ns1:CLOUD_BACK_DATED_CONTRACT"/>
                  </msg_in_out:CloudBackDatedContract>
                </xsl:if>
                <xsl:if test="string(ns1:CLOUD_STORE_SSO_USERNAME)">
                  <msg_in_out:CloudStoreSsoUsername>
                    <xsl:value-of select="ns1:CLOUD_STORE_SSO_USERNAME"/>
                  </msg_in_out:CloudStoreSsoUsername>
                </xsl:if>
                <xsl:if test="string(ns1:CLOUD_REF_SUBSCRIPTION_ID)">
                  <msg_in_out:CloudRefSubscription>
                    <xsl:value-of select="ns1:CLOUD_REF_SUBSCRIPTION_ID"/>
                  </msg_in_out:CloudRefSubscription>
                </xsl:if>
                <xsl:if test="string(ns1:CUSTOMERS_CRM_CHOICE)">
                  <msg_in_out:CustomersCrmChoice>
                    <xsl:value-of select="ns1:CUSTOMERS_CRM_CHOICE"/>
                  </msg_in_out:CustomersCrmChoice>
                </xsl:if>
                <xsl:if test="string(ns1:ADMIN_FIRST_NAME)">
                  <msg_in_out:AdminFirstName>
                    <xsl:value-of select="ns1:ADMIN_FIRST_NAME"/>
                  </msg_in_out:AdminFirstName>
                </xsl:if>
                <xsl:if test="string(ns1:ADMIN_LAST_NAME)">
                  <msg_in_out:AdminLastName>
                    <xsl:value-of select="ns1:ADMIN_LAST_NAME"/>
                  </msg_in_out:AdminLastName>
                </xsl:if>
                <xsl:if test="string(ns1:CUSTOMER_CODE)">
                  <msg_in_out:CustomerCode>
                    <xsl:value-of select="ns1:CUSTOMER_CODE"/>
                  </msg_in_out:CustomerCode>
                </xsl:if>
                <xsl:if test="string(ns1:LANGUAGE_PACK)">
                  <msg_in_out:LanguagePack>
                    <xsl:value-of select="ns1:LANGUAGE_PACK"/>
                  </msg_in_out:LanguagePack>
                </xsl:if>
                <xsl:if test="string(ns1:TALEO_CONSULTING_METHODOLOGY)">
                  <msg_in_out:TaleoConsultingMethod>
                    <xsl:value-of select="ns1:TALEO_CONSULTING_METHODOLOGY"/>
                  </msg_in_out:TaleoConsultingMethod>
                </xsl:if>
                <xsl:if test="string(ns1:AUTO_CLOSE_FOR_PROVISIONING)">
                  <msg_in_out:AutoCloseForProv>
                    <xsl:value-of select="ns1:AUTO_CLOSE_FOR_PROVISIONING"/>
                  </msg_in_out:AutoCloseForProv>
                </xsl:if>
                <xsl:if test="string(ns1:CHANNEL_OPTION)">
                  <msg_in_out:ChannelOption>
                    <xsl:value-of select="ns1:CHANNEL_OPTION"/>
                  </msg_in_out:ChannelOption>
                </xsl:if>
                <xsl:if test="string(ns1:PARTNER_ID)">
                  <msg_in_out:Partner>
                    <xsl:value-of select="ns1:PARTNER_ID"/>
                  </msg_in_out:Partner>
                </xsl:if>
                <xsl:if test="string(ns1:RAVELLO_TOKEN_ID)">
                  <msg_in_out:RavelloToken>
                    <xsl:value-of select="ns1:RAVELLO_TOKEN_ID"/>
                  </msg_in_out:RavelloToken>
                </xsl:if>
                <!--Changes for SPM-9570 - SPMPROV END   -->
                <xsl:if test="string(ns1:PILOT_TYPE)">
                  <msg_in_out:PilotType>
                    <xsl:value-of select="ns1:PILOT_TYPE"/>
                  </msg_in_out:PilotType>
                </xsl:if>
                <xsl:if test="string(ns1:FIXED_END_DATE_FLAG)">
                  <msg_in_out:FixedEndDate>
                    <xsl:value-of select="ns1:FIXED_END_DATE_FLAG"/>
                  </msg_in_out:FixedEndDate>
                </xsl:if>
                <xsl:if test="string(ns1:NCER_ZONE)">
                  <msg_in_out:NcerZone>
                    <xsl:value-of select="ns1:NCER_ZONE"/>
                  </msg_in_out:NcerZone>
                </xsl:if>
                <xsl:if test="string(ns1:NCER_TYPE)">
                  <msg_in_out:NcerType>
                    <xsl:value-of select="ns1:NCER_TYPE"/>
                  </msg_in_out:NcerType>
                </xsl:if>
                <xsl:if test="string(ns1:SPECIAL_HANDLING_FLAG)">
                  <msg_in_out:spmProvisioningSpecialHandling>
                    <xsl:value-of select="ns1:SPECIAL_HANDLING_FLAG"/>
                  </msg_in_out:spmProvisioningSpecialHandling>
                </xsl:if>
                <xsl:if test="string(ns1:LINE_OF_BUSINESS)">
                  <msg_in_out:LineOfBusiness>
                    <xsl:value-of select="ns1:LINE_OF_BUSINESS"/>
                  </msg_in_out:LineOfBusiness>
                </xsl:if>
                <xsl:if test="string(ns1:TEXTURA_TOKEN_ID)">
                  <msg_in_out:TexturaTokenID>
                    <xsl:value-of select="ns1:TEXTURA_TOKEN_ID"/>
                  </msg_in_out:TexturaTokenID>
                </xsl:if>
                <xsl:if test="string(ns1:APIARY_TOKEN_ID)">
                  <msg_in_out:ApiaryToken>
                    <xsl:value-of select="ns1:APIARY_TOKEN_ID"/>
                  </msg_in_out:ApiaryToken>
                </xsl:if>
                <xsl:if test="string(ns1:CUSTOMER_READINESS_DATE)">
                  <msg_in_out:CustomerReadinessDate>
                    <xsl:value-of select="ns1:CUSTOMER_READINESS_DATE"/>
                  </msg_in_out:CustomerReadinessDate>
                </xsl:if>
                <xsl:if test="string(ns1:DEDICATED_COMPUTE_CAPACITY)">
                  <msg_in_out:DedicatedComputeCapacity>
                    <xsl:value-of select="ns1:DEDICATED_COMPUTE_CAPACITY"/>
                  </msg_in_out:DedicatedComputeCapacity>
                </xsl:if>
                <xsl:if test="string(ns1:ESTIMATED_PROV_DATE)">
                  <msg_in_out:EstimatedProvDate>
                    <xsl:value-of select="ns1:ESTIMATED_PROV_DATE"/>
                  </msg_in_out:EstimatedProvDate>
                </xsl:if>
                <xsl:if test="string(ns1:AGREEMENT_ID)">
                  <msg_in_out:AgreementId>
                    <xsl:value-of select="ns1:AGREEMENT_ID"/>
                  </msg_in_out:AgreementId>
                </xsl:if>
                <xsl:if test="string(ns1:COST_CENTER)">
                  <msg_in_out:CostCenterId>
                    <xsl:value-of select="ns1:COST_CENTER"/>
                  </msg_in_out:CostCenterId>
                </xsl:if>
                <xsl:if test="string(ns1:COST_CENTER_DESCRIPTION)">
                  <msg_in_out:CostCenterName>
                    <xsl:value-of select="ns1:COST_CENTER_DESCRIPTION"/>
                  </msg_in_out:CostCenterName>
                </xsl:if>
                <xsl:if test="string(ns1:PROGRAM_TYPE)">
                  <msg_in_out:ProgramType>
                    <xsl:value-of select="ns1:PROGRAM_TYPE"/>
                  </msg_in_out:ProgramType>
                </xsl:if>
                <xsl:if test="string(ns1:AGREEMENT_NAME)">
                  <msg_in_out:AgreementName>
                    <xsl:value-of select="ns1:AGREEMENT_NAME"/>
                  </msg_in_out:AgreementName>
                </xsl:if>
                <xsl:if test="string(ns1:ORIGINAL_SUB_IDS)">
                  <msg_in_out:OriginalSubIDs>
                    <xsl:value-of select="ns1:ORIGINAL_SUB_IDS"/>
                  </msg_in_out:OriginalSubIDs>
                </xsl:if>
                <xsl:if test="string(ns1:SALES_SCENARIO)">
                  <msg_in_out:SalesScenario>
                    <xsl:value-of select="ns1:SALES_SCENARIO"/>
                  </msg_in_out:SalesScenario>
                </xsl:if>
                <xsl:if test="string(ns1:AGREEMENT_END_DATE)">
                  <msg_in_out:AgreementEndDate>
                    <xsl:value-of select="ns1:AGREEMENT_END_DATE"/>
                  </msg_in_out:AgreementEndDate>
                </xsl:if>
                <xsl:if test="string(ns1:ULA2PAAS)">
                  <msg_in_out:ULA2PaaS>
                    <xsl:value-of select="ns1:ULA2PAAS"/>
                  </msg_in_out:ULA2PaaS>
                </xsl:if>
                <xsl:if test="string(ns1:ULAORDER)">
                  <msg_in_out:ULAOrder>
                    <xsl:value-of select="ns1:ULAORDER"/>
                  </msg_in_out:ULAOrder>
                </xsl:if>
                <xsl:if test="string(ns1:CREDIT4_REPUR_SUPP)">
                  <msg_in_out:Credit4RepurposedSupport>
                    <xsl:value-of select="ns1:CREDIT4_REPUR_SUPP"/>
                  </msg_in_out:Credit4RepurposedSupport>
                </xsl:if>
                <xsl:if test="string(ns1:IS_SYNC_START_DATE)">
                  <msg_in_out:IsSyncStartDate>
                    <xsl:value-of select="ns1:IS_SYNC_START_DATE"/>
                  </msg_in_out:IsSyncStartDate>
                </xsl:if>
                <xsl:if test="string(ns1:START_DATE_TYPE)">
                  <msg_in_out:StartDateType>
                    <xsl:value-of select="ns1:START_DATE_TYPE"/>
                  </msg_in_out:StartDateType>
                </xsl:if>
                <msg_in_out:OveragePrice>
                  <xsl:value-of select="ns1:OVERAGE_PRICE"/>
                </msg_in_out:OveragePrice>
                <msg_in_out:OperationType>
                  <xsl:value-of select="ns1:OPERATION_TYPE"/>
                </msg_in_out:OperationType>
                <xsl:if test="ns1:PROMOTION_TYPE != '0'">
                  <msg_in_out:IsDonotGenInvLines>
                    <xsl:text disable-output-escaping="no">true</xsl:text>
                  </msg_in_out:IsDonotGenInvLines>
                </xsl:if>
                <msg_in_out:PONumber>
                  <xsl:value-of select="../../ns1:PO_NUMBER"/>
                </msg_in_out:PONumber>
                <msg_in_out:POExpiryDate>
                  <xsl:value-of select="ns1:PO_EXPIRY_DATE"/>
                </msg_in_out:POExpiryDate>
                <msg_in_out:TrxnExtensionId>
                  <xsl:value-of select="../../ns1:CC_TOKEN_REF"/>
                </msg_in_out:TrxnExtensionId>
                <msg_in_out:CCExpiryDate>
                  <xsl:value-of select="../../ns1:CC_EXPIRY_DATE"/>
                </msg_in_out:CCExpiryDate>
                <msg_in_out:SalesChannel>
                  <xsl:value-of select="../../ns1:SALES_CHANNEL"/>
                </msg_in_out:SalesChannel>
                <msg_in_out:OrderSource>
                  <msg_in_out:SearchKey>
                    <xsl:value-of select="../../ns1:ORDER_SOURCE"/>
                  </msg_in_out:SearchKey>
                  <msg_in_out:Name>
                    <xsl:value-of select="../../ns1:ORDER_SOURCE"/>
                  </msg_in_out:Name>
                </msg_in_out:OrderSource>
                <xsl:choose>
                  <xsl:when test="ns1:SPMIST4C">
                    <msg_in_out:IsT4C>
                      <xsl:text disable-output-escaping="no">true</xsl:text>
                    </msg_in_out:IsT4C>
                  </xsl:when>
                  <xsl:otherwise>
                    <msg_in_out:IsT4C>
                      <xsl:text disable-output-escaping="no">false</xsl:text>
                    </msg_in_out:IsT4C>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="ns1:SPMIST4C">
                  <msg_in_out:T4CDate>
                    <xsl:value-of select="ns1:SPMIST4C"/>
                  </msg_in_out:T4CDate>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test="ns1:PROMOTION_TYPE != '0'">
                    <msg_in_out:IsEligible2Renew>
                      <xsl:text disable-output-escaping="no">N</xsl:text>
                    </msg_in_out:IsEligible2Renew>
                  </xsl:when>
                  <xsl:otherwise>
                    <msg_in_out:IsEligible2Renew>
                      <xsl:value-of select="ns1:CLOUD_RENEWAL_FLAG"/>
                    </msg_in_out:IsEligible2Renew>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test='ns1:SPM_OLD_LINE_ID != "0"'>
                  <msg_in_out:RenewedLine>
                    <msg_in_out:ID>
                      <xsl:value-of select="ns1:SPM_OLD_LINE_ID"/>
                    </msg_in_out:ID>
                  </msg_in_out:RenewedLine>
                </xsl:if>
                <msg_in_out:TranslatedDescription>
                  <xsl:value-of select="ns1:USER_ITEM_DESCRIPTION"/>
                </msg_in_out:TranslatedDescription>
                <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
                  <xsl:if test='ns1:SITE_USE_TYPE = "BILL_TO"'>
                    <msg_in_out:Bill2Customer>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:text disable-output-escaping="no">0</xsl:text>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:TcaCustAccountId>
                        <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                      </msg_in_out:TcaCustAccountId>
                      <msg_in_out:SearchKey>
                        <xsl:value-of select="ns1:CUST_ACCOUNT_NUMBER"/>
                      </msg_in_out:SearchKey>
                      <msg_in_out:Name>
                        <xsl:value-of select="ns1:PARTY_NAME"/>
                      </msg_in_out:Name>
                      <msg_in_out:CustomerEnglishName>
                        <xsl:value-of select="ns1:TRANSLATED_NAME"/>
                      </msg_in_out:CustomerEnglishName>
                      <msg_in_out:BusinessPartnerCategory>
                        <msg_in_out:SearchKey>
                          <xsl:text disable-output-escaping="no">CUSTOMER</xsl:text>
                        </msg_in_out:SearchKey>
                      </msg_in_out:BusinessPartnerCategory>
                      <msg_in_out:TCAPartyId>
                        <xsl:value-of select="ns1:PARTY_ID"/>
                      </msg_in_out:TCAPartyId>
                      <msg_in_out:TCAPartyNumber>
                        <xsl:value-of select="ns1:PARTY_NUMBER"/>
                      </msg_in_out:TCAPartyNumber>
                    </msg_in_out:Bill2Customer>
                  </xsl:if>
                </xsl:for-each>
                <xsl:if test='ns1:INV_CATEGORY = "CLDSUBSFEE"'>
                  <msg_in_out:IsOneTimeConfig>
                    <xsl:text disable-output-escaping="no">true</xsl:text>
                  </msg_in_out:IsOneTimeConfig>
                </xsl:if>
                <msg_in_out:OrderHeaderId>
                  <xsl:value-of select="../../ns1:ORDER_HEADER_ID"/>
                </msg_in_out:OrderHeaderId>
                <msg_in_out:OrderNumber>
                  <xsl:value-of select="../../ns1:ORDER_NUMBER"/>
                </msg_in_out:OrderNumber>
                <msg_in_out:OrderLineId>
                  <xsl:value-of select="ns1:ORDER_LINE_ID"/>
                </msg_in_out:OrderLineId>
                <msg_in_out:BaseOrderLineId>
                  <xsl:value-of select="ns1:BASE_ORDER_LINE_ID"/>
                </msg_in_out:BaseOrderLineId>
                <msg_in_out:OrderLineNumber>
                  <xsl:value-of select="ns1:ORDER_LINE_NUMBER"/>
                </msg_in_out:OrderLineNumber>
                <msg_in_out:RateCardId>
                  <xsl:value-of select="ns1:BOM_COMPONENTS/ns1:MISIMD_SPM_BOM_COMPONENT[1]/ns1:RATE_CARD_ID"/>
                </msg_in_out:RateCardId>
                <msg_in_out:SalesAccNumber>
                  <xsl:value-of select="../../ns1:CRM_TARGET_PARTY_ID"/>
                </msg_in_out:SalesAccNumber>
                <msg_in_out:SubscriptionId>
                  <xsl:value-of select="ns1:SUBSCRIPTION_ID"/>
                </msg_in_out:SubscriptionId>
                <msg_in_out:OPCAccNumber>
                  <xsl:value-of select="ns1:OPC_CUSTOMER_NAME"/>
                </msg_in_out:OPCAccNumber>
                <msg_in_out:DataCentre>
                  <xsl:value-of select="ns1:CLOUD_DATA_CENTER_REGION"/>
                </msg_in_out:DataCentre>
                <msg_in_out:DataCenterRegion>
                  <msg_in_out:Value>
                    <xsl:value-of select="ns1:CLOUD_DATA_CENTER_REGION"/>
                  </msg_in_out:Value>
                  <msg_in_out:Meaning>
                    <xsl:value-of select="ns1:CLOUD_DATA_CENTER_REGION_M"/>
                  </msg_in_out:Meaning>
                  <msg_in_out:Lookup>
                    <msg_in_out:Type>SPM_DATA_CENTER_REGION</msg_in_out:Type>
                  </msg_in_out:Lookup>
                </msg_in_out:DataCenterRegion>
                <msg_in_out:ProvisioningDate>
                  <xsl:value-of select="ns1:PROVISIONING_DATE"/>
                </msg_in_out:ProvisioningDate>
                <msg_in_out:AdminEmail>
                  <xsl:value-of select="ns1:CLOUD_ACC_ADMIN_EMAIL"/>
                </msg_in_out:AdminEmail>
                <msg_in_out:IsTopLevel>
                  <xsl:text disable-output-escaping="no">true</xsl:text>
                </msg_in_out:IsTopLevel>
                <xsl:choose>
                  <xsl:when test="count(ns1:ENTITLEMENT_COMPONENTS/ns1:MISIMD_SPM_ENT_COMPONENT) > 0.0">
                    <msg_in_out:HasEntitlements>
                      <xsl:text disable-output-escaping="no">true</xsl:text>
                    </msg_in_out:HasEntitlements>
                  </xsl:when>
                  <xsl:otherwise>
                    <msg_in_out:HasEntitlements>
                      <xsl:text disable-output-escaping="no">false</xsl:text>
                    </msg_in_out:HasEntitlements>
                  </xsl:otherwise>
                </xsl:choose>
                <msg_in_out:OpportunityNumber>
                  <xsl:value-of select="../../ns1:CRM_OPTY_NUM"/>
                </msg_in_out:OpportunityNumber>
                <msg_in_out:HasPromotion>
                  <xsl:value-of select="ns1:HAS_PROMOTION"/>
                </msg_in_out:HasPromotion>
                <msg_in_out:IsRebalance>
                  <xsl:value-of select="ns1:REBALANCE_OPTED"/>
                </msg_in_out:IsRebalance>
                <msg_in_out:FulfillmentSet>
                  <xsl:value-of select="ns1:FULFILLMENT_SET"/>
                </msg_in_out:FulfillmentSet>
                <msg_in_out:ReplacementReason>
                  <xsl:value-of select="ns1:REPLACE_REASON_CODE"/>
                </msg_in_out:ReplacementReason>
                <msg_in_out:SupersedeNotes>
                  <xsl:value-of select="ns1:SUPERSEDE_NOTES"/>
                </msg_in_out:SupersedeNotes>
                <msg_in_out:ReplaceSubscriptionId>
                  <xsl:value-of select="ns1:REPLACE_SUBSCRIPTION_ID"/>
                </msg_in_out:ReplaceSubscriptionId>
                <msg_in_out:SupersededSet>
                  <xsl:value-of select="ns1:SUPERSEDED_SET_ID"/>
                </msg_in_out:SupersededSet>
                <msg_in_out:OrderType>
                  <xsl:value-of select="../../ns1:ORDER_TYPE"/>
                </msg_in_out:OrderType>
                <xsl:if test='ns1:USAGE_BILLING = "METERED_OVERAGE"'>
                  <msg_in_out:IsBurstingEnabled>
                    <xsl:text disable-output-escaping="no">true</xsl:text>
                  </msg_in_out:IsBurstingEnabled>
                </xsl:if>
                <msg_in_out:BuyerEmail>
                  <xsl:value-of select="../../ns1:BUYER_EMAIL_ID"/>
                </msg_in_out:BuyerEmail>
                <msg_in_out:ParentLineId>
                  <xsl:value-of select="ns1:PARENT_LINE_ID"/>
                </msg_in_out:ParentLineId>
                <msg_in_out:IsUnified>
                  <xsl:value-of select="ns1:IS_UNIFIED"/>
                </msg_in_out:IsUnified>
                <msg_in_out:UnifiedRevenueQuota>
                  <xsl:value-of select="ns1:UNIFIED_REVENUE_QUOTA"/>
                </msg_in_out:UnifiedRevenueQuota>
                <msg_in_out:UnifiedRevenueAmount>
                  <xsl:value-of select="ns1:UNIFIED_REVENUE_AMOUNT"/>
                </msg_in_out:UnifiedRevenueAmount>
                <xsl:if test="string(ns1:RENEWAL)">
                  <msg_in_out:Renewal>
                    <xsl:value-of select="ns1:RENEWAL"/>
                  </msg_in_out:Renewal>
                </xsl:if>
                <xsl:if test="string(ns1:UPSELL)">
                  <msg_in_out:Upsell>
                    <xsl:value-of select="ns1:UPSELL"/>
                  </msg_in_out:Upsell>
                </xsl:if>
                <xsl:if test="string(ns1:CROSSSELL)">
                  <msg_in_out:Cross-Sell>
                    <xsl:value-of select="ns1:CROSSSELL"/>
                  </msg_in_out:Cross-Sell>
                </xsl:if>
                <xsl:if test="string(ns1:DOWNSELL)">
                  <msg_in_out:Downsell>
                    <xsl:value-of select="ns1:DOWNSELL"/>
                  </msg_in_out:Downsell>
                </xsl:if>
                <msg_in_out:CloudAccountID>
                  <xsl:value-of select="ns1:CLOUD_ACCOUNT_ID"/>
                </msg_in_out:CloudAccountID>
                <msg_in_out:CloudAccountName>
                  <xsl:value-of select="ns1:CLOUD_ACCOUNT_NAME"/>
                </msg_in_out:CloudAccountName>
                <msg_in_out:AssociateSubId>
                  <xsl:value-of select="ns1:ASSOCIATE_SUB_ID"/>
                </msg_in_out:AssociateSubId>
                <xsl:if test="ns1:PROMOTION_TYPE != '0'">
                  <msg_in_out:OriginalPromoAmt>
                    <xsl:value-of select="ns1:ORIGINAL_PROMO_AMT"/>
                  </msg_in_out:OriginalPromoAmt>
                </xsl:if>
                <xsl:if test="(ns1:PROMOTION_TYPE = '0') and (ns1:PROMOTION_ORDER = 'Y')">
                  <msg_in_out:PromoOrderRefLineId>
                    <xsl:value-of select="ns1:PARENT_LINE_ID"/>
                  </msg_in_out:PromoOrderRefLineId>
                </xsl:if>
                <xsl:if test="ns1:PROMOTION_TYPE != '0'">
                  <msg_in_out:PromotionType>
                    <xsl:value-of select="ns1:PROMOTION_TYPE"/>
                  </msg_in_out:PromotionType>
                </xsl:if>
                <xsl:if test="string(ns1:PROMOTION_TYPE_VAL)">
                  <msg_in_out:PromotionTypeVal>
                    <xsl:value-of select="ns1:PROMOTION_TYPE_VAL"/>
                  </msg_in_out:PromotionTypeVal>
                </xsl:if>
                <ns1:IsCreditEnabled>
                  <xsl:choose>
                    <xsl:when test="not(string(ns1:IS_CREDIT_ENABLED))">
                      <xsl:text disable-output-escaping="no">false</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="ns1:IS_CREDIT_ENABLED"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </ns1:IsCreditEnabled>
                <ns1:CreditPercentage>
                  <xsl:value-of select="ns1:CREDIT_PERCENTAGE"/>
                </ns1:CreditPercentage>
                <xsl:if test="ns1:OVERAGE_BILL_TO">
                  <ns1:OverageBillTo>
                    <xsl:value-of select="ns1:OVERAGE_BILL_TO"/>
                  </ns1:OverageBillTo>
                </xsl:if>
                <ns1:PartnerTransactionType>
                  <xsl:value-of select="ns1:PARTNER_TRANSACTION_TYPE"/>
                </ns1:PartnerTransactionType>
                <ns1:SubscriptionDiscountPercentage>
                  <xsl:value-of select="ns1:RATE_CARD_DIS_PER"/>
                </ns1:SubscriptionDiscountPercentage>
                <xsl:if test="ns1:PAYG_POLICY">
                  <ns1:PayAsYouGoPolicy>
                    <xsl:value-of select="ns1:PAYG_POLICY"/>
                  </ns1:PayAsYouGoPolicy>
                </xsl:if>
                <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
                  <xsl:if test='(ns1:SITE_USE_TYPE = "BILL_TO") and ns1:CUST_ACCT_SITE_ID'>
                    <msg_in_out:Bill2Address>
                      <msg_in_out:BusinessPartner>
                        <msg_in_out:TcaCustAccountId>
                          <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                        </msg_in_out:TcaCustAccountId>
                      </msg_in_out:BusinessPartner>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:TCACustAccntSiteId>
                        <xsl:value-of select="ns1:CUST_ACCT_SITE_ID"/>
                      </msg_in_out:TCACustAccntSiteId>
                      <msg_in_out:PartySiteNumber>
                        <xsl:value-of select="ns1:PARTY_SITE_NUMBER"/>
                      </msg_in_out:PartySiteNumber>
                      <msg_in_out:Name>
                        <xsl:value-of select='substring(concat(ns1:CITY,", ",ns1:ADDRESS1),1.0,60.0)'/>
                      </msg_in_out:Name>
                      <msg_in_out:IsInvoice2Address>
                        <xsl:text disable-output-escaping="no">true</xsl:text>
                      </msg_in_out:IsInvoice2Address>
                      <msg_in_out:GeographyLocation>
                        <msg_in_out:TcaLocationId>
                          <xsl:value-of select="ns1:LOCATION_ID"/>
                        </msg_in_out:TcaLocationId>
                        <msg_in_out:AddressLine1>
                          <xsl:value-of select="ns1:ADDRESS1"/>
                        </msg_in_out:AddressLine1>
                        <msg_in_out:AddressLine2>
                          <xsl:value-of select="ns1:ADDRESS2"/>
                        </msg_in_out:AddressLine2>
                        <msg_in_out:PostalCode>
                          <xsl:value-of select="ns1:POSTAL_CODE"/>
                        </msg_in_out:PostalCode>
                        <msg_in_out:CityName>
                          <xsl:value-of select="ns1:CITY"/>
                        </msg_in_out:CityName>
                        <xsl:if test="ns1:STATE">
                          <msg_in_out:Region>
                            <msg_in_out:Name>
                              <xsl:value-of select="ns1:STATE"/>
                            </msg_in_out:Name>
                            <msg_in_out:Country>
                              <msg_in_out:Code>
                                <xsl:value-of select="ns1:COUNTRY"/>
                              </msg_in_out:Code>
                            </msg_in_out:Country>
                          </msg_in_out:Region>
                        </xsl:if>
                        <msg_in_out:Country>
                          <msg_in_out:Code>
                            <xsl:value-of select="ns1:COUNTRY"/>
                          </msg_in_out:Code>
                        </msg_in_out:Country>
                      </msg_in_out:GeographyLocation>
                      <msg_in_out:Bill2SiteUseId>
                        <xsl:value-of select="ns1:SITE_USE_ID"/>
                      </msg_in_out:Bill2SiteUseId>
                    </msg_in_out:Bill2Address>
                  </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
                  <xsl:if test='(ns1:SITE_USE_TYPE = "BILL_TO") and ns1:CONTACT_CUST_ACCT_ROLE_ID'>
                    <msg_in_out:BillingContact>
                      <msg_in_out:TCACustAccRoleId>
                        <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                      </msg_in_out:TCACustAccRoleId>
                      <msg_in_out:BusinessPartner>
                        <msg_in_out:TcaCustAccountId>
                          <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                        </msg_in_out:TcaCustAccountId>
                      </msg_in_out:BusinessPartner>
                      <msg_in_out:Name>
                        <xsl:value-of select='concat(ns1:CONTACT_FIRST_NAME," ",ns1:CONTACT_LAST_NAME)'/>
                      </msg_in_out:Name>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:FirstName>
                        <xsl:value-of select="ns1:CONTACT_FIRST_NAME"/>
                      </msg_in_out:FirstName>
                      <msg_in_out:LastName>
                        <xsl:value-of select="ns1:CONTACT_LAST_NAME"/>
                      </msg_in_out:LastName>
                      <msg_in_out:Email>
                        <xsl:value-of select="ns1:CONTACT_EMAIL"/>
                      </msg_in_out:Email>
                      <msg_in_out:Phone>
                        <xsl:value-of select="ns1:CONTACT_PHONE"/>
                      </msg_in_out:Phone>
                      <msg_in_out:TCAPartyId>
                        <xsl:value-of select="ns1:CONTACT_PARTY_ID"/>
                      </msg_in_out:TCAPartyId>
                      <msg_in_out:TCACustAccSiteId>
                        <xsl:value-of select="ns1:CONTACT_CUST_ACCT_SITE_ID"/>
                      </msg_in_out:TCACustAccSiteId>
                    </msg_in_out:BillingContact>
                  </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
                  <xsl:if test='ns1:SITE_USE_TYPE = "RESELLER"'>
                    <msg_in_out:Reseller>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:text disable-output-escaping="no">0</xsl:text>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:TcaCustAccountId>
                        <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                      </msg_in_out:TcaCustAccountId>
                      <msg_in_out:SearchKey>
                        <xsl:value-of select="ns1:CUST_ACCOUNT_NUMBER"/>
                      </msg_in_out:SearchKey>
                      <msg_in_out:Name>
                        <xsl:value-of select="ns1:PARTY_NAME"/>
                      </msg_in_out:Name>
                      <msg_in_out:CustomerEnglishName>
                        <xsl:value-of select="ns1:TRANSLATED_NAME"/>
                      </msg_in_out:CustomerEnglishName>
                      <msg_in_out:BusinessPartnerCategory>
                        <msg_in_out:SearchKey>
                          <xsl:text disable-output-escaping="no">CUSTOMER</xsl:text>
                        </msg_in_out:SearchKey>
                      </msg_in_out:BusinessPartnerCategory>
                      <msg_in_out:TCAPartyId>
                        <xsl:value-of select="ns1:PARTY_ID"/>
                      </msg_in_out:TCAPartyId>
                      <msg_in_out:TCAPartyNumber>
                        <xsl:value-of select="ns1:PARTY_NUMBER"/>
                      </msg_in_out:TCAPartyNumber>
                      <msg_in_out:IsChainCustomer>
                        <xsl:value-of select="ns1:IS_CHAIN_CUSTOMER"/>
                      </msg_in_out:IsChainCustomer>
                      <msg_in_out:IsPublicSector>
                        <xsl:value-of select="ns1:IS_PUBLIC_SECTOR"/>
                      </msg_in_out:IsPublicSector>
                       <msg_in_out:CustomerChainType>
                    <xsl:value-of select="ns1:CUSTOMER_CHAIN_TYPE"/>
                  </msg_in_out:CustomerChainType>
                    </msg_in_out:Reseller>
                  </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
                  <xsl:if test='(ns1:SITE_USE_TYPE = "RESELLER") and ns1:CUST_ACCT_SITE_ID'>
                    <msg_in_out:ResellerAddress>
                      <msg_in_out:BusinessPartner>
                        <msg_in_out:TcaCustAccountId>
                          <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                        </msg_in_out:TcaCustAccountId>
                      </msg_in_out:BusinessPartner>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:TCACustAccntSiteId>
                        <xsl:value-of select="ns1:CUST_ACCT_SITE_ID"/>
                      </msg_in_out:TCACustAccntSiteId>
                      <msg_in_out:PartySiteNumber>
                        <xsl:value-of select="ns1:PARTY_SITE_NUMBER"/>
                      </msg_in_out:PartySiteNumber>
                      <msg_in_out:Name>
                        <xsl:value-of select='substring(concat(ns1:CITY,", ",ns1:ADDRESS1),1.0,60.0)'/>
                      </msg_in_out:Name>
                      <msg_in_out:IsInvoice2Address>
                        <xsl:text disable-output-escaping="no">true</xsl:text>
                      </msg_in_out:IsInvoice2Address>
                      <msg_in_out:GeographyLocation>
                        <msg_in_out:TcaLocationId>
                          <xsl:value-of select="ns1:LOCATION_ID"/>
                        </msg_in_out:TcaLocationId>
                        <msg_in_out:AddressLine1>
                          <xsl:value-of select="ns1:ADDRESS1"/>
                        </msg_in_out:AddressLine1>
                        <msg_in_out:AddressLine2>
                          <xsl:value-of select="ns1:ADDRESS2"/>
                        </msg_in_out:AddressLine2>
                        <msg_in_out:PostalCode>
                          <xsl:value-of select="ns1:POSTAL_CODE"/>
                        </msg_in_out:PostalCode>
                        <msg_in_out:CityName>
                          <xsl:value-of select="ns1:CITY"/>
                        </msg_in_out:CityName>
                        <xsl:if test="ns1:STATE">
                          <msg_in_out:Region>
                            <msg_in_out:Name>
                              <xsl:value-of select="ns1:STATE"/>
                            </msg_in_out:Name>
                            <msg_in_out:Country>
                              <msg_in_out:Code>
                                <xsl:value-of select="ns1:COUNTRY"/>
                              </msg_in_out:Code>
                            </msg_in_out:Country>
                          </msg_in_out:Region>
                        </xsl:if>
                        <msg_in_out:Country>
                          <msg_in_out:Code>
                            <xsl:value-of select="ns1:COUNTRY"/>
                          </msg_in_out:Code>
                        </msg_in_out:Country>
                      </msg_in_out:GeographyLocation>
                    </msg_in_out:ResellerAddress>
                  </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
                  <xsl:if test='(ns1:SITE_USE_TYPE = "RESELLER") and ns1:CONTACT_CUST_ACCT_ROLE_ID'>
                    <msg_in_out:ResellerContact>
                      <msg_in_out:TCACustAccRoleId>
                        <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                      </msg_in_out:TCACustAccRoleId>
                      <msg_in_out:BusinessPartner>
                        <msg_in_out:TcaCustAccountId>
                          <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                        </msg_in_out:TcaCustAccountId>
                      </msg_in_out:BusinessPartner>
                      <msg_in_out:Name>
                        <xsl:value-of select='concat(ns1:CONTACT_FIRST_NAME," ",ns1:CONTACT_LAST_NAME)'/>
                      </msg_in_out:Name>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:FirstName>
                        <xsl:value-of select="ns1:CONTACT_FIRST_NAME"/>
                      </msg_in_out:FirstName>
                      <msg_in_out:LastName>
                        <xsl:value-of select="ns1:CONTACT_LAST_NAME"/>
                      </msg_in_out:LastName>
                      <msg_in_out:Email>
                        <xsl:value-of select="ns1:CONTACT_EMAIL"/>
                      </msg_in_out:Email>
                      <msg_in_out:Phone>
                        <xsl:value-of select="ns1:CONTACT_PHONE"/>
                      </msg_in_out:Phone>
                      <msg_in_out:TCAPartyId>
                        <xsl:value-of select="ns1:CONTACT_PARTY_ID"/>
                      </msg_in_out:TCAPartyId>
                      <msg_in_out:TCACustAccSiteId>
                        <xsl:value-of select="ns1:CONTACT_CUST_ACCT_SITE_ID"/>
                      </msg_in_out:TCACustAccSiteId>
                    </msg_in_out:ResellerContact>
                  </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="ns1:ENTITLEMENT_COMPONENTS/ns1:MISIMD_SPM_ENT_COMPONENT">
                  <msg_in_out:Entitlement>
                    <msg_in_out:Subscription>
                      <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER = "0"'>
                        <msg_in_out:Name>
                          <xsl:value-of select='concat(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_TYPE,"_",/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_NUMBER, $varContactIdentifier)'/>
                        </msg_in_out:Name>
                      </xsl:if>
                      <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER != "0"'>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER"/>
                        </msg_in_out:SearchKey>
                      </xsl:if>
                    </msg_in_out:Subscription>
                    <msg_in_out:LineNo>
                      <xsl:value-of select="ns1:LINE_NUMBER"/>
                    </msg_in_out:LineNo>
                    <xsl:if test="string(ns1:LICENSE_METRIC)">
                      <msg_in_out:LicenseMetric>
                        <xsl:value-of select="ns1:LICENSE_METRIC"/>
                      </msg_in_out:LicenseMetric>
                    </xsl:if>
                    <xsl:if test="string(ns1:QUANTITY_CONSTRAINT)">
                      <msg_in_out:QuantityConstraint>
                        <xsl:value-of select="ns1:QUANTITY_CONSTRAINT"/>
                      </msg_in_out:QuantityConstraint>
                    </xsl:if>
                    <xsl:if test="string(ns1:QUANTITY_MULTIPLIER)">
                      <msg_in_out:QuantityMultiplier>
                        <xsl:value-of select="ns1:QUANTITY_MULTIPLIER"/>
                      </msg_in_out:QuantityMultiplier>
                    </xsl:if>
                    <xsl:if test="string(ns1:FIRST_PURCHASE)">
                      <msg_in_out:FirstPurchase>
                        <xsl:value-of select="ns1:FIRST_PURCHASE"/>
                      </msg_in_out:FirstPurchase>
                    </xsl:if>
                    <xsl:if test="string(ns1:SERVICE_PART_ID)">
                      <msg_in_out:ServicePart>
                        <xsl:value-of select="ns1:SERVICE_PART_ID"/>
                      </msg_in_out:ServicePart>
                    </xsl:if>
                    <xsl:if test="string(ns1:SERVICE_PART_DESCRIPTION)">
                      <msg_in_out:ServicePartDescription>
                        <xsl:value-of select="ns1:SERVICE_PART_DESCRIPTION"/>
                      </msg_in_out:ServicePartDescription>
                    </xsl:if>
                    <msg_in_out:Quantity>
                      <xsl:text disable-output-escaping="no">1</xsl:text>
                    </msg_in_out:Quantity>
                    <msg_in_out:ParentPartNumber>
                      <xsl:value-of select="ns1:PARENT_PART_NUMBER"/>
                    </msg_in_out:ParentPartNumber>
                    <msg_in_out:ParentPartDescription>
                      <xsl:value-of select="ns1:PARENT_PART_DESCRIPTION"/>
                    </msg_in_out:ParentPartDescription>
                    <msg_in_out:ParentInventoryItemID>
                      <xsl:value-of select="ns1:PARENT_INVENTORY_ITEM_ID"/>
                    </msg_in_out:ParentInventoryItemID>
                    <msg_in_out:ChildPartNumber>
                      <xsl:value-of select="ns1:CHILD_PART_NUMBER"/>
                    </msg_in_out:ChildPartNumber>
                    <msg_in_out:ChildPartDescription>
                      <xsl:value-of select="ns1:CHILD_PART_DESCRIPTION"/>
                    </msg_in_out:ChildPartDescription>
                    <msg_in_out:ChildInventoryItemID>
                      <xsl:value-of select="ns1:CHILD_INVENTORY_ITEM_ID"/>
                    </msg_in_out:ChildInventoryItemID>
                    <msg_in_out:PhoneCountryCode>
                      <xsl:value-of select="../../ns1:ENTITLEMENT_COUNTRYCODE"/>
                    </msg_in_out:PhoneCountryCode>
                    <msg_in_out:PhoneNumber>
                      <xsl:value-of select="../../ns1:ENTITLEMENT_PHONENUMBER"/>
                    </msg_in_out:PhoneNumber>
                  </msg_in_out:Entitlement>
                </xsl:for-each>
                <xsl:for-each select="ns1:SALES_CREDIT/ns1:MISIMD_SPM_SALES_CREDIT">
                  <msg_in_out:SalesCredit>
                    <msg_in_out:SalesRep>
                      <msg_in_out:Name>
                        <xsl:value-of select="ns1:SALESREP_NAME"/>
                      </msg_in_out:Name>
                      <msg_in_out:Org>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                        </msg_in_out:SearchKey>
                      </msg_in_out:Org>
                      <msg_in_out:Email>
                        <xsl:value-of select="ns1:SALESREP_EMAIL"/>
                      </msg_in_out:Email>
                      <msg_in_out:BusinessPartner>
                        <msg_in_out:Org>
                          <msg_in_out:SearchKey>
                            <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
                          </msg_in_out:SearchKey>
                        </msg_in_out:Org>
                        <msg_in_out:JTFSalesRepId>
                          <xsl:value-of select="ns1:SALESREP_ID"/>
                        </msg_in_out:JTFSalesRepId>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select='concat(ns1:SALESREP_NUMBER,"-",../../../../ns1:ORGANIZATION_ID)'/>
                        </msg_in_out:SearchKey>
                        <msg_in_out:Name>
                          <xsl:value-of select="ns1:SALESREP_NAME"/>
                        </msg_in_out:Name>
                        <msg_in_out:IsSalesRepresentative>
                          <xsl:text disable-output-escaping="no">true</xsl:text>
                        </msg_in_out:IsSalesRepresentative>
                        <msg_in_out:IsCustomer>
                          <xsl:text disable-output-escaping="no">false</xsl:text>
                        </msg_in_out:IsCustomer>
                        <msg_in_out:BusinessPartnerCategory>
                          <msg_in_out:SearchKey>
                            <xsl:text disable-output-escaping="no">Employee</xsl:text>
                          </msg_in_out:SearchKey>
                        </msg_in_out:BusinessPartnerCategory>
                      </msg_in_out:BusinessPartner>
                    </msg_in_out:SalesRep>
                    <msg_in_out:Subscription>
                      <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER = "0"'>
                        <msg_in_out:Name>
                          <xsl:value-of select='concat(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_TYPE,"_",/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_NUMBER, $varContactIdentifier)'/>
                        </msg_in_out:Name>
                      </xsl:if>
                      <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER != "0"'>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER"/>
                        </msg_in_out:SearchKey>
                      </xsl:if>
                    </msg_in_out:Subscription>
                    <msg_in_out:SalesCreditType>
                      <xsl:value-of select="ns1:SALES_CREDIT_TYPE_ID"/>
                    </msg_in_out:SalesCreditType>
                    <msg_in_out:Percent>
                      <xsl:value-of select="ns1:PERCENT"/>
                    </msg_in_out:Percent>
                  </msg_in_out:SalesCredit>
                </xsl:for-each>
                <xsl:for-each select="ns1:BOM_COMPONENTS/ns1:MISIMD_SPM_BOM_COMPONENT">
                  <msg_in_out:BOMComponent>
                    <msg_in_out:Product>
                      <msg_in_out:SearchKey>
                        <xsl:value-of select="ns1:INV_PART_NUMBER"/>
                      </msg_in_out:SearchKey>
                    </msg_in_out:Product>
                    <msg_in_out:StartDate>
                      <xsl:value-of select="../../ns1:START_DATE"/>
                    </msg_in_out:StartDate>
                    <msg_in_out:EndDate>
                      <xsl:value-of select="../../ns1:END_DATE"/>
                    </msg_in_out:EndDate>
                    <msg_in_out:Subscription>
                      <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER = "0"'>
                        <msg_in_out:Name>
                          <xsl:value-of select='concat(/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_TYPE,"_",/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_NUMBER, $varContactIdentifier)'/>
                        </msg_in_out:Name>
                      </xsl:if>
                      <xsl:if test='/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER != "0"'>
                        <msg_in_out:SearchKey>
                          <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:SPM_PLAN_NUMBER"/>
                        </msg_in_out:SearchKey>
                      </xsl:if>
                    </msg_in_out:Subscription>
                    <msg_in_out:PricePeriod>
                      <xsl:value-of select="ns1:PRICE_PERIOD"/>
                    </msg_in_out:PricePeriod>
                    <msg_in_out:Quantity>
                      <xsl:text disable-output-escaping="no">0</xsl:text>
                    </msg_in_out:Quantity>
                    <xsl:choose>
                      <xsl:when test='ns1:PRICE_BAND_ITEM_FLAG = "N"'>
                        <msg_in_out:NetUnitPrice>
                          <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:UNIT_SELLING_PRICE"/>
                        </msg_in_out:NetUnitPrice>
                      </xsl:when>
                      <xsl:otherwise>
                        <msg_in_out:NetUnitPrice>
                          <xsl:text disable-output-escaping="no">0</xsl:text>
                        </msg_in_out:NetUnitPrice>
                      </xsl:otherwise>
                    </xsl:choose>
                    <msg_in_out:NetUnitPriceUOM>
                      <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:UNIT_SELLING_PRICE_UOM"/>
                    </msg_in_out:NetUnitPriceUOM>
                    <msg_in_out:OveragePrice>
                      <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:OVERAGE_PRICE"/>
                    </msg_in_out:OveragePrice>
                    <msg_in_out:OveragePriceUOM>
                      <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:OVERAGE_PRICE_UOM"/>
                    </msg_in_out:OveragePriceUOM>
                    <msg_in_out:DiscretionaryDiscountPercentage>
                      <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:DISCR_DISCOUNT_PRCNT"/>
                    </msg_in_out:DiscretionaryDiscountPercentage>
                    <msg_in_out:DiscountCategory>
                      <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:DISCOUNT_CATEGORY"/>
                    </msg_in_out:DiscountCategory>
                    <msg_in_out:OverageDiscountPercentage>
                      <xsl:value-of select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD/ns1:OVERAGE_DISCOUNT_PRCNT"/>
                    </msg_in_out:OverageDiscountPercentage>
                    <xsl:choose>
                      <xsl:when test='ns1:PRICE_BAND_ITEM_FLAG = "Y"'>
                        <msg_in_out:IsTier>
                          <xsl:text disable-output-escaping="no">true</xsl:text>
                        </msg_in_out:IsTier>
                      </xsl:when>
                      <xsl:otherwise>
                        <msg_in_out:IsTier>
                          <xsl:text disable-output-escaping="no">false</xsl:text>
                        </msg_in_out:IsTier>
                      </xsl:otherwise>
                    </xsl:choose>
                    <msg_in_out:IsDonotGenInvLines>
                      <xsl:text disable-output-escaping="no">true</xsl:text>
                    </msg_in_out:IsDonotGenInvLines>
                    <msg_in_out:RateCardId>
                      <xsl:value-of select="ns1:RATE_CARD_ID"/>
                    </msg_in_out:RateCardId>
                    <msg_in_out:IsTopLevel>
                      <xsl:text disable-output-escaping="no">false</xsl:text>
                    </msg_in_out:IsTopLevel>
                    <xsl:if test='ns1:PRICE_BAND_ITEM_FLAG = "Y"'>
                      <xsl:for-each select="ns1:RATE_CARD/ns1:MISIMD_SPM_RATE_CARD">
                        <msg_in_out:IptProductTier>
                          <msg_in_out:MaxQuantity>
                            <xsl:value-of select="ns1:TO_BAND_QUANTITY"/>
                          </msg_in_out:MaxQuantity>
                          <msg_in_out:UnitPrice>
                            <xsl:value-of select="ns1:UNIT_SELLING_PRICE"/>
                          </msg_in_out:UnitPrice>
                          <msg_in_out:Description>
                            <xsl:value-of select="../../ns1:INV_PART_DESCRIPTION"/>
                          </msg_in_out:Description>
                          <msg_in_out:OveragePrice>
                            <xsl:value-of select="ns1:OVERAGE_PRICE"/>
                          </msg_in_out:OveragePrice>
                        </msg_in_out:IptProductTier>
                      </xsl:for-each>
                    </xsl:if>
                  </msg_in_out:BOMComponent>
                </xsl:for-each>
                <xsl:for-each select="ns1:OPTIONAL_TIERS/ns1:MISIMD_SPM_OPTIONAL_TIERS">
                  <msg_in_out:OptionalTier>
                    <msg_in_out:StartDate>
                      <xsl:value-of select="ns1:START_DATE"/>
                    </msg_in_out:StartDate>
                    <msg_in_out:EndDate>
                      <xsl:value-of select="ns1:END_DATE"/>
                    </msg_in_out:EndDate>
                    <msg_in_out:Quantity>
                      <xsl:value-of select="ns1:QUANTITY"/>
                    </msg_in_out:Quantity>
                    <msg_in_out:UnitPrice>
                      <xsl:value-of select="ns1:UNIT_LIST_PRICE"/>
                    </msg_in_out:UnitPrice>
                    <msg_in_out:OveragePrice>
                      <xsl:value-of select="ns1:SUB_OVERAGE_PRICE"/>
                    </msg_in_out:OveragePrice>
                    <msg_in_out:OveragePolicy>
                      <xsl:value-of select="ns1:SUB_OVERAGE_POLICY_TYPE"/>
                    </msg_in_out:OveragePolicy>
                  </msg_in_out:OptionalTier>
                </xsl:for-each>
              </msg_in_out:SubscribedService>
            </xsl:for-each>
          </msg_in_out:Subscription>
        </msg_in_out:SPM>
      </msg_in_out:PAYLOAD>
      <msg_in_out:ATTACHMENT>
        <ns1:MISIMD_SPM_SUBSCRIPTION>
          <ns1:ORDER_HEADER_ID>
            <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_HEADER_ID"/>
          </ns1:ORDER_HEADER_ID>
          <ns1:ORGANIZATION_ID>
            <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORGANIZATION_ID"/>
          </ns1:ORGANIZATION_ID>
          <ns1:ORDER_NUMBER>
            <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:ORDER_NUMBER"/>
          </ns1:ORDER_NUMBER>
          <ns1:CUSTOMERS>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CUSTOMERS/ns1:MISIMD_SPM_CUSTOMER">
              <ns1:MISIMD_SPM_CUSTOMER>
                <ns1:TCA_CUST_ACCOUNT_ID>
                  <xsl:value-of select="ns1:TCA_CUST_ACCOUNT_ID"/>
                </ns1:TCA_CUST_ACCOUNT_ID>
                <ns1:CUST_ACCT_SITE_ID>
                  <xsl:value-of select="ns1:CUST_ACCT_SITE_ID"/>
                </ns1:CUST_ACCT_SITE_ID>
                <ns1:SITE_USE_TYPE>
                  <xsl:value-of select="ns1:SITE_USE_TYPE"/>
                </ns1:SITE_USE_TYPE>
                <ns1:CONTACT_CUST_ACCT_ROLE_ID>
                  <xsl:value-of select="ns1:CONTACT_CUST_ACCT_ROLE_ID"/>
                </ns1:CONTACT_CUST_ACCT_ROLE_ID>
              </ns1:MISIMD_SPM_CUSTOMER>
            </xsl:for-each>
          </ns1:CUSTOMERS>
          <ns1:LINES>
            <xsl:for-each select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:LINES/ns1:MISIMD_SPM_LINES">
              <ns1:MISIMD_SPM_LINES>
                <ns1:ORDER_LINE_ID>
                  <xsl:value-of select="ns1:ORDER_LINE_ID"/>
                </ns1:ORDER_LINE_ID>
                <ns1:SUBSCRIPTION_ID>
                  <xsl:value-of select="ns1:SUBSCRIPTION_ID"/>
                </ns1:SUBSCRIPTION_ID>
              </ns1:MISIMD_SPM_LINES>
            </xsl:for-each>
          </ns1:LINES>
        </ns1:MISIMD_SPM_SUBSCRIPTION>
      </msg_in_out:ATTACHMENT>
    </msg_in_out:ORACLE_INTEGRATION_MESSAGE>
  </xsl:template>
</xsl:stylesheet>