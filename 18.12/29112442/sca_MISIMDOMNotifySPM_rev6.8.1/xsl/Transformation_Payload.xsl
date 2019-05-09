<?xml version = '1.0' encoding = 'UTF-8'?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:oraxsl="http://www.oracle.com/XSL/Transform/java"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:oracle-xsl-mapper="http://www.oracle.com/xsl/mapper/schemas"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:ns0="http://www.oracle.com/spm" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:ns1="http://xmlns.oracle.com/oih/oracle_integration_message"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                exclude-result-prefixes="xsi oracle-xsl-mapper xsl xsd ns0 ns1 xp20 oraxsl mhdr oraext dvm xref socket"
                xmlns:tns="http://xmlns.oracle.com/pcbpel/adapter/http/SPM/MISIMDOMNotifySPM/SPMGenericWS"
                xmlns:plt="http://schemas.xmlsoap.org/ws/2003/05/partner-link/"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:ns2="http://schemas.oracle.com/bpel/extension">
    <oracle-xsl-mapper:schema>
        <oracle-xsl-mapper:mapSources>
            <oracle-xsl-mapper:source type="WSDL">
                <oracle-xsl-mapper:schema location="../SPMGenericWS.wsdl"/>
                <oracle-xsl-mapper:rootElement name="MISIMD_SPM_SUBSCRIPTION" namespace="http://www.oracle.com/spm"/>
            </oracle-xsl-mapper:source>
            <oracle-xsl-mapper:source type="WSDL">
                <oracle-xsl-mapper:schema location="../SPMGenericWS.wsdl"/>
                <oracle-xsl-mapper:rootElement name="ORACLE_INTEGRATION_MESSAGE"
                                               namespace="http://xmlns.oracle.com/oih/oracle_integration_message"/>
                <oracle-xsl-mapper:param name="InvokeSPMGenericWS_Request-Response_InputVariable.ORACLE_INTEGRATION_MESSAGE"/>
            </oracle-xsl-mapper:source>
        </oracle-xsl-mapper:mapSources>
        <oracle-xsl-mapper:mapTargets>
            <oracle-xsl-mapper:target type="WSDL">
                <oracle-xsl-mapper:schema location="../SPMGenericWS.wsdl"/>
                <oracle-xsl-mapper:rootElement name="ORACLE_INTEGRATION_MESSAGE"
                                               namespace="http://xmlns.oracle.com/oih/oracle_integration_message"/>
            </oracle-xsl-mapper:target>
        </oracle-xsl-mapper:mapTargets>
    </oracle-xsl-mapper:schema>
    <xsl:param name="InvokeSPMGenericWS_Request-Response_InputVariable.ORACLE_INTEGRATION_MESSAGE"/>
    <xsl:template match="/">
        <ns1:ORACLE_INTEGRATION_MESSAGE/>
    </xsl:template>
</xsl:stylesheet>