<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/transform/block-translator-template.xsl"/>
	
	<xsl:param name="text-transform" required="yes"/>
	
	<xsl:template match="css:block" mode="#default before after">
		<xsl:variable name="text" as="text()*" select="//text()"/>
		<xsl:variable name="style" as="xs:string*">
			<xsl:for-each select="$text">
				<xsl:variable name="inline-style" as="element()*"
				              select="css:computed-properties($inline-properties[not(.='word-spacing')], true(), parent::*)"/>
				<xsl:sequence select="css:serialize-declaration-list($inline-style[not(@value=css:initial-value(@name))])"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="new-text-nodes" as="xs:string*">
			<xsl:apply-templates select="node()[1]" mode="emphasis">
				<xsl:with-param name="segments" select="pf:text-transform($text-transform,$text,$style)"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:apply-templates select="node()[1]" mode="treewalk">
			<xsl:with-param name="new-text-nodes" select="$new-text-nodes"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="css:property[@name=('letter-spacing',
	                                         'font-style',
	                                         'font-weight',
	                                         'text-decoration',
	                                         'color')]"
	              mode="translate-declaration-list"/>
	
	<xsl:template match="css:property[@name='text-transform']" mode="translate-declaration-list">
		<css:property name="text-transform" value="none"/>
	</xsl:template>
	
	<xsl:template match="css:property[@name='hyphens' and @value='auto']" mode="translate-declaration-list">
		<xsl:sequence select="css:property('hyphens','manual')"/>
	</xsl:template>
	
	<xsl:template match="*" mode="emphasis" as="xs:string*">
		<xsl:param name="segments" as="xs:string*" required="yes"/>
		<xsl:variable name="text-node-count" select="count(.//text())"/>
		<xsl:apply-templates select="child::node()[1]" mode="#current">
			<xsl:with-param name="segments" select="$segments[position()&lt;=$text-node-count]"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="following-sibling::node()[1]" mode="#current">
			<xsl:with-param name="segments" select="$segments[position()&gt;$text-node-count]"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="text()" mode="emphasis" as="xs:string*">
		<xsl:param name="segments" as="xs:string*" required="yes"/>
		<xsl:value-of select="$segments[1]"/>
		<xsl:apply-templates select="following-sibling::node()[1]" mode="#current">
			<xsl:with-param name="segments" select="$segments[position()&gt;1]"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="html:em     | dtb:em     |
	                     html:strong | dtb:strong"
	              mode="emphasis" as="xs:string*">
		<xsl:param name="segments" as="xs:string*" required="yes"/>
		<xsl:call-template name="mark-emphasis">
			<xsl:with-param name="segments" select="$segments"/>
			<xsl:with-param name="opening-mark" select="'⠰'"/>
			<xsl:with-param name="closing-mark" select="'⠰'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="mark-emphasis">
		<xsl:param name="segments" as="xs:string*" required="yes"/>
		<xsl:param name="opening-mark" as="xs:string" required="yes"/>
		<xsl:param name="closing-mark" as="xs:string" required="yes"/>
		<xsl:variable name="text-node-count" select="count(.//text())"/>
		<xsl:variable name="segments-inside" as="xs:string*">
			<xsl:apply-templates select="child::node()[1]" mode="#current">
				<xsl:with-param name="segments" select="$segments[position()&lt;=$text-node-count]"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:for-each-group select="$segments-inside" group-adjacent="matches(.,'^[\s&#x2800;]*$')">
			<xsl:choose>
				<xsl:when test="current-grouping-key()">
					<xsl:sequence select="current-group()"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="segments" as="xs:string*" select="current-group()"/>
					<xsl:variable name="segments" as="xs:string*">
						<xsl:choose>
							<xsl:when test="position()=(1,2)">
								<xsl:sequence select="replace($segments[1],'^([\s&#x2800;]*)([^\s&#x2800;].*)$',concat('$1',$opening-mark,'$2'))"/>
								<xsl:sequence select="$segments[position()&gt;1]"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:sequence select="current-group()"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="segments" as="xs:string*">
						<xsl:choose>
							<xsl:when test="(last() - position())=(0,1)">
								<xsl:sequence select="$segments[position()&lt;last()]"/>
								<xsl:sequence select="replace($segments[last()],'^(.*[^\s&#x2800;])([\s&#x2800;]*)$',concat('$1',$closing-mark,'$2'))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:sequence select="current-group()"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:sequence select="$segments"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each-group>
		<xsl:apply-templates select="following-sibling::node()[1]" mode="#current">
			<xsl:with-param name="segments" select="$segments[position()&gt;$text-node-count]"/>
		</xsl:apply-templates>
	</xsl:template>
	
</xsl:stylesheet>
