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

    <!-- Check if this is a batch transaction -->
    <xsl:choose>
      <!-- If it's a batch transaction, process each TxDtls individually -->
      <xsl:when test="NtryDtls/Btch">
        <xsl:apply-templates select="NtryDtls/TxDtls" mode="batch">
          <xsl:with-param name="parentNtry" select="."/>
          <xsl:with-param name="fee" select="$fee"/>
        </xsl:apply-templates>
      </xsl:when>
      <!-- If it's a regular transaction, process as before (backward compatibility) -->
      <xsl:otherwise>
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
            <xsl:value-of select="AcctSvcrRef"/>
          </FITID>
          <REFNUM>
            <xsl:value-of select="normalize-space(NtryDtls/TxDtls/Refs/Prtry/Ref)"/>
          </REFNUM>
          <NAME>
            <xsl:choose>
              <!-- For CREDIT transactions, show the DEBTOR (who is paying us) -->
              <xsl:when test="CdtDbtInd = 'CRDT'">
                <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Dbtr/Pty/Nm"/>
                <!-- Backward compatibility: also try the old path structure -->
                <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Dbtr/Nm"/>
              </xsl:when>
              <!-- For DEBIT transactions, show the CREDITOR (who we are paying) -->
              <xsl:when test="CdtDbtInd = 'DBIT'">
                <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Cdtr/Pty/Nm"/>
                <!-- Backward compatibility: also try the old path structure -->
                <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Cdtr/Nm"/>
              </xsl:when>
            </xsl:choose>
          </NAME>
          <MEMO>
            <xsl:choose>
              <!-- First priority: Ustrd from RmtInf (most descriptive) -->
              <xsl:when test="normalize-space(NtryDtls/TxDtls/RmtInf/Ustrd) != ''">
                <xsl:value-of select="normalize-space(NtryDtls/TxDtls/RmtInf/Ustrd)"/>
              </xsl:when>
              <!-- Second priority: AddtlNtryInf without "Transaction ID: " prefix -->
              <xsl:when test="starts-with(normalize-space(AddtlNtryInf), 'Transaction ID: ')">
                <xsl:value-of select="substring-after(normalize-space(AddtlNtryInf), 'Transaction ID: ')"/>
              </xsl:when>
              <!-- Fallback: AddtlNtryInf as is -->
              <xsl:otherwise>
                <xsl:value-of select="normalize-space(AddtlNtryInf)"/>
              </xsl:otherwise>
            </xsl:choose>
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
              <xsl:value-of select="AcctSvcrRef"/><xsl:text>/FEE</xsl:text>
            </FITID>
            <REFNUM>
              <xsl:value-of select="normalize-space(NtryDtls/TxDtls/Refs/Prtry/Ref)"/>
            </REFNUM>
            <NAME>
              <xsl:choose>
                <!-- For CREDIT transactions, show the DEBTOR (who is paying us) -->
                <xsl:when test="CdtDbtInd = 'CRDT'">
                  <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Dbtr/Pty/Nm"/>
                  <!-- Backward compatibility: also try the old path structure -->
                  <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Dbtr/Nm"/>
                </xsl:when>
                <!-- For DEBIT transactions, show the CREDITOR (who we are paying) -->
                <xsl:when test="CdtDbtInd = 'DBIT'">
                  <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Cdtr/Pty/Nm"/>
                  <!-- Backward compatibility: also try the old path structure -->
                  <xsl:value-of select="NtryDtls/TxDtls/RltdPties/Cdtr/Nm"/>
                </xsl:when>
              </xsl:choose>
            </NAME>
            <MEMO>
              <xsl:choose>
                <!-- First priority: Ustrd from RmtInf (most descriptive) -->
                <xsl:when test="normalize-space(NtryDtls/TxDtls/RmtInf/Ustrd) != ''">
                  <xsl:value-of select="normalize-space(NtryDtls/TxDtls/RmtInf/Ustrd)"/>
                </xsl:when>
                <!-- Second priority: AddtlNtryInf without "Transaction ID: " prefix -->
                <xsl:when test="starts-with(normalize-space(AddtlNtryInf), 'Transaction ID: ')">
                  <xsl:value-of select="substring-after(normalize-space(AddtlNtryInf), 'Transaction ID: ')"/>
                </xsl:when>
                <!-- Fallback: AddtlNtryInf as is -->
                <xsl:otherwise>
                  <xsl:value-of select="normalize-space(AddtlNtryInf)"/>
                </xsl:otherwise>
              </xsl:choose>
            </MEMO>
          </STMTTRN>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- Handle individual transactions within a batch -->
  <xsl:template match="TxDtls" mode="batch">
    <xsl:param name="parentNtry"/>
    <xsl:param name="fee"/>

    <STMTTRN>
      <TRNTYPE>
        <xsl:if test="$parentNtry/CdtDbtInd = 'CRDT'">CREDIT</xsl:if>
        <xsl:if test="$parentNtry/CdtDbtInd = 'DBIT'">DEBIT</xsl:if>
      </TRNTYPE>
      <DTPOSTED>
        <xsl:value-of select="translate($parentNtry/ValDt/Dt,'-','')"/>
      </DTPOSTED>
      <TRNAMT>
        <xsl:if test="$parentNtry/CdtDbtInd != 'CRDT'">-</xsl:if><xsl:value-of select="Amt"/>
      </TRNAMT>
      <FITID>
        <xsl:value-of select="Refs/AcctSvcrRef"/>
      </FITID>
      <REFNUM>
        <xsl:value-of select="normalize-space(Refs/Prtry/Ref)"/>
      </REFNUM>
      <NAME>
        <xsl:choose>
          <!-- For CREDIT transactions, show the DEBTOR (who is paying us) -->
          <xsl:when test="$parentNtry/CdtDbtInd = 'CRDT'">
            <xsl:value-of select="RltdPties/Dbtr/Pty/Nm"/>
            <!-- Backward compatibility: also try the old path structure -->
            <xsl:value-of select="RltdPties/Dbtr/Nm"/>
          </xsl:when>
          <!-- For DEBIT transactions, show the CREDITOR (who we are paying) -->
          <xsl:when test="$parentNtry/CdtDbtInd = 'DBIT'">
            <xsl:value-of select="RltdPties/Cdtr/Pty/Nm"/>
            <!-- Backward compatibility: also try the old path structure -->
            <xsl:value-of select="RltdPties/Cdtr/Nm"/>
          </xsl:when>
        </xsl:choose>
      </NAME>
      <MEMO>
        <xsl:choose>
          <!-- First priority: Ustrd from RmtInf (most descriptive) -->
          <xsl:when test="normalize-space(RmtInf/Ustrd) != ''">
            <xsl:value-of select="normalize-space(RmtInf/Ustrd)"/>
          </xsl:when>
          <!-- Second priority: AddtlTxInf -->
          <xsl:when test="normalize-space(AddtlTxInf) != ''">
            <xsl:value-of select="normalize-space(AddtlTxInf)"/>
          </xsl:when>
          <!-- Fallback: parent AddtlNtryInf -->
          <xsl:otherwise>
            <xsl:value-of select="normalize-space($parentNtry/AddtlNtryInf)"/>
          </xsl:otherwise>
        </xsl:choose>
      </MEMO>
    </STMTTRN>
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
                <xsl:value-of select="normalize-space(/Document/BkToCstmrStmt/Stmt/Acct/Id)"/>
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