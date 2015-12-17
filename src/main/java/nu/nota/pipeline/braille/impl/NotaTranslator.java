package nu.nota.pipeline.braille.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.net.URI;

import com.google.common.base.Objects;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;

import org.daisy.pipeline.braille.common.AbstractBrailleTranslator;
import org.daisy.pipeline.braille.common.AbstractTransformProvider;
import org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Function;
import org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables.concat;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables.transform;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.logCreate;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.logSelect;
import org.daisy.pipeline.braille.common.BrailleTranslator;
import org.daisy.pipeline.braille.common.BrailleTranslatorProvider;
import org.daisy.pipeline.braille.common.Query;
import org.daisy.pipeline.braille.common.Query.Feature;
import org.daisy.pipeline.braille.common.Query.MutableQuery;
import static org.daisy.pipeline.braille.common.Query.util.mutableQuery;
import org.daisy.pipeline.braille.common.TransformProvider;
import static org.daisy.pipeline.braille.common.TransformProvider.util.dispatch;
import static org.daisy.pipeline.braille.common.TransformProvider.util.memoize;
import static org.daisy.pipeline.braille.common.util.Locales.parseLocale;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.libhyphen.LibhyphenHyphenator;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

public interface NotaTranslator {
	
	@Component(
		name = "nu.nota.pipeline.braille.impl.NotaTranslatorProvider",
		service = {
			TransformProvider.class,
			BrailleTranslatorProvider.class
		}
	)
	public class Provider extends AbstractTransformProvider<BrailleTranslator> implements BrailleTranslatorProvider<BrailleTranslator> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
		}
		
		private final static Query uncontractedTable = mutableQuery().add("liblouis-table", "http://www.liblouis.org/tables/da-dk-g16.utb");
		private final static Query contractedTable = mutableQuery().add("liblouis-table", "http://www.liblouis.org/tables/da-dk-g26.ctb");
		private final static Query hyphenTable = mutableQuery().add("libhyphen-table",
		                                                            "http://www.libreoffice.org/dictionaries/hyphen/hyph_da_DK.dic");
		
		private final static Iterable<BrailleTranslator> empty = Iterables.<BrailleTranslator>empty();
		
		private final static List<String> supportedInput = ImmutableList.of("css","text-css","dtbook","html");
		private final static List<String> supportedOutput = ImmutableList.of("css","braille");
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `nota'.
		 * - locale: Will only match if the language subtag is 'da'.
		 * - grade: `1' or `2'.
		 *
		 */
		protected final Iterable<BrailleTranslator> _get(Query query) {
			final MutableQuery q = mutableQuery(query);
			for (Feature f : q.removeAll("input"))
				if (!supportedInput.contains(f.getValue().get()))
					return empty;
			for (Feature f : q.removeAll("output"))
				if (!supportedOutput.contains(f.getValue().get()))
					return empty;
			if (q.containsKey("locale"))
				if (!"da".equals(parseLocale(q.removeOnly("locale").getValue().get()).getLanguage()))
					return empty;
			if (q.containsKey("translator"))
				if ("nota".equals(q.removeOnly("translator").getValue().get()))
					if (q.containsKey("grade")) {
						String v = q.removeOnly("grade").getValue().get();
						final int grade;
						if (v.equals("1"))
							grade = 1;
						else if (v.equals("2"))
							grade = 2;
						else
							return empty;
						if (q.isEmpty()) {
							Iterable<LibhyphenHyphenator> hyphenators = logSelect(hyphenTable, libhyphenHyphenatorProvider);
							final Query liblouisTable = grade == 1 ? uncontractedTable : contractedTable;
							return concat(
								transform(
									hyphenators,
									new Function<LibhyphenHyphenator,Iterable<BrailleTranslator>>() {
										public Iterable<BrailleTranslator> _apply(LibhyphenHyphenator h) {
											return transform(
												logSelect(mutableQuery(liblouisTable).add("hyphenator", h.getIdentifier()),
												          liblouisTranslatorProvider),
												new Function<LiblouisTranslator,BrailleTranslator>() {
													public BrailleTranslator _apply(LiblouisTranslator translator) {
														return __apply(logCreate(new TransformImpl(grade, translator))); }}); }})); }}
			return empty;
		}
		
		private class TransformImpl extends AbstractBrailleTranslator {
			
			private final LiblouisTranslator translator;
			private final XProc xproc;
			private final int grade;
			
			private TransformImpl(int grade, LiblouisTranslator translator) {
				Map<String,String> options = ImmutableMap.of("query", mutableQuery().add("id", this.getIdentifier()).toString());
				xproc = new XProc(href, null, options);
				this.grade = grade;
				this.translator = translator;
			}
			
			@Override
			public XProc asXProc() {
				return xproc;
			}
			
			@Override
			public FromStyledTextToBraille fromStyledTextToBraille() {
				return fromStyledTextToBraille;
			}
			
			private final FromStyledTextToBraille fromStyledTextToBraille = new FromStyledTextToBraille() {
				public java.lang.Iterable<String> transform(java.lang.Iterable<CSSStyledText> styledText) {
					return translator.fromStyledTextToBraille().transform(styledText);
				}
			};
			
			@Override
			public String toString() {
				return Objects.toStringHelper(NotaTranslator.class.getSimpleName())
					.add("grade", grade)
					.add("id", getIdentifier())
					.toString();
			}
		}
		
		@Reference(
			name = "LiblouisTranslatorProvider",
			unbind = "unbindLiblouisTranslatorProvider",
			service = LiblouisTranslator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		protected void bindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.add(provider);
		}
	
		protected void unbindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.remove(provider);
			liblouisTranslatorProvider.invalidateCache();
		}
	
		private List<TransformProvider<LiblouisTranslator>> liblouisTranslatorProviders
		= new ArrayList<TransformProvider<LiblouisTranslator>>();
		private TransformProvider.util.MemoizingProvider<LiblouisTranslator> liblouisTranslatorProvider
		= memoize(dispatch(liblouisTranslatorProviders));
		
		@Reference(
			name = "LibhyphenHyphenatorProvider",
			unbind = "unbindLibhyphenHyphenatorProvider",
			service = LibhyphenHyphenator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		protected void bindLibhyphenHyphenatorProvider(LibhyphenHyphenator.Provider provider) {
			libhyphenHyphenatorProviders.add(provider);
		}
	
		protected void unbindLibhyphenHyphenatorProvider(LibhyphenHyphenator.Provider provider) {
			libhyphenHyphenatorProviders.remove(provider);
			libhyphenHyphenatorProvider.invalidateCache();
		}
	
		private List<TransformProvider<LibhyphenHyphenator>> libhyphenHyphenatorProviders
		= new ArrayList<TransformProvider<LibhyphenHyphenator>>();
		private TransformProvider.util.MemoizingProvider<LibhyphenHyphenator> libhyphenHyphenatorProvider
		= memoize(dispatch(libhyphenHyphenatorProviders));
		
	}
}
