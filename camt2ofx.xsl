<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

  <!-- Look at the file's GrpHdr -->
  <xsl:template match="/Document/BkToCstmrStmt/GrpHdr">
    <!-- Check if the camt 053 statement is contained within a single file/message
         We don't handle statements split into multiple files yet
         and if one is encountered, the translation will be aborted -->
    <xsl:if test="MsgPgntn/PgNb != 1 or MsgPgntn/LastPgInd != 'true'">
      <xsl:message terminate="yes">
        <xsl:text>Incomplete message (not first page or subsequent pages exist)</xsl:text>
      </xsl:message>
    </xsl:if>
  </xsl:template>

  <!-- Handle one of the summary rows (opening or closing balance details) -->
  <xsl:template match="/Document/BkToCstmrStmt/Stmt/Bal">
  	<BALAMT>
      <xsl:if test="CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="Amt"/>
    </BALAMT>
    <DTASOF>
      <xsl:value-of select="translate(Dt/Dt,'-','')"/>
    </DTASOF>
  </xsl:template>

  <!-- Handle one of the entries in the list of transactions -->
  <xsl:template match="/Document/BkToCstmrStmt/Stmt/Ntry">

    <xsl:variable name="fee" select="translate(number(Chrgs/TtlChrgsAndTaxAmt), 'aN', '0')"/>

    <STMTTRN>
      <TRNTYPE>
        <xsl:if test="CdtDbtInd = 'CRDT'">CREDIT</xsl:if>
        <xsl:if test="CdtDbtInd = 'DBIT'">DEBIT</xsl:if>
      </TRNTYPE>
      <DTPOSTED>
        <xsl:value-of select="translate(ValDt/Dt,'-','')"/>
      </DTPOSTED>
      <TRNAMT>
        <xsl:if test="CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="Amt - $fee"/>
      </TRNAMT>
      <FITID>
        <xsl:value-of select="NtryDtls/TxDtls/Refs/AcctSvcrRef"/>
      </FITID>
      <NAME>
        <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Cdtr/Nm"/>
        <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Dbtr/Nm"/>
      </NAME>
      <MEMO>
        <xsl:value-of select="AddtlNtryInf"/>
      </MEMO>
    </STMTTRN>

    <xsl:if test="$fee > 0">

      <STMTTRN>
        <TRNTYPE>FEE</TRNTYPE>
        <DTPOSTED>
          <xsl:value-of select="translate(ValDt/Dt,'-','')"/>
        </DTPOSTED>
        <TRNAMT><xsl:value-of select="-$fee"/>
        </TRNAMT>
        <FITID>
          <xsl:value-of select="NtryDtls/TxDtls/Refs/AcctSvcrRef"/><xsl:text>/FEE</xsl:text>
        </FITID>
        <NAME>
          <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Cdtr/Nm"/>
        </NAME>
        <MEMO>
          <xsl:value-of select="AddtlNtryInf"/>
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
              <xsl:value-of select="/Document/BkToCstmrStmt/Stmt/Id"/>
            </TRNUID>
            <CURDEF>
              <xsl:value-of select="/Document/BkToCstmrStmt/Stmt/Bal/Amt/@Ccy"/>
            </CURDEF>
            <BANKACCTFROM>
              <BANKID>
                <xsl:value-of select="/Document/BkToCstmrStmt/Stmt/Acct/Svcr/FinInstnId/BICFI"/>
              </BANKID>
              <ACCTID>
                <xsl:value-of select="/Document/BkToCstmrStmt/Stmt/Acct/Id"/>
              </ACCTID>
              <ACCTTYPE>CHECKING</ACCTTYPE>
            </BANKACCTFROM>
            <BANKTRANLIST>
              <DTSTART>
                <xsl:value-of select="translate(/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd[text()='OPBD']/../../../Dt/Dt,'-','')"/>
              </DTSTART>
              <DTEND>
                <xsl:value-of select="translate(/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd[text()='CLBD']/../../../Dt/Dt,'-','')"/>
              </DTEND>

              <!-- List of transaction details -->
              <xsl:apply-templates select="/Document/BkToCstmrStmt/Stmt/Ntry"/>

            </BANKTRANLIST>
            <LEDGERBAL>

                <!-- Closing balance -->
                <xsl:apply-templates select="/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd[text()='CLBD']/../../.."/>

				    </LEDGERBAL>
          </STMTRS>
        </STMTTRNRS>
      </BANKMSGSRSV1>
    </OFX>

    <!-- Check the GrpHdr first
    <xsl:apply-templates select="/Document/BkToCstmrStmt/GrpHdr"/>
    -->

    <!-- Closing balance
    /Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd[text()='CLBD']/../../..
    /Dt/Dt
    <xsl:value-of select="Dt/Dt"/>
    <xsl:if test="CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="Amt"/>
    -->

    <!-- Account holder name 
    <xsl:value-of select="/Document/BkToCstmrStmt/Stmt/Acct/Ownr/Nm"/>
    -->


  </xsl:template>

</xsl:stylesheet>