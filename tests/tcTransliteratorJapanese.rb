# -*- coding: utf-8 -*-
$: << '..'

require "test/unit"
require "Transliterator.rb"

class TcTransliteratorJapanese < Test::Unit::TestCase

  def setup
    fn = "../languages/japanese"
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

    assert_equal("hkaku", t.english("かく"))
    assert_equal("kkaku", t.english("カク"))
    assert_equal("hkaku1", t.english("かく1"))
    assert_equal("hkaku1", t.english("かく１"))
    assert_equal("hkaku_kiku1", t.english("かく＿きく１"))
    assert_equal("HKAku", t.english("御かく"))
    assert_equal("hkakku", t.english("かっく"))
    assert_equal("kkaaku", t.english("カーク"))
    assert_equal("{", t.symbol("｛"))

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

    assert_equal("かく", t.native("hkaku"))
    assert_equal("カク", t.native("kkaku"))
    assert_equal("かく1", t.native("hkaku1"))
    assert_equal("かく_きく1",t.native("hkaku_kiku1"))
    assert_equal("かっく", t.native("hkakku"))
    assert_equal("御かく", t.native("HKAku"))
    assert_equal("かあく",t.native("hkaaku"))
    assert_equal("カーク", t.native("kkaaku"))
    

  end

end
