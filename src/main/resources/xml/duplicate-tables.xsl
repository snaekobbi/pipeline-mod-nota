<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all"
                version="2.0">
    
    <xsl:template match="dtb:table[@class='render_by_both']|
                         html:table[@class='render_by_both']">
        <xsl:element name="p" namespace="{namespace-uri(.)}">
            <xsl:attribute name="style" select="'margin-top: 1; margin-bottom: 1; text-indent: 0'"/>
            Tabellen vist rækkevis:
        </xsl:element>
        <xsl:copy>
            <xsl:attribute name="class" select="'render_by_row'"/>
            <xsl:sequence select="@* except @class"/>
            <xsl:apply-templates/>
        </xsl:copy>
        <xsl:element name="p" namespace="{namespace-uri(.)}">
            <xsl:attribute name="style" select="'margin-top: 1; margin-bottom: 1; text-indent: 0'"/>
            Tabellen vist kolonnevis:
        </xsl:element>
        <xsl:copy>
            <xsl:attribute name="class" select="'render_by_column'"/>
            <xsl:sequence select="@* except @class"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()">
        <xsl:copy>
            <xsl:sequence select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
