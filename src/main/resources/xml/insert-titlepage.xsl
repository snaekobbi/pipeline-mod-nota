<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns="http://www.daisy.org/z3986/2005/dtbook/"
                xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all"
                version="2.0">
    
    <!-- Parameters -->
    <xsl:param name="contraction-grade" as="xs:string" select="'0'"/>
    
    <!--
        FIXME: these numbers should be generated with CSS
    -->
    <xsl:param name="first-page-in-volume" as="xs:string" select="''"/>
    <xsl:param name="last-page-in-volume" as="xs:string" select="''"/>
    
    <!-- Variables -->
    <xsl:variable name="OUTPUT_NAMESPACE" as="xs:string" select="namespace-uri(/*)"/>
    
    <!-- Fetch metadata: not sure how to do this in the EPUB case, as I don't
        know if/how stuff is copied over; what I would do is copy dc elements
        from the OPF file, so I assume this is the case -->
    <xsl:variable name="AUTHOR" as="xs:string*"
        select="/dtbook/head/meta[@name eq 'dc:creator']/@content|
                /html:html/html:head/dc:creator/text()"/>
    <xsl:variable name="PID" as="xs:string*"
        select="/dtbook/head/meta[@name eq 'dtb:uid']/@content|
                /html:html/html:head/dc:identifier/text()"/>
    <xsl:variable name="SOURCE_ISBN" as="xs:string*"
        select="(/dtbook/head/meta[@name eq 'dc:source']/@content|
                /html:html/html:head/dc:source/text())/replace(
                ., '^urn:isbn:', '')"/>
    <xsl:variable name="TITLE" as="xs:string*"
        select="/dtbook/head/meta[@name eq 'dc:title']/@content|
                /html:html/html:head/dc:title/text()"/>
    
    <xsl:variable name="YEAR" as="xs:integer"
        select="year-from-date(current-date())"/>
    
    <!-- Generic copy-all template -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="TITLE_PAGE_CONTENT">
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="class" select="'author'"/>
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:value-of select="$AUTHOR"/>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="class" select="'title'"/>
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:value-of select="$TITLE"/>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:value-of
                select="if ($contraction-grade eq '0')
                        then 'uforkortet'
                        else if ($contraction-grade eq '1')
                        then 'lille forkortelse'
                        else if ($contraction-grade eq '2')
                        then 'stor forkortelse'
                        else ''"/>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:element name="span" namespace="{$OUTPUT_NAMESPACE}">
                <xsl:attribute name="style" select="'::before { content: -obfl-evaluate(&quot;(round $volume)&quot;); }'"/>
            </xsl:element>
            <xsl:text>. bind af </xsl:text>
            <xsl:element name="span" namespace="{$OUTPUT_NAMESPACE}">
                <xsl:attribute name="style" select="'::before { content: -obfl-evaluate(&quot;(round $volumes)&quot;); }'"/>
            </xsl:element>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            nota<br/>nationalbibliotek for<br/>mennesker med læsevanskeligheder<br/>
            københavn <xsl:value-of select="$YEAR"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="COLOPHON_CONTENT">
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:value-of select="$TITLE"/>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:value-of select="concat('isbn ', $SOURCE_ISBN)"/>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            fejl i punktudgaven kan rapporteres på aub@nota.nu
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:value-of select="$PID"/>
        </xsl:element>
        <xsl:element name="p" namespace="{$OUTPUT_NAMESPACE}">
            <xsl:attribute name="style" select="'display:block'"/>
            <xsl:element name="span" namespace="{$OUTPUT_NAMESPACE}">
                <xsl:attribute name="style" select="'::before { content: -obfl-evaluate(&quot;(round $volume)&quot;); }'"/>
            </xsl:element>
            <xsl:value-of select="concat('. punktbind: ', $first-page-in-volume, '-', $last-page-in-volume)"/>
        </xsl:element>
    </xsl:template>
    
    <!-- DTBook template: note lack of proper namespace -->
    <xsl:template match="frontmatter/doctitle">
        <xsl:next-match/>
        <level depth="1"
               class="title_page"
               style="display:block; text-align:center; page-break-after: always; page-break-inside: avoid; flow: titlepage">
            <xsl:call-template name="TITLE_PAGE_CONTENT"/>
        </level>
        <level depth="1"
               class="colophon"
               style="display:block; page-break-after: always; page-break-inside: avoid; flow: colophon">
            <xsl:call-template name="COLOPHON_CONTENT"/>
        </level>
    </xsl:template>
    
    <!-- XHTML template: once again I'm unsure of the structure of the input
        document, so this is just a guess as to where the document begins -->
    <xsl:template match="html:body">
        <xsl:copy>
            <xsl:sequence select="@*"/>
            <section xmlns="http://www.w3.org/1999/xhtml"
                     class="title_page"
                     style="display:block; text-align:center; page-break-after: always; page-break-inside: avoid; flow: titlepage">
                <xsl:call-template name="TITLE_PAGE_CONTENT"/>
            </section>
            <section xmlns="http://www.w3.org/1999/xhtml"
                     class="colophon"
                     style="display:block; page-break-after: always; page-break-inside: avoid; flow: colophon">
                <xsl:call-template name="COLOPHON_CONTENT"/>
            </section>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
