# -*- coding: utf-8 -*-
$: << '..'

require "test/unit"
require "Transliterator.rb"

class TcTransliteratorRussian < Test::Unit::TestCase

  def setup
    fn = "../languages/russian"
    @fd = File.open(fn)
  end
  
  def teardown
    @fd.close
  end

  def test1
    # can we run the initializer?
    assert_nothing_raised(TransliteratorError) {
      t = Transliterator.new
    }
  end

  def test2
    # can we load the file?
    t = Transliterator.new
    assert_nothing_raised(TransliteratorError) {
      @fd.each do |line|
        next if @fd.lineno == 1 

        key = line.scan(/^-(.*)/)[0]

        if (not key.nil?) && key[0][0..0] == "t"
          t.processLine(key[0])
        end
      end
    }
    # can we finish the initialization?
    assert_nothing_raised(TransliteratorError) {
      t.setup
    }
  end

  def test3
    # can we transliterate into english from japanese?
    t = Transliterator.new
    @fd.each do |line|
      next if @fd.lineno == 1 
      
      key = line.scan(/^-(.*)/)[0]
      
      if (not key.nil?) && key[0][0..0] == "t"
        t.processLine(key[0])
      end
    end
    t.setup

    assert_equal("rx", t.english("х"))
    assert_equal("rxru", t.english("хру"))
    assert_equal("rxryu", t.english("хрю"))
    assert_equal("rzhyiznyy", t.english("жизнь"))
    assert_equal("rxryu1", t.english("хрю1"))
    assert_equal("rxryu_1", t.english("хрю_1"))
    assert_equal("RXryu_1", t.english("Хрю_1"))

  end

  def test4
    # can we transliterate into japanese from english?
    t = Transliterator.new
    @fd.each do |line|
      next if @fd.lineno == 1 
      
      key = line.scan(/^-(.*)/)[0]
      
      if (not key.nil?) && key[0][0..0] == "t"
        t.processLine(key[0])
      end
    end
    t.setup

    assert_equal("х", t.native("rx"))
    assert_equal("хру", t.native("rxru"))
    assert_equal("хрю", t.native("rxryu"))
    assert_equal("жизнь", t.native("rzhyiznyy"))
    assert_equal("хрю1", t.native("rxryu1"))
    assert_equal("хрю_1", t.native("rxryu_1"))
    assert_equal("Хрю_1", t.native("RXryu_1"))
    assert_equal("Чай", t.native("RCHai"))

  end

end
