# ISO20022 CAMT.053 to OFX bank statement XML convertor

This simple webpage loads the bank statement with account balance and all transactions - exported as an XML file from an European (esp. Swiss) online banking systems in [ISO20022](https://www.iso20022.org/) SEPA [camt.053 XML format](https://www.six-group.com/dam/download/banking-services/standardization/sps/ig-cash-management-delta-guide-sps2022-en.pdf), it transforms the data and generates [Open Financial Exchange (OFX)](https://financialdataexchange.org/ofx) format suitable for import into [Xero](https://www.xero.com/) and other accounting and financial systems.

Secure - your data are not submitted anywhere. Conversion happens directly in your web browser locally using in-browser XSLT transformation (camt2ofx.xsl) without any server.

Open-source code including the XSL transformation itself is available at https://github.com/maptiler/iso2ofx. 

Available online at:
[https://labs.maptiler.com/iso2ofx/](https://labs.maptiler.com/iso2ofx/)