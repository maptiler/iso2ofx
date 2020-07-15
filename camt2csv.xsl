<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:camt="urn:iso:std:iso:20022:tech:xsd:camt.053.001.04">
<xsl:output method="text" encoding="UTF-8"/>

<xsl:strip-space elements="*" />

<xsl:template match="/camt:Document/camt:BkToCstmrStmt/camt:GrpHdr">
  <xsl:if test="camt:MsgPgntn/camt:PgNb != 1 or camt:MsgPgntn/camt:LastPgInd != 'true'">
    <xsl:message terminate="yes">
      <xsl:text>Incomplete message (not first page or subsequent pages exist)</xsl:text>
    </xsl:message>
  </xsl:if>
</xsl:template>

<xsl:template match="/camt:Document/camt:BkToCstmrStmt/camt:Stmt">
<xsl:for-each select="camt:Ntry">
  <xsl:variable name="fee" select="translate(number(camt:Chrgs/camt:TtlChrgsAndTaxAmt), 'aN', '0')"/>
  <xsl:if test="$fee > 0">
    <xsl:value-of select="translate(camt:ValDt/camt:Dt,'-','')"/>,<xsl:if test="camt:CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="$fee"/>,"","<xsl:value-of select="camt:AddtlNtryInf"/> - fee"<xsl:text>&#xD;&#xA;</xsl:text>
  </xsl:if>
  <xsl:value-of select="camt:ValDt/camt:Dt"/>,<xsl:if test="camt:CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="camt:Amt - $fee"/>,"<xsl:value-of select="camt:NtryDtls/camt:TxDtls/camt:RltdPties/camt:Cdtr/camt:Nm"/>","<xsl:value-of select="camt:AddtlNtryInf"/>"<xsl:text>&#xD;&#xA;</xsl:text>
</xsl:for-each>
</xsl:template>

<xsl:template match="/">Date,Amount,Payee,Description<xsl:text>&#xD;&#xA;</xsl:text><xsl:apply-templates select="/camt:Document/camt:BkToCstmrStmt/camt:GrpHdr|/camt:Document/camt:BkToCstmrStmt/camt:Stmt"/></xsl:template>

</xsl:stylesheet>
