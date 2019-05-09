<?xml version = '1.0' encoding = 'UTF-8'?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:ns3="http://xmlns.oracle.com/apps/scm/productModel/deleteGroups/publicModel/"
                xmlns:ns2="http://xmlns.oracle.com/oracle/apps/sales/opptyMgmt/revenues/revenueService/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:ns6="http://xmlns.oracle.com/apps/crmCommon/notes/flex/noteDff/"
                xmlns:pc="http://xmlns.oracle.com/pcbpel/"
                xmlns:ns8="http://xmlns.oracle.com/apps/crmCommon/activities/activitiesService/"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:ns9="http://xmlns.oracle.com/apps/crmCommon/notes/noteService"
                xmlns:ph="http://xmlns.oracle.com/pcbpel/adapter/aq/headers/payloadheaders/"
                xmlns:plt="http://schemas.xmlsoap.org/ws/2003/05/partner-link/"
                xmlns:tns="http://xmlns.oracle.com/pcbpel/adapter/AQ/SPM+Proj+Application/MISIMDOMNotifySPM/DequeueOrderDetailsForSPM"
                xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                xmlns:ns0="http://xmlns.oracle.com/apps/sales/opptyMgmt/opportunities/opportunityService/"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:errors="http://xmlns.oracle.com/adf/svc/errors/" xmlns:obj1="http://xmlns.oracle.com/xdb/APPS"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns4="commonj.sdo/xml"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:ns5="http://xmlns.oracle.com/adf/svc/types/"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath" xmlns:ns1="http://www.oracle.com/spm"
                xmlns:ns7="commonj.sdo/java" xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:jca="http://xmlns.oracle.com/pcbpel/wsdl/jca/"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:types="http://xmlns.oracle.com/apps/sales/opptyMgmt/opportunities/opportunityService/types/"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:ns10="commonj.sdo" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ns11="http://xmlns.oracle.com/apps/sales/opptyMgmt/revenues/revenueService/"
                xmlns:orafault="http://xmlns.oracle.com/oracleas/schema/oracle-fault-11_0"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl pc ph plt tns wsdl obj1 ns1 jca xsd ns3 ns2 ns6 ns8 ns9 soap ns0 errors ns4 ns5 ns7 types ns10 ns11 orafault xp20 bpws bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref ldap">
    <xsl:template match="/">
      <types:findOpportunity>
            <types:findCriteria>
                <ns5:fetchStart>
                    <xsl:text disable-output-escaping="no">0</xsl:text>
                </ns5:fetchStart>
                <ns5:fetchSize>
                    <xsl:text disable-output-escaping="no">1</xsl:text>
                </ns5:fetchSize>
                <ns5:filter>
                    <ns5:group>
                        <ns5:upperCaseCompare>
                            <xsl:text disable-output-escaping="no">false</xsl:text>
                        </ns5:upperCaseCompare>
                        <ns5:item>
                            <ns5:upperCaseCompare>
                                <xsl:text disable-output-escaping="no">false</xsl:text>
                            </ns5:upperCaseCompare>
                            <ns5:attribute>
                                <xsl:text disable-output-escaping="no">OptyNumber</xsl:text>
                            </ns5:attribute>
                            <ns5:operator>
                                <xsl:text disable-output-escaping="no">=</xsl:text>
                            </ns5:operator>
                            <ns5:value>
                                <xsl:value-of select="/ns1:MISIMD_SPM_SUBSCRIPTION/ns1:CRM_OPTY_NUM"/>
                            </ns5:value>
                        </ns5:item>
                    </ns5:group>
                </ns5:filter>
                <ns5:findAttribute>
                    <xsl:text disable-output-escaping="no">TargetPartyId</xsl:text>
                </ns5:findAttribute>
                <ns5:findAttribute>
                    <xsl:text disable-output-escaping="no">PreviousContractNumber_c</xsl:text>
                </ns5:findAttribute>
                <ns5:excludeAttribute>
                    <xsl:text disable-output-escaping="no">false</xsl:text>
                </ns5:excludeAttribute>
            </types:findCriteria>
            <types:findControl>
                <ns5:retrieveAllTranslations>
                    <xsl:text disable-output-escaping="no">false</xsl:text>
                </ns5:retrieveAllTranslations>
            </types:findControl>
        </types:findOpportunity>
   </xsl:template>
</xsl:stylesheet>