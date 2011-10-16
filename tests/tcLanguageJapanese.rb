# -*- coding: utf-8 -*-
$: << '..'

require "test/unit"
require "Language.rb"

class TcTransliteratorJapanese < Test::Unit::TestCase

  def setup
    @fn = "../languages/japanese"
  end
  
  def test1
    # can we run the initializer?
    assert_nothing_raised(TransliteratorError) {
      l = Language.new(@fn)
      l.setup
    }
  end

  def test3
    # can we transliterate into english from japanese?
    l = Language.new(@fn)
    l.setup
  end

  def test4
    # can we transliterate into japanese from english?
    l = Language.new(@fn)
    l.setup
  end

end
