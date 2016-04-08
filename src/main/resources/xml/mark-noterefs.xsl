<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all"
                version="2.0">
    
    <xsl:template match="dtb:noteref">
        <xsl:copy>
            <xsl:sequence select="@* except @class"/>
            <xsl:variable name="class" as="xs:string*">
                <xsl:sequence select="tokenize(@class,'\s+')[not(.='')]"/>
                <xsl:variable name="idref" as="xs:string" select="@idref"/>
                <xsl:variable name="note" as="element()" select="//dtb:note[@id=$idref]"/>
                <xsl:sequence select="tokenize($note/@class,'\s+')[.=('footnote','endnote')]"/>
            </xsl:variable>
            <xsl:if test="exists($class)">
                <xsl:attribute name="class" select="string-join($class,' ')"/>
            </xsl:if>
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
