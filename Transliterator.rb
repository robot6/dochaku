# -*- coding: utf-8 -*-

class TransliteratorError < RuntimeError
end

class Transliterator
  attr_reader :sets, :unsets, :rule, :charactersN, :charactersE
  attr_reader :capitals, :capital_re, :bigset, :spaces_re
  attr_reader :symbols, :numbers, :numberset

  OtherNumbers = {"0"=>"0", "1"=>"1", "2"=>"2", "3"=>"3",
    "4"=>"4", "5"=>"5", "6"=>"6", "7"=>"7",
    "8"=>"8", "9"=>"9"}
  OtherIdChars = {"_"=>"_"}
  OtherNumberChars = {"."=>"."}
  Vowels = ["a", "i", "u", "e", "o"]
  Uppercase = ("A".."Z")
  Lowercase = ("a".."z")
  Numbers = ("0".."9")

  def initialize
    @sets = []
    @unsets = []
    @characters = []
    @capitals = []
    @spaces_list = []
  end

  def setup
    @bigset = Hash.new
    @capital_re = Regexp.new("^[#{@capitals}].") unless @capitals.empty?
    @sets.collect { |set| @bigset.merge!(set[1]) }
    @numbers ||= Hash.new
    @numbers.merge!(Transliterator::OtherNumbers)
    @numberset = @numbers.dup
    @numberset.merge!(Transliterator::OtherNumberChars)
    @bigset.merge!(@numbers)
    @bigset.merge!(Transliterator::OtherIdChars)
    if @symbols != nil then 
      @symbols.each do |k,v|
        if v == "_" then @bigset.store(k,v) end
        if v == "." then @numberset.store(k,v) end
      end
    end
    # collect all the characters into an array so we can search them quickly
    # sets.each { |set| @charactersN << set[1].keys }
    # sets.each { |set| @charactersE << set[1].values }
    p @bigset
    p @symbols
    p @numbers
    p @numberset
  end

  def is_number?(c)
    not @numbers[c].nil?
  end

  def is_continuing_number(c)
    not @numberset[c].nil?
  end

  def is_single_quote?(c)
    c == "'" or @symbols[c] == "'"
  end

  def is_double_quote?(c)
    c == '"' or @symbols[c] == '"'
  end

  def is_open_brace?(c)
    c == "{" or @symbols[c] == "{"
  end

  def is_close_brace?(c)
    c == "}" or @symbols[c] == "}"
  end

  def is_space?(c)
    not c.scan(@spaces_re)[0].nil?
  end

  def is_native?(c)
    initializeCharacters if @chararcters.empty?
    @charactersN.include?(c) or @capitals.include?(c)
  end

  def is_english?(c)
    Lowercase.cover?(c) or Uppercase.cover?(c)
  end

  def is_slash?(c)
    c == "/" or (@symbols.nil? ? false : @symbols[c] == "/")
  end

  def is_pound?(c)
    c == "#" or (@symbols.nil? ? false : @symbols[c] == "#")
  end

  def is_percent?(c)
    c == "%" or (@symbols.nil? ? false : @symbols[c] == "%")
  end

  def is_idchar?(c)
    not @bigset[c].nil?
  end

  def is_equal?(c)
    c == "=" or (@symbols.nil? ? false : @symbols[c] == "=")
  end

  def space(c)
    return " " unless @spaces_list.index(c).nil?
    return c
  end

  def symbol(c)
    @symbols.nil? ? c : @symbols[c]
  end
  
  def english(c)
    setup if @bigset.nil?

    # so far this conversion is 1 -> n characters so it's pretty easy

    # first check the capitalization rule
    if @rule == 1
      # the first native character is the first character of the string
      n = c
    elsif @rule == 2
      # in this case, the first native character is the second character
      # if the first character is one of the capitals
      if (c2 = c.scan(@capital_re)[0]).nil?
        n = c
        cap = false
      else
        n = c[1,c.size-1]
        cap = true
      end
    else
      raise TransliteratorError, "bad capitalization rule #{@rule}"
    end

    # next find the set that this expression is in
    type = ""
    working_set = nil
    sets.each do |set|
      if not set[1][n[0]].nil?
        type = set[0].dup
        working_set = set
        break
      end
    end

    raise TransliteratorError, "cannot transliterate #{c}, it is not in a set." if working_set.nil?

    # now do the transliteration
    case @rule
    when 1
      c.each_char do |cs| 
        char = @bigset[cs]
        if type.size == 1 and Uppercase.include?(char[0]) 
          type.upcase! 
        end
        type << char
      end
    when 2
      vdouble = consdouble = false
      lastchar = ""
      n.each_char.with_index do |cs,i|
        if is_space?(cs)
          type << cs
        else
          if (nc = @bigset[cs]).nil?
            # check to see if it's a doubling character
            if working_set[2].nil? and working_set[3].nil?
              raise TransliteratorError," character #{cs} could not be transliterated."
            end
            consdoubler = working_set[2].class == Hash ? working_set[3] : working_set[2]
            vdoubler = working_set[2].class == Hash ? working_set[2] : working_set[3]
            if cs==consdoubler then consdouble = true
            elsif vdoubler[cs] == 2 then vdouble = true
            end
            if consdouble == false and vdouble == false
              raise TransliteratorError," character #{cs} could not be transliterated."
            end
            if vdouble
              if lastchar.empty?
                raise TransliteratorError," vowel doubler at beginning."
              else
                type << lastchar[-1] # double only the vowel, which is the last character
                vdouble = false
              end
            end
          else
            if consdouble
              type << nc[0]
              consdouble = false
            end
            type << nc
            lastchar = nc
          end
        end
        if i == 0 and cap then type.upcase! end
      end
    else
      raise TransliteratorError, "rule #{@rule} not supported."
    end

    return type
  end

  def native(c)
    type,string = c.scan(/(.)(.*)/)[0]
    if type.nil? then return nil end
    if string.empty? then return nil end
    cap = Uppercase.cover?(type)
    trans = ""

    case @rule
    when 1
      if cap then type.downcase! end
      @unsets.each do |set|
        if set[0] == type
          ws = set[1]
          index = 0
          while index < string.size
            # try to take one character, and make sure it's not an underscore or a number
            char = string[index]
            if char == "_" or Numbers.include?(char) 
              trans << char
              index += 1
            else
              # in this case, we first try to take two characters
              if index + 1 < string.size
                char = string[index..index+1]
                if not (ch = ws[char]).nil?
                  trans << ch
                  index += 2
                else
                  char = string[index]
                  if not (ch = ws[char]).nil?
                    trans << ch
                    index += 1
                  else
                    return nil
                  end
                end
              else
                char = string[index]
                if not (ch = ws[char]).nil?
                  trans << ch
                  index += 1
                else
                  return nil
                end
              end
            end
          end
          return trans
        end
      end
      return nil
      
    when 2
      if cap then 
        trans << @capitals[0]
        string.downcase!
        type.downcase!
      end
      @unsets.each do |set|
        if set[0] == type
          ws = set[1]
          consdoubler = set[2].class == Hash ? set[3] : set[2]
          voweldoubler = set[2].class == Hash ? set[2] : set[3]
          index = 0
          while index < string.size
            char = string[index]
            if (ch = ws[char]).nil?
              # check out what it could be...
              case char
              when "_"
                trans << char
              when "0".."9"
                trans << char
              else # none of the above so take a second character
                index += 1
                nextchar = string[index]
                # check to see if it's a double consonant
                if char == nextchar and not Vowels.include?(char)
                  trans << consdoubler
                  index += 1
                  nextchar = string[index]
                end
                # after handling the double consonant, we look for the double letter
                char << nextchar
                if (ch = ws[char]).nil?
                  return nil
                else
                  trans << ch
                end
              end
            else
              # check to see if this is a double vowel
              if char == string[index-1] and not voweldoubler.nil? and Vowels.include?(char)
                trans << voweldoubler.rassoc(2)[0]
              else
                trans << ch
              end
            end
            index += 1
          end
          return trans
        end
      end
      return nil
    else
      return nil
    end
  end

  def processLine(line)
    #    puts "transliteration:" + line + "; case: " + line[1..1]
    case type = line[1..1]

    when "0"  # rule 0 is 1 if there is one long set of characters with both capitals
      # and lower-case letters.  An example is Cyrillic.
      # rule 0 is 2 if there are multiple sets with vowel extenders and consonant
      # doublers, such as in Japanese.
      @rule = (line.scan /\{([^\}]*)\}/)[0]
      raise TransliteratorError, "rule could not be parsed" if @rule.nil?
      @rule = @rule[0]
      raise TransliteratorError, "unknown rule" unless ("1".."2").cover?(@rule)
      @rule = @rule.to_i

    when "+" # rule + tells us what kind of character will signal a capital
      raise TransliteratorError, "capital declared when rule 1" if @rule == 1
      @capitals << line.scan(/t\+\s*\{([^\}]*)\}/)[0][0]

    when "_" # rule _ tells us the unicode hex digits for spaces...
      space_list_string = line.scan(/t\_\s*\{([^\}]*)\}/)[0][0]
      space_list = space_list_string.split(@spaces_re)
      @spaces_string = " \t\n\b\f\v\r" # always include the Ruby whitespaces
      space_list.each do |sl| 
        @spaces_list << (s = sl.to_i(16).chr(Encoding::UTF_8))
        @spaces_string.concat(s)
      end
      @spaces_re = Regexp.new("[#{@spaces_string}]")
      # @spaces_string.codepoints{|c| print c, ", "}

    when "(" # rule ( indicates what the extra braces will look like...
      braces = line.scan(/t\(\s*\{([^\}]*)\}/)[0][0]
      brace_list = braces.split(@spaces_re)
      @symbols = Hash.new if @symbols.nil?
      @symbols.store(brace_list[0],"{")
      @symbols.store(brace_list[1],"}")

    else  # any phonetic character tells what the strings are,
      # while "1" indicates a number translation and
      # "2" indicates symbol translation
      if not @workfirst.nil?
        if @typestore != type
          raise TransliteratorError, "sequence out of order in language file: "+line
        end
        @worksecond = (line.scan /\{([^\}]*)\}/)[0]
        if @worksecond.nil?
          raise TransliteratorError, "cannot parse sequence in language file"
        end
        # we have two matching sets, now associate them
        h = Hash.new
        set1 = @workfirst.split(@spaces_re)
        set1.delete("")
        set2 = @worksecond[0].split(@spaces_re)
        set2.delete("")
        set1.zip(set2) do |a,b|
          if a.nil? or b.nil?
            raise TransliteratorError, "type #{@typestore} not coherent"
          end
          h.store(a,b)
        end
        if ("a".."z").cover?(@typestore)
          # save this kind of transliteration in @sets
          @sets << [@typestore,h]
          @unsets << [@typestore,h.invert]
          # clear work area
          @workfirst = @worksecond = @typestore = nil
        elsif @typestore == "1"
          @numbers = h
          @workfirst = @worksecond = @typestore = nil
        elsif @typestore == "2"
          if @symbols.nil?
            @symbols = h
          else
            @symbols.merge!(h)
          end
          @workfirst = @worksecond = @typestore = nil
        else
          raise TransliteratorError, "unknown class of characters: "+line
        end
      else
        check = (line.scan /t([^\{]*)\{([^\}]*)\}/)[0]
        raise TransliteratorError, "cannot parse sequence in language file" if check.nil?

        case check[0][1]
        when "c"
          # it is a consonant-doubling character.
          # Find the set and append the doubler.
          @sets.each {|set| if set[0]==type then set << check[1] ; break ; end }
          @unsets.each {|set| if set[0]==type then set << check[1] ; break ; end }
          # clear the work areas, they must be reset for the next round.
          @workfirst = nil
          @typestore = nil
        when "&"
          # it is a vowel-extending character.
          # Find the set and append the vowel extender as a hash with the number 2
          h = Hash.new
          h.store(check[1],2)
          @sets.each {|set| if set[0]==type then set << h ; break ; end }
          @unsets.each {|set| if set[0]==type then set << h ; break ; end}
          # clear the work areas, they must be reset for the next round.
          @workfirst = nil
          @typestore = nil
        else
          @typestore = type
          @workfirst = check[1] # (line.scan /\{([^\}]*)\}/)[0]
        end
      end
    end
    if @spaces_re.nil?
      @spaces_string = " \t\n"
      @spaces_re = Regexp.new("[#{@spaces_string}]")
    end
  end
end
