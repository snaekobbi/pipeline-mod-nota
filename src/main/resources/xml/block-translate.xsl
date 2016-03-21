<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/transform/block-translator-template.xsl"/>
	
	<xsl:param name="text-transform" required="yes"/>
	
	<xsl:template match="css:block" mode="#default before after">
		<xsl:variable name="text" as="text()*" select="//text()"/>
		<xsl:variable name="style" as="xs:string*">
			<xsl:for-each select="$text">
				<xsl:variable name="inline-style" as="element()*"
				              select="css:computed-properties($inline-properties, true(), parent::*)"/>
				<xsl:variable name="inline-style" as="element()*">
					<xsl:variable name="lang" as="xs:string" select="pxi:lang(parent::*)"/>
					<xsl:variable name="danish" as="xs:boolean" select="tokenize($lang,'-')[1]='da'"/>
					<xsl:apply-templates select="$inline-style" mode="property">
						<xsl:with-param name="danish" select="$danish"/>
					</xsl:apply-templates>
					<xsl:if test="not($danish) and not($inline-style[@name='text-transform'])">
						<css:property name="text-transform" value="uncontracted"/>
					</xsl:if>
				</xsl:variable>
				<xsl:sequence select="css:serialize-declaration-list($inline-style)"/>
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
	
	<xsl:template match="css:property" mode="property">
		<xsl:if test="not(@value=css:initial-value(@name))">
			<xsl:sequence select="."/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="css:property[@name='text-transform' and not(@value='none')]" mode="property">
		<xsl:param name="danish" as="xs:boolean" select="true()"/>
		<xsl:choose>
			<xsl:when test="not($danish)">
				<xsl:variable name="value" as="xs:string*" select="tokenize(@value,'\s+')[not(.=('','auto'))]"/>
				<css:property name="text-transform" value="{string-join(($value,'uncontracted'),' ')}"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="css:property[@name='word-spacing']" mode="property"/>
	
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
