package nu.nota.pipeline.braille.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.net.URI;
import javax.xml.namespace.QName;

import static com.google.common.base.Objects.toStringHelper;
import static com.google.common.collect.Iterables.transform;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.Transform;
import org.daisy.pipeline.braille.common.Transform.AbstractTransform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.logCreate;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.logSelect;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.memoize;
import static org.daisy.pipeline.braille.common.util.Locales.parseLocale;
import org.daisy.pipeline.braille.common.WithSideEffect;
import org.daisy.pipeline.braille.common.XProcTransform;
import org.daisy.pipeline.braille.libhyphen.LibhyphenHyphenator;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

import org.slf4j.Logger;

public interface NotaCSSBlockTransform extends CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "nu.nota.pipeline.braille.impl.NotaCSSBlockTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider implements XProcTransform.Provider<NotaCSSBlockTransform>, CSSBlockTransform.Provider<NotaCSSBlockTransform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
		}
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `nota'.
		 * - locale: Will only match if the language subtag is 'da'.
		 * - grade: `1' or `2'.
		 *
		 */
		public Iterable<NotaCSSBlockTransform> get(String query) {
			 return impl.get(query);
		 }
	
		public Transform.Provider<NotaCSSBlockTransform> withContext(Logger context) {
			return impl.withContext(context);
		}
	
		private Transform.Provider.MemoizingProvider<NotaCSSBlockTransform> impl = new ProviderImpl(null);
	
		private class ProviderImpl extends AbstractProvider<NotaCSSBlockTransform> {
			
			private final static String uncontractedTable = "(liblouis-table:'http://www.liblouis.org/tables/da-dk-g16.utb')";
			private final static String contractedTable = "(liblouis-table:'http://www.liblouis.org/tables/da-dk-g26.ctb')";
			private final static String hyphenationTable = "(libhyphen-table:'http://www.libreoffice.org/dictionaries/hyphen/hyph_da_DK.dic')";
		
			private ProviderImpl(Logger context) {
				super(context);
			}
		
			protected Transform.Provider.MemoizingProvider<NotaCSSBlockTransform> _withContext(Logger context) {
				return new ProviderImpl(context);
			}
		
			protected final Iterable<WithSideEffect<NotaCSSBlockTransform,Logger>> __get(String query) {
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
								Iterable<WithSideEffect<LibhyphenHyphenator,Logger>> hyphenators
									= logSelect(hyphenationTable, libhyphenHyphenatorProvider.get(hyphenationTable));
								final String liblouisTable = grade == 1 ? uncontractedTable : contractedTable;
								return transform(
									hyphenators,
									new WithSideEffect.Function<LibhyphenHyphenator,NotaCSSBlockTransform,Logger>() {
										public NotaCSSBlockTransform _apply(LibhyphenHyphenator h) {
											String translatorQuery = liblouisTable + "(hyphenator:" + h.getIdentifier() + ")";
											try {
												applyWithSideEffect(
													logSelect(
														translatorQuery,
														liblouisTranslatorProvider.get(translatorQuery)).iterator().next()); }
											catch (NoSuchElementException e) {
												throw new NoSuchElementException(); }
											return applyWithSideEffect(
												logCreate(
													(NotaCSSBlockTransform)new TransformImpl(grade, translatorQuery))); }}); }}
				return empty;
			}
		}
	
		private final static Iterable<WithSideEffect<NotaCSSBlockTransform,Logger>> empty
		= Optional.<WithSideEffect<NotaCSSBlockTransform,Logger>>absent().asSet();
		
		private class TransformImpl extends AbstractTransform implements NotaCSSBlockTransform {
			
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			private final int grade;
			
			private TransformImpl(int grade, String translatorQuery) {
				Map<String,String> options = ImmutableMap.of("query", translatorQuery);
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
				this.grade = grade;
			}
	
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
	
			@Override
			public String toString() {
				return toStringHelper(NotaCSSBlockTransform.class.getSimpleName())
					.add("grade", grade)
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
