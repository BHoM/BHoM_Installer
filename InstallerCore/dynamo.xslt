<xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:msxsl="urn:schemas-microsoft-com:xslt"
            exclude-result-prefixes="msxsl"
            xmlns:wix="http://schemas.microsoft.com/wix/2006/wi"
            xmlns:my="my:my">

  <xsl:output method="xml" indent="yes" />

  <xsl:strip-space elements="*"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match='wix:Wix/wix:Fragment/wix:ComponentGroup/wix:Component[@Directory="DYNC13BHOMDIR"]/wix:File'>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:element name="wix:CopyFile">
        <xsl:attribute name="Id">
          <xsl:text>CpyDYNR13_</xsl:text>
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
        <xsl:attribute name="DestinationDirectory">
          <xsl:text>DYNR13BHOMDIR</xsl:text>
        </xsl:attribute>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
  <xsl:template match='wix:Wix/wix:Fragment/wix:ComponentGroup/wix:Component[@Directory="DYNC20BHOMDIR"]/wix:File'>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:element name="wix:CopyFile">
        <xsl:attribute name="Id">
          <xsl:text>CpyDYNR20_</xsl:text>
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
        <xsl:attribute name="DestinationDirectory">
          <xsl:text>DYNR20BHOMDIR</xsl:text>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="wix:CopyFile">
        <xsl:attribute name="Id">
          <xsl:text>CpyDYNR23_</xsl:text>
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
        <xsl:attribute name="DestinationDirectory">
          <xsl:text>DYNR23BHOMDIR</xsl:text>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="wix:CopyFile">
        <xsl:attribute name="Id">
          <xsl:text>CpyDYNC23_</xsl:text>
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
        <xsl:attribute name="DestinationDirectory">
          <xsl:text>DYNC23BHOMDIR</xsl:text>
        </xsl:attribute>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
