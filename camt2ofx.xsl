<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:camt="urn:iso:std:iso:20022:tech:xsd:camt.053.001.04" exclude-result-prefixes="camt">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

  <!-- Look at the file's GrpHdr -->
  <xsl:template match="/camt:Document/camt:BkToCstmrStmt/camt:GrpHdr">
    <!-- Check if the camt 053 statement is contained within a single file/message
         We don't handle statements split into multiple files yet
         and if one is encountered, the translation will be aborted -->
    <xsl:if test="camt:MsgPgntn/camt:PgNb != 1 or camt:MsgPgntn/camt:LastPgInd != 'true'">
      <xsl:message terminate="yes">
        <xsl:text>Incomplete message (not first page or subsequent pages exist)</xsl:text>
      </xsl:message>
    </xsl:if>
  </xsl:template>

  <!-- Handle one of the summary rows (opening or closing balance details) -->
  <xsl:template match="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Bal">
  	<BALAMT>
      <xsl:if test="camt:CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="camt:Amt"/>
    </BALAMT>
    <DTASOF>
      <xsl:value-of select="translate(camt:Dt/camt:Dt,'-','')"/>
    </DTASOF>
  </xsl:template>

  <!-- Handle one of the entries in the list of transactions -->
  <xsl:template match="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Ntry">

    <xsl:variable name="fee" select="translate(number(camt:Chrgs/camt:TtlChrgsAndTaxAmt), 'aN', '0')"/>

    <STMTTRN>
      <TRNTYPE>
        <xsl:if test="camt:CdtDbtInd = 'CRDT'">CREDIT</xsl:if>
        <xsl:if test="camt:CdtDbtInd = 'DBIT'">DEBIT</xsl:if>
      </TRNTYPE>
      <DTPOSTED>
        <xsl:value-of select="translate(camt:ValDt/camt:Dt,'-','')"/>
      </DTPOSTED>
      <TRNAMT>
        <xsl:if test="camt:CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="camt:Amt - $fee"/>
      </TRNAMT>
      <FITID>
        <xsl:value-of select="camt:NtryDtls/camt:TxDtls/camt:Refs/camt:AcctSvcrRef"/>
      </FITID>
      <NAME>
        <xsl:value-of select="camt:NtryDtls/camt:TxDtls/camt:RltdPties/camt:Cdtr/camt:Nm"/>
      </NAME>
      <MEMO>
        <xsl:value-of select="camt:AddtlNtryInf"/>
      </MEMO>
    </STMTTRN>

    <xsl:if test="$fee > 0">

      <STMTTRN>
        <TRNTYPE>FEE</TRNTYPE>
        <DTPOSTED>
          <xsl:value-of select="translate(camt:ValDt/camt:Dt,'-','')"/>
        </DTPOSTED>
        <TRNAMT><xsl:value-of select="-$fee"/>
        </TRNAMT>
        <FITID>
          <xsl:value-of select="camt:NtryDtls/camt:TxDtls/camt:Refs/camt:AcctSvcrRef"/><xsl:text>/FEE</xsl:text>
        </FITID>
        <NAME>
          <xsl:value-of select="camt:NtryDtls/camt:TxDtls/camt:RltdPties/camt:Cdtr/camt:Nm"/>
        </NAME>
        <MEMO>
          <xsl:value-of select="camt:AddtlNtryInf"/>
        </MEMO>
      </STMTTRN>

    </xsl:if>

  </xsl:template>

  <!-- Handle the root node of the XML document -->
  <xsl:template match="/">
    <xsl:text disable-output-escaping="yes">&lt;?OFX OFXHEADER="200" VERSION="202" SECURITY="NONE" OLDFILEUID="NONE" NEWFILEUID="NONE"?&gt;&#xD;&#xA;</xsl:text>

    <OFX>
      <BANKMSGSRSV1>
        <STMTTRNRS>
          <STMTRS>
            <TRNUID>
              <xsl:value-of select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Id"/>
            </TRNUID>
            <CURDEF>
              <xsl:value-of select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Bal/camt:Amt/@Ccy"/>
            </CURDEF>
            <BANKACCTFROM>
              <BANKID>
                <xsl:value-of select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Acct/camt:Svcr/camt:FinInstnId/camt:BICFI"/>
              </BANKID>
              <ACCTID>
                <xsl:value-of select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Acct/camt:Id"/>
              </ACCTID>
              <ACCTTYPE>CHECKING</ACCTTYPE>
            </BANKACCTFROM>
            <BANKTRANLIST>
              <DTSTART>
                <xsl:value-of select="translate(/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Bal/camt:Tp/camt:CdOrPrtry/camt:Cd[text()='OPBD']/../../../camt:Dt/camt:Dt,'-','')"/>
              </DTSTART>
              <DTEND>
                <xsl:value-of select="translate(/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Bal/camt:Tp/camt:CdOrPrtry/camt:Cd[text()='CLBD']/../../../camt:Dt/camt:Dt,'-','')"/>
              </DTEND>

              <!-- List of transaction details -->
              <xsl:apply-templates select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Ntry"/>

            </BANKTRANLIST>
            <LEDGERBAL>

                <!-- Closing balance -->
                <xsl:apply-templates select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Bal/camt:Tp/camt:CdOrPrtry/camt:Cd[text()='CLBD']/../../.."/>

				    </LEDGERBAL>
          </STMTRS>
        </STMTTRNRS>
      </BANKMSGSRSV1>
    </OFX>

    <!-- Check the GrpHdr first
    <xsl:apply-templates select="/camt:Document/camt:BkToCstmrStmt/camt:GrpHdr"/>
    -->

    <!-- Closing balance
    /camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Bal/camt:Tp/camt:CdOrPrtry/camt:Cd[text()='CLBD']/../../..
    /camt:Dt/camt:Dt
    <xsl:value-of select="camt:Dt/camt:Dt"/>
    <xsl:if test="camt:CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="camt:Amt"/>
    -->

    <!-- Account holder name 
    <xsl:value-of select="/camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Acct/camt:Ownr/camt:Nm"/>
    -->


  </xsl:template>

</xsl:stylesheet>