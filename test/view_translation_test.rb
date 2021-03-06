require File.dirname(__FILE__) + '/test_helper'

class ViewTranslationTest < Test::Unit::TestCase
  include Globalize

  fixtures :globalize_languages, :globalize_countries, :globalize_translations

  def setup
    Globalize::Locale.set("en-US")
    Globalize::Locale.set_base_language("en-US")
  end

  def test_translate
    assert_equal "This is the default", "This is the default".t
    Locale.set("he-IL")
    assert_equal "This is the default", "This is the default".t
    assert_equal "ועכשיו בעברית", "And now in Hebrew".t
  end

  def test_plural
    Locale.set("pl-PL")
    assert_equal "1 plik", "%d file" / 1
    assert_equal "2 pliki", "%d file" / 2
    assert_equal "3 pliki", "%d file" / 3
    assert_equal "4 pliki", "%d file" / 4

    assert_equal "5 plików", "%d file" / 5
    assert_equal "8 plików", "%d file" / 8
    assert_equal "13 plików", "%d file" / 13
    assert_equal "21 plików", "%d file" / 21

    assert_equal "22 pliki", "%d file" / 22
    assert_equal "23 pliki", "%d file" / 23
    assert_equal "24 pliki", "%d file" / 24

    assert_equal "25 plików", "%d file" / 25
    assert_equal "31 plików", "%d file" / 31
  end

  def test_aliases
    Locale.set("he-IL")
    assert_equal "ועכשיו בעברית", "And now in Hebrew".translate
    assert_equal "ועכשיו בעברית", _("And now in Hebrew")
  end

  def test_set_translation
    assert_equal "a dark and stormy night", "a dark and stormy night".t
    Locale.set_translation("a dark and stormy night", "quite a dark and stormy night")
    assert_equal "quite a dark and stormy night", "a dark and stormy night".t

    Locale.set("he-IL")
    assert_equal "a dark and stormy night", "a dark and stormy night".t
    Locale.set_translation("a dark and stormy night", "ליל קודר וגועש")
    assert_equal "ליל קודר וגועש", "a dark and stormy night".t
    polish = Language.pick("pl")

    Locale.set_translation("a dark and stormy night", polish, "How do you say this in Polish?")

    Locale.set("en-US")
    assert_equal "quite a dark and stormy night", "a dark and stormy night".t
    Locale.set("pl-PL")
    assert_equal "How do you say this in Polish?", "a dark and stormy night".t
  end

  def test_set_translation_pl
    Locale.set_translation("%d dark and stormy nights", "quite a dark and stormy night",
      "%d dark and stormy nights")
    assert_equal "quite a dark and stormy night", "%d dark and stormy nights".t
    assert_equal "5 dark and stormy nights", "%d dark and stormy nights" / 5

    Locale.set("he-IL")
    Locale.set_translation("%d dark and stormy nights",
      [ "ליל קודר וגועש", "%d לילות קודרים וגועשים" ])
    assert_equal "ליל קודר וגועש", "%d dark and stormy nights".t
    assert_equal "7 לילות קודרים וגועשים", "%d dark and stormy nights" / 7

    Locale.set("en-US")
    assert_equal "quite a dark and stormy night", "%d dark and stormy nights".t
  end

	def test_set_pluralized_translation
    Locale.set_pluralized_translation '%d dark and stormy nights', 
      1, 'quite a dark and stormy night'
    Locale.set_pluralized_translation '%d dark and stormy nights', 
      2, 'wow, %d dark and stormy nights'
    assert_equal "quite a dark and stormy night", "%d dark and stormy nights" / 1
    assert_equal "wow, 5 dark and stormy nights", "%d dark and stormy nights" / 5
	end
	
  def test_missed_report
    Locale.set("he-IL")
    assert_nil ViewTranslation.find(:first,
      :conditions => %q{language_id = 2 AND tr_key = 'not in database'})
    assert_equal "not in database", "not in database".t
    result = ViewTranslation.find(:first,
      :conditions => %q{language_id = 2 AND tr_key = 'not in database'})
    assert_not_nil result, "There should be a record in the db with nil text"
    assert_nil result.text
  end

  # for when language doesn't have a translation
  def test_default_number_substitution
    Locale.set("pl-PL")
    assert_equal "There are 0 translations for this",
      "There are %d translations for this" / 0
  end

  # for when language only has one pluralization form for translation
  def test_default_number_substitution2
    Locale.set("he-IL")
    assert_equal "יש לי 5 קבצים", "I have %d files" / 5
  end

  def test_symbol
    Locale.set("he-IL")
    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t
    assert_equal "this is the default", :bogus_translation.t("this is the default")
  end

  def test_syntax_error
    Locale.set("ur")
    assert_raise(SyntaxError) { "I have %d bogus numbers" / 5 }
  end

  def test_illegal_code
    assert_raise(SecurityError) { Locale.set("ba") }
  end

  def test_overflow_code
    assert_raise(SecurityError) { Locale.set("tw") }
  end

  def test_string_substitute
    assert_equal "Welcome, Josh", "welcome, %s" / "Josh"
  end

  def test_zero_form
    Locale.set_translation("%d items in your cart",
      [ "One item in your cart", "%d items in your cart" ], "Your cart is empty")
    assert_equal "8 items in your cart", "%d items in your cart" / 8
    assert_equal "One item in your cart", "%d items in your cart" / 1
    assert_equal "Your cart is empty", "%d items in your cart" / 0
  end

  def test_zero_form_default
    Locale.set_translation("%d items in your cart",
      [ "One item in your cart", "%d items in your cart" ])
    assert_equal "8 items in your cart", "%d items in your cart" / 8
    assert_equal "One item in your cart", "%d items in your cart" / 1
    assert_equal "0 items in your cart", "%d items in your cart" / 0
  end

  def test_string_substitute_he
    Locale.set("he-IL")
    assert_equal "ברוכים הבאים, יהושע", "welcome, %s" / "יהושע"
  end

  def test_no_substitute
    assert_equal "Don't substitute any %s in %s",
      "Don't substitute any %s in %s".t
  end

  def test_cache
    Locale.set("he-IL")
    tr = Locale.translator
    tr.cache_reset
    assert_equal 0, tr.cache_size
    assert_equal 0, tr.cache_count
    assert_equal 0, tr.cache_total_hits
    assert_equal 0, tr.cache_total_queries

    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t
    assert_equal 1, tr.cache_count
    assert_equal 42, tr.cache_size
    assert_equal 0, tr.cache_total_hits
    assert_equal 1, tr.cache_total_queries

    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t
    assert_equal 1, tr.cache_count
    assert_equal 42, tr.cache_size
    assert_equal 1, tr.cache_total_hits
    assert_equal 2, tr.cache_total_queries

    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t
    assert_equal 1, tr.cache_count
    assert_equal 42, tr.cache_size
    assert_equal 2, tr.cache_total_hits
    assert_equal 3, tr.cache_total_queries
    assert_equal 67, (tr.cache_hit_ratio * 100).ceil

    assert_equal "ועכשיו בעברית",
      tr.instance_eval {
        cache_fetch("And now in Hebrew", Locale.language,
        Locale.language.plural_index(nil))
      }

    # test for purging
    tr.max_cache_size = 41 / 1024  # in kb
    assert_equal "יש לי 5 קבצים", "I have %d files" / 5
    assert_equal 1, tr.cache_count
    assert_equal 38, tr.cache_size
    assert_equal 3, tr.cache_total_hits
    assert_equal 5, tr.cache_total_queries

    assert_equal "יש לי 5 קבצים", "I have %d files" / 5
    assert_equal 1, tr.cache_count
    assert_equal 38, tr.cache_size
    assert_equal 4, tr.cache_total_hits
    assert_equal 6, tr.cache_total_queries

    tr.max_cache_size = 100000 / 1024 # in bytes

    # test for two items in cache
    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t
    assert_equal 2, tr.cache_count
    assert_equal 80, tr.cache_size
    assert_equal 4, tr.cache_total_hits
    assert_equal 7, tr.cache_total_queries

    tr.max_cache_size = 8192  # set it back to default
    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t
    assert_equal 2, tr.cache_count
    assert_equal 80, tr.cache_size
    assert_equal 5, tr.cache_total_hits
    assert_equal 8, tr.cache_total_queries

    # test for invalidation on set_translation
    Locale.set_translation(:And_now_in_Hebrew, "override")
    assert_equal 1, tr.cache_count
    assert_equal 21, tr.cache_size
    assert_equal 5, tr.cache_total_hits
    assert_equal 8, tr.cache_total_queries

    assert_equal "override", :And_now_in_Hebrew.t
    assert_equal 2, tr.cache_count
    assert_equal 46, tr.cache_size
    assert_equal 5, tr.cache_total_hits
    assert_equal 9, tr.cache_total_queries

    # set it back to what it was for other tests
    Locale.set_translation(:And_now_in_Hebrew, "ועכשיו בעברית")
    assert_equal "ועכשיו בעברית", :And_now_in_Hebrew.t

    # phew!
  end
  
  def test_cache_with_zplural_idx
    Locale.set("it")
    tr = Locale.translator
    tr.cache_reset
    
    assert_equal 'un cane', '%d dogs' / 1
    assert_equal 1, tr.cache_count
    assert_equal 14, tr.cache_size
    assert_equal 0, tr.cache_total_hits
    assert_equal 1, tr.cache_total_queries

    assert_equal '100 cani', '%d dogs' / 100
    assert_equal 2, tr.cache_count
    assert_equal 28, tr.cache_size
    assert_equal 0, tr.cache_total_hits
    assert_equal 2, tr.cache_total_queries

    assert_equal '1000 cani', '%d dogs' / 1000
    assert_equal 2, tr.cache_count
    assert_equal 28, tr.cache_size
    assert_equal 1, tr.cache_total_hits
    assert_equal 3, tr.cache_total_queries
  end
  
  def test_cache_and_default
    Locale.set("en")
    
    tr = Locale.translator
    tr.cache_reset

    assert_equal 'abcde', 'abcde'.t
    assert_equal 1, tr.cache_count
    assert_equal 10, tr.cache_size
    assert_equal 0, tr.cache_total_hits
    assert_equal 1, tr.cache_total_queries
    
    # now even default is in cache
    assert_equal 'abcde', 'abcde'.t
    assert_equal 1, tr.cache_count
    assert_equal 10, tr.cache_size
    assert_equal 1, tr.cache_total_hits
    assert_equal 2, tr.cache_total_queries

    # what does it happen with zplural_idx?
    assert_equal 'abcde', 'abcde' / 0
    assert_equal 'abcde', 'abcde' / 0
    assert_equal 'abcde', 'abcde' / 1
    assert_equal 'abcde', 'abcde' / 1
    assert_equal 'abcde', 'abcde' / 8
    assert_equal 'abcde', 'abcde' / 9
    assert_equal 'abcde', 'abcde' / 10
    
    assert_equal 3, tr.cache_count
    assert_equal 30, tr.cache_size
    assert_equal 6, tr.cache_total_hits
    assert_equal 9, tr.cache_total_queries
    
    # what does it happen changing Locale?
    Locale.set("he")
    
    assert_equal 'abcde', 'abcde'.t
    assert_equal 'abcde', 'abcde'.t
    assert_equal 'abcde', 'abcde' / 0
    assert_equal 'abcde', 'abcde' / 0
    assert_equal 'abcde', 'abcde' / 1
    assert_equal 'abcde', 'abcde' / 1
    assert_equal 'abcde', 'abcde' / 8
    assert_equal 'abcde', 'abcde' / 9
    assert_equal 'abcde', 'abcde' / 10

    assert_equal 6, tr.cache_count
    assert_equal 60, tr.cache_size
    assert_equal 12, tr.cache_total_hits
    assert_equal 18, tr.cache_total_queries
    
    # back to English
    Locale.set('en')
    # a string with %d
    assert_equal '%d abcde', '%d abcde'.t
    assert_equal '%d abcde', '%d abcde'.t
    assert_equal '0 abcde', '%d abcde' / 0
    assert_equal '0 abcde', '%d abcde' / 0
    assert_equal '1 abcde', '%d abcde' / 1
    assert_equal '1 abcde', '%d abcde' / 1
    assert_equal '8 abcde', '%d abcde' / 8
    assert_equal '9 abcde', '%d abcde' / 9
    assert_equal '10 abcde', '%d abcde' / 10
    
    assert_equal 9, tr.cache_count
    assert_equal 108, tr.cache_size
    assert_equal 18, tr.cache_total_hits
    assert_equal 27, tr.cache_total_queries    
  end
  
  def test_cache_and_arguments_substitution
    Locale.set("en")
    assert_equal '10 a', '%d a' / 10
    assert_equal '11 a', '%d a' / 11
    assert_equal 'the a', '%s a' / 'the'
    assert_equal 'an a', '%s a' / 'an'
    assert_equal 'a and b', '%{arg1} and %{arg2}' / {'arg1' => 'a', 'arg2' => 'b'}
    assert_equal 'c and d', '%{arg1} and %{arg2}' / {'arg1' => 'c', 'arg2' => 'd'}
  end

  def test_array_arg
    Locale.set('en')
    assert_equal 'Nicola has 3 dogs', '%s has %d dogs' / ['Nicola', 3]

    # but  
    assert_equal 'Nicola has 1 dogs', '%s has %d dogs' / ['Nicola', 1]
    # and that's not what someone usually wants
    # so (to check also comment in code)
    assert_equal 'a dog', '%d dogs' / 1
    assert_equal 'Nicola has a dog', "%s has %s" / ['Nicola', '%d dogs' / 1]
    
    Locale.set('it')
    assert_equal 'Nicola ha 3 cani', '%s has %d dogs' / ['Nicola', 3]
  end

  def test_translate_with_named_param # hash arg
    Locale.set('en')
    assert_equal '3 colored toucans', '%{number} %{adjective} %{name}' / {'number' => 3, 'adjective' => 'colored', 'name' => 'toucans'}
    Locale.set('it')
    assert_equal '3 tucani colorati', '%{number} %{adjective} %{name}' / {'number' => 3, 'adjective' => 'colorati', 'name' => 'tucani'}
  end
  
  def test_on_full_cache_callback
    Locale.set('en')
    tr = Locale.translator
    tr.cache_reset
    
    m = Class.new do
      def on_full_cache(_tr)
        @message = "#{_tr.cache_total_queries} queries"
      end
      attr_reader :message
    end 
    tr.cache_monitor = cache_monitor = m.new
    
    tr.max_cache_size = 10 / 1024  # in kb
    '123'.t
    assert_nil cache_monitor.message
    '456'.t
    assert_equal "2 queries", cache_monitor.message
    
    # cleaning
    tr.cache_monitor = nil
  end

end
