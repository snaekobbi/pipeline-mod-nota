<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:html="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/transform/block-translator-template.xsl"/>
	
	<xsl:param name="query" required="yes"/>
	
	<xsl:template match="css:block" mode="#default before after">
		<xsl:variable name="text" as="text()*" select="//text()"/>
		<xsl:variable name="style" as="xs:string*">
			<xsl:for-each select="$text">
				<xsl:variable name="inline-style" as="element()*"
				              select="css:computed-properties($inline-properties, true(), parent::*)"/>
				<xsl:variable name="transform" as="xs:string?"
				              select="if (ancestor::html:strong) then 'louis-bold' else
				                      if (ancestor::html:em) then 'louis-ital' else ()"/>
				<xsl:variable name="inline-style" as="element()*"
				              select="if ($transform) then ($inline-style,css:property('transform',$transform)) else $inline-style"/>
				<xsl:sequence select="css:serialize-declaration-list($inline-style[not(@value=css:initial-value(@name))])"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:apply-templates select="node()[1]" mode="treewalk">
			<xsl:with-param name="new-text-nodes" select="pf:text-transform($query,$text,$style)"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="css:property[@name=('font-style','font-weight','text-decoration','color')]"
	              mode="translate-declaration-list"/>
	
	<xsl:template match="css:property[@name='hyphens' and @value='auto']" mode="translate-declaration-list">
		<xsl:sequence select="css:property('hyphens','manual')"/>
	</xsl:template>
	
</xsl:stylesheet>
