<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="nota:dtbook-to-pef" version="1.0"
                xmlns:nota="http://www.nota.dk"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:pef="http://www.daisy.org/ns/2008/pef"
                exclude-inline-prefixes="#all"
                name="main">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">DTBook to PEF (Nota)</h1>
        <p px:role="desc">Transforms a DTBook (DAISY 3 XML) document into a PEF.</p>
    </p:documentation>
    
    <p:input port="source"/>
    
    <!--
        Documentation and default values of options are defined in xml-to-pef.xpl.
    -->
    <p:option name="pef-output-dir"/>
    <p:option name="brf-output-dir"/>
    <p:option name="preview-output-dir"/>
    <p:option name="temp-dir"/>
    <p:option name="stylesheet"/>
    <p:option name="contraction-grade"/>
    <p:option name="ascii-table"/>
    <p:option name="include-brf"/>
    <p:option name="include-preview"/>
    <p:option name="include-obfl"/>
    <p:option name="page-width"/>
    <p:option name="page-height"/>
    <p:option name="left-margin"/>
    <p:option name="duplex"/>
    <p:option name="levels-in-footer"/>
    <p:option name="main-document-language"/>
    <p:option name="hyphenation"/>
    <p:option name="line-spacing"/>
    <p:option name="tab-width"/>
    <p:option name="capital-letters"/>
    <p:option name="accented-letters"/>
    <p:option name="polite-forms"/>
    <p:option name="downshift-ordinal-numbers"/>
    <p:option name="include-captions"/>
    <p:option name="include-images"/>
    <p:option name="include-image-groups"/>
    <p:option name="include-line-groups"/>
    <p:option name="text-level-formatting"/>
    <p:option name="include-note-references"/>
    <p:option name="include-production-notes"/>
    <p:option name="show-braille-page-numbers"/>
    <p:option name="show-print-page-numbers"/>
    <p:option name="force-braille-page-break"/>
    <p:option name="toc-depth"/>
    <p:option name="ignore-document-title"/>
    <p:option name="include-symbols-list"/>
    <p:option name="choice-of-colophon"/>
    <p:option name="footnotes-placement"/>
    <p:option name="colophon-metadata-placement"/>
    <p:option name="rear-cover-placement"/>
    <p:option name="number-of-sheets"/>
    <p:option name="maximum-number-of-sheets"/>
    <p:option name="minimum-number-of-sheets"/>
    
    <p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl"/>
    
    <p:in-scope-names name="in-scope-names"/>
    <p:identity>
        <p:input port="source">
            <p:pipe port="result" step="in-scope-names"/>
        </p:input>
    </p:identity>
    <p:delete match="c:param[@name=('stylesheet',
                                    'ascii-table',
                                    'include-brf',
                                    'include-preview',
                                    'include-obfl',
                                    'pef-output-dir',
                                    'brf-output-dir',
                                    'preview-output-dir',
                                    'temp-dir')]"/>
    <p:identity name="input-options"/>
    <p:sink/>
    
    <!-- =============== -->
    <!-- CREATE TEMP DIR -->
    <!-- =============== -->
    <px:tempdir name="temp-dir">
        <p:with-option name="href" select="if ($temp-dir!='') then $temp-dir else $pef-output-dir"/>
    </px:tempdir>
    <p:sink/>
    
    <!-- ======= -->
    <!-- CONVERT -->
    <!-- ======= -->
    <px:dtbook-to-pef.convert default-stylesheet="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/css/default.css"
                              name="convert">
        <p:input port="source">
            <p:pipe step="main" port="source"/>
        </p:input>
        <p:with-option name="temp-dir" select="string(/c:result)">
            <p:pipe step="temp-dir" port="result"/>
        </p:with-option>
        <p:with-option name="stylesheet" select="string-join((
                                                   'http://www.nota.dk/pipeline/modules/braille/internal/insert-titlepage.xsl',
                                                   'http://www.nota.dk/pipeline/modules/braille/internal/duplicate-tables.xsl',
                                                   'http://www.nota.dk/pipeline/modules/braille/internal/mark-noterefs.xsl',
                                                   $stylesheet),' ')"/>
        <p:with-option name="transform" select="concat('(formatter:dotify)(translator:nota)(grade:',$contraction-grade,')')"/>
        <p:with-option name="include-obfl" select="$include-obfl"/>
        <p:input port="parameters">
            <p:pipe port="result" step="input-options"/>
        </p:input>
    </px:dtbook-to-pef.convert>
    
    <!-- ===== -->
    <!-- STORE -->
    <!-- ===== -->
    <px:dtbook-to-pef.store>
        <p:input port="obfl">
            <p:pipe step="convert" port="obfl"/>
        </p:input>
        <p:with-option name="name" select="replace(p:base-uri(/),'^.*/([^/]*)\.[^/\.]*$','$1')">
            <p:pipe step="main" port="source"/>
        </p:with-option>
        <p:with-option name="include-brf" select="$include-brf"/>
        <p:with-option name="include-preview" select="$include-preview"/>
        <p:with-option name="include-obfl" select="$include-obfl"/>
        <p:with-option name="ascii-table" select="$ascii-table"/>
        <p:with-option name="pef-output-dir" select="$pef-output-dir"/>
        <p:with-option name="brf-output-dir" select="$brf-output-dir"/>
        <p:with-option name="preview-output-dir" select="$preview-output-dir"/>
    </px:dtbook-to-pef.store>
    
</p:declare-step>

