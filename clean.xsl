<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- This XSLT will pretty-print (indent) the output XML -->
  <xsl:output method="xml" indent="yes"/>

  <!-- This template strips namespaces from all elements by recreating them without namespace -->
  <xsl:template match="*">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <!-- This template strips namespaces from all attributes by recreating them without namespace -->
  <xsl:template match="@*">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- Copy comments, processing instructions, and text nodes as-is -->
  <xsl:template match="comment()|processing-instruction()|text()">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet> 