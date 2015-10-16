package nu.nota.pipeline.braille.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URI;
import javax.xml.namespace.QName;

import com.google.common.base.Objects;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.AbstractTransform;
import org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Function;
import org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables.concat;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables.transform;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.logCreate;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.logSelect;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.TextTransform;
import org.daisy.pipeline.braille.common.Transform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.memoize;
import static org.daisy.pipeline.braille.common.util.Locales.parseLocale;
import org.daisy.pipeline.braille.common.XProcTransform;
import org.daisy.pipeline.braille.libhyphen.LibhyphenHyphenator;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

public interface NotaCSSBlockTransform extends CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "nu.nota.pipeline.braille.impl.NotaCSSBlockTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider extends AbstractTransform.Provider<NotaCSSBlockTransform>
		                  implements XProcTransform.Provider<NotaCSSBlockTransform>, CSSBlockTransform.Provider<NotaCSSBlockTransform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
		}
		
		private final static String uncontractedTable = "(liblouis-table:'http://www.liblouis.org/tables/da-dk-g16.utb')";
		private final static String contractedTable = "(liblouis-table:'http://www.liblouis.org/tables/da-dk-g26.ctb')";
		private final static String hyphenationTable = "(libhyphen-table:'http://www.libreoffice.org/dictionaries/hyphen/hyph_da_DK.dic')";
		
		private final static Iterable<NotaCSSBlockTransform> empty = Iterables.<NotaCSSBlockTransform>empty();
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `nota'.
		 * - locale: Will only match if the language subtag is 'da'.
		 * - grade: `1' or `2'.
		 *
		 */
		protected final Iterable<NotaCSSBlockTransform> _get(String query) {
			Map<String,Optional<String>> q = new HashMap<String,Optional<String>>(parseQuery(query));
			Optional<String> o;
			if ((o = q.remove("locale")) != null)
				if (!"da".equals(parseLocale(o.get()).getLanguage()))
					return empty;
			if ((o = q.remove("translator")) != null)
				if (o.get().equals("nota"))
					if ((o = q.remove("grade")) != null) {
						final int grade;
						if (o.get().equals("1"))
							grade = 1;
						else if (o.get().equals("2"))
							grade = 2;
						else
							return empty;
						if (q.size() == 0) {
							Iterable<LibhyphenHyphenator> hyphenators = logSelect(hyphenationTable, libhyphenHyphenatorProvider);
							final String liblouisTable = grade == 1 ? uncontractedTable : contractedTable;
							return concat(
								transform(
									hyphenators,
									new Function<LibhyphenHyphenator,Iterable<NotaCSSBlockTransform>>() {
										public Iterable<NotaCSSBlockTransform> _apply(LibhyphenHyphenator h) {
											final String translatorQuery = liblouisTable + "(hyphenator:" + h.getIdentifier() + ")";
											return transform(
												logSelect(translatorQuery, liblouisTranslatorProvider),
												new Function<LiblouisTranslator,NotaCSSBlockTransform>() {
													public NotaCSSBlockTransform _apply(LiblouisTranslator translator) {
														return __apply(logCreate(new TransformImpl(grade, translatorQuery, translator))); }}); }})); }}
			return empty;
		}
		
		private class TransformImpl extends AbstractTransform implements NotaCSSBlockTransform {
			
			private final LiblouisTranslator translator;
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			private final int grade;
			
			private TransformImpl(int grade, String translatorQuery, LiblouisTranslator translator) {
				Map<String,String> options = ImmutableMap.of("query", translatorQuery);
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
				this.grade = grade;
				this.translator = translator;
			}
			
			public TextTransform asTextTransform() {
				return translator;
			}
			
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
	
			@Override
			public String toString() {
				return Objects.toStringHelper(NotaCSSBlockTransform.class.getSimpleName())
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
	
		private List<Transform.Provider<LiblouisTranslator>> liblouisTranslatorProviders
		= new ArrayList<Transform.Provider<LiblouisTranslator>>();
		private Transform.Provider.MemoizingProvider<LiblouisTranslator> liblouisTranslatorProvider
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
	
		private List<Transform.Provider<LibhyphenHyphenator>> libhyphenHyphenatorProviders
		= new ArrayList<Transform.Provider<LibhyphenHyphenator>>();
		private Transform.Provider.MemoizingProvider<LibhyphenHyphenator> libhyphenHyphenatorProvider
		= memoize(dispatch(libhyphenHyphenatorProviders));
		
	}
}
