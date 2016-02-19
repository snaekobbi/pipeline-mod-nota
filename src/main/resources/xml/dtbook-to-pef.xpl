<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="nota:dtbook-to-pef" version="1.0"
                xmlns:nota="http://www.nota.dk"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                exclude-inline-prefixes="#all"
                name="main">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">DTBook to PEF (Nota)</h1>
        <p px:role="desc">Transforms a DTBook (DAISY 3 XML) document into a PEF.</p>
    </p:documentation>
    
    <p:input port="source"/>
    <p:option name="output-dir"/>
    <p:option name="temp-dir"/>
    
    <p:option name="stylesheet"/>
    
    <p:option name="contraction-grade" required="false" px:data-type="nota:grade" select="'1'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Translation/formatting of text: Contraction grade</h2>
            <p px:role="desc">`1` (uncontracted) or `2` (contracted).</p>
        </p:documentation>
    </p:option>
    
    <p:option name="ascii-table"/>
    <p:option name="include-preview"/>
    <p:option name="include-brf"/>
    
    <p:option name="page-width"/>
    <p:option name="page-height"/>
    <p:option name="predefined-page-formats"/>
    <p:option name="left-margin"/>
    <p:option name="duplex"/>
    <p:option name="levels-in-footer"/>
    <p:option name="main-document-language"/>
    <p:option name="hyphenation-with-single-line-spacing"/>
    <p:option name="hyphenation-with-double-line-spacing"/>
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
    <p:option name="number-of-pages"/>
    <p:option name="maximum-number-of-pages"/>
    <p:option name="minimum-number-of-pages"/>
    <p:option name="sbsform-macros"/>
    
    <p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/dtbook-to-pef.xpl"/>
    
    <px:dtbook-to-pef>
        <p:with-option name="output-dir" select="$output-dir"/>
        <p:with-option name="temp-dir" select="$temp-dir"/>
        <p:with-option name="stylesheet" select="$stylesheet"/>
        <p:with-option name="transform" select="concat('(formatter:dotify)(translator:nota)(grade:',$contraction-grade,')')"/>
        <p:with-option name="ascii-table" select="$ascii-table"/>
        <p:with-option name="include-preview" select="$include-preview"/>
        <p:with-option name="include-brf" select="$include-brf"/>
        <p:with-option name="page-width" select="$page-width"/>
        <p:with-option name="page-height" select="$page-height"/>
        <p:with-option name="predefined-page-formats" select="$predefined-page-formats"/>
        <p:with-option name="left-margin" select="$left-margin"/>
        <p:with-option name="duplex" select="$duplex"/>
        <p:with-option name="levels-in-footer" select="$levels-in-footer"/>
        <p:with-option name="main-document-language" select="$main-document-language"/>
        <p:with-option name="hyphenation-with-single-line-spacing" select="$hyphenation-with-single-line-spacing"/>
        <p:with-option name="hyphenation-with-double-line-spacing" select="$hyphenation-with-double-line-spacing"/>
        <p:with-option name="line-spacing" select="$line-spacing"/>
        <p:with-option name="tab-width" select="$tab-width"/>
        <p:with-option name="capital-letters" select="$capital-letters"/>
        <p:with-option name="accented-letters" select="$accented-letters"/>
        <p:with-option name="polite-forms" select="$polite-forms"/>
        <p:with-option name="downshift-ordinal-numbers" select="$downshift-ordinal-numbers"/>
        <p:with-option name="include-captions" select="$include-captions"/>
        <p:with-option name="include-images" select="$include-images"/>
        <p:with-option name="include-image-groups" select="$include-image-groups"/>
        <p:with-option name="include-line-groups" select="$include-line-groups"/>
        <p:with-option name="text-level-formatting" select="$text-level-formatting"/>
        <p:with-option name="include-note-references" select="$include-note-references"/>
        <p:with-option name="include-production-notes" select="$include-production-notes"/>
        <p:with-option name="show-braille-page-numbers" select="$show-braille-page-numbers"/>
        <p:with-option name="show-print-page-numbers" select="$show-print-page-numbers"/>
        <p:with-option name="force-braille-page-break" select="$force-braille-page-break"/>
        <p:with-option name="toc-depth" select="$toc-depth"/>
        <p:with-option name="ignore-document-title" select="$ignore-document-title"/>
        <p:with-option name="include-symbols-list" select="$include-symbols-list"/>
        <p:with-option name="choice-of-colophon" select="$choice-of-colophon"/>
        <p:with-option name="footnotes-placement" select="$footnotes-placement"/>
        <p:with-option name="colophon-metadata-placement" select="$colophon-metadata-placement"/>
        <p:with-option name="rear-cover-placement" select="$rear-cover-placement"/>
        <p:with-option name="number-of-pages" select="$number-of-pages"/>
        <p:with-option name="maximum-number-of-pages" select="$maximum-number-of-pages"/>
        <p:with-option name="minimum-number-of-pages" select="$minimum-number-of-pages"/>
        <p:with-option name="sbsform-macros" select="$sbsform-macros"/>
    </px:dtbook-to-pef>
    
</p:declare-step>

