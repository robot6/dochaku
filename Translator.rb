require "LanguageArray.rb"

class TranslatorError < RuntimeError
end

class Translator

  attr_reader :language

  def initialize(dn)
    # simply read the language directory so that we have a collection
    # of all the nicknames
    @languageArray = LanguageArray.new(dn)
    @language = NoLanguage.new
  end


  def translateFileOut1(fn)
    # Open the file and read the first line,
    # which should be in the form of "#xx" or "#yyyyyy"
    # If it is in the form of "#xx" then it is a two-digit code for
    #   the language.
    # If it is in the form of "#yyyyyy" then it is a long string
    #   for the language.

    fd = File.open(fn)

    fd.each do |line|
      if fd.lineno == 1 and not line.scan(/^#!/)[0].nil?
        puts line
      elsif (fd.lineno == 1 or fd.lineno == 2) and
          not line.scan(/coding: /)[0].nil?
        puts line
      elsif (fd.lineno == 1 or fd.lineno == 2 or fd.lineno == 3) and
          @language = @languageArray[line]
      else
        puts translate(line)
      end
    end
  end

  def translateFileOut(fn)
    # Open the file and read the first line,
    # which should be in the form of "#xx" or "#yyyyyy"
    # If it is in the form of "#xx" then it is a two-digit code for
    #   the language.
    # If it is in the form of "#yyyyyy" then it is a long string
    #   for the language.

    fd = File.open(fn,"r")

    lineno = 0
    charno = 0
    preamble = true
    commenting = false
    line_complete = false
    token_complete = false
    lastchar = nil
    comment = ""
    building_inline_documentation_start = false
    building_inline_documentation_stop = false
    multiline_comment = false
    start_delim_next_char = false
    token = ""
    parse_until = false

    fd.chars.each do |char|
      charno += 1

      # First, handle the preamble section.  This also handles commenting.
      if preamble and charno == 1 and char == "#"
        commenting = true
        comment = String.new
      elsif preamble and charno == 1 and char != "#"
        commenting = false
        preamble = false
        @language.setup unless @language.class == NoLanguage
      end

      if char == "\n"
        line_complete = true
        lineno += 1
        charno = 0
      else
        line_complete = false
      end

      if not preamble and @language.class == NoLanguage
        # if we've made it past the preamble and there is no language defined, then
        # we simply dump the file
        print char
      else

        if commenting or multiline_comment
          comment << char
        end

        #puts "char: " + char + " pos: " + charno.to_s + " line: " + lineno.to_s +
        #  " preamble: " + preamble.to_s + " commenting: " + commenting.to_s +
        #  " line_complete: " + line_complete.to_s
        if preamble
          if line_complete
            if lineno == 1 and not comment.scan(/^#!/)[0].nil?
              print comment
              commenting = line_complete = false
              comment = ""
            elsif (lineno == 1 or lineno == 2) and
                not comment.scan(/coding: /)[0].nil?
              print comment
              commenting = line_complete = false
              comment = ""
            elsif (lineno == 1 or lineno == 2 or lineno == 3) and 
                @language.class == NoLanguage and @language = @languageArray[comment]
              print comment
              commenting = line_complete = false
              comment = ""
            elsif (lineno == 2 or lineno == 3 or lineno == 4) and 
                @language.class != NoLanguage and
                not (p = comment.scan(/aliases:(.*)/)[0]).nil?
              print comment
              commenting = line_complete = false
              @language.add_aliases(p[0].strip!)
              preamble = false
              @language.setup
              comment = ""
            else
              print comment
              @language.setup unless @language.class == NoLanguage
              preamble = false
              comment = ""
            end
          end

        else
           # puts "got a new character: "+char

          # For now, just build and output tokens
#          if @language.is_pound?(char) and not commenting and not multiline_comment
#            puts "here1"
#            comment << char
#            commenting = true
#          end

          if start_delim_next_char
            parse_until = ( @language.is_symbol?(char) ? 
                            ( (k = @language.transliterator.symbol(char)).nil? ? char : k) : 
                            char )
            # p parse_until
            case parse_until
            when "{" 
              parse_until = "}"
            when "("
              parse_until = ")"
            when "[" 
              parse_until = "]"
            end
            start_delim_next_char = false
            print char
            next
          end

          if parse_until != false
            # puts char + ":" + @language.is_symbol?(char).to_s + " : " + 
            #  @language.transliterator.symbol(char).to_s + " : " + ( @language.is_symbol?(char) ? 
            #      (( k = @language.transliterator.symbol(char)).nil? ? char : k )  : char )
            compare_char = ( @language.is_symbol?(char) ? 
                  (( k = @language.transliterator.symbol(char)).nil? ? char : k )  : char )
            if compare_char == parse_until
              print compare_char 
              parse_until = false
            else
              print char
            end
            next
          end
            
          #puts "char here:"+char

          if ( @language.is_idchar?(char) or @language.is_english?(char) ) and not commenting and 
              not multiline_comment and not parse_until
            # puts "here2"+char
            token << char
            if lastchar == "%"
              if char == "q" then
                token.clear
                token_complete =  false
                print "q"
                start_delim_next_char = true
                interpolable = false
                next
              elsif char == "Q" then
                token.clear ; token_complete = false
                print "Q"
                start_delim_next_char = true
                interpolable = true
                next
              elsif char == "x" then
                token.clear ; token_complete = false
                print "x"
                start_delim_next_char = true
                interpolable = true
                next
              elsif char == "r" then
                token.clear ; token_complete = false
                print "r"
                start_delim_next_char = true
                interpolable = true
                next
              end
            end
          end

          if @language.is_equal?(char) and charno == 1 and 
              not commenting and not parse_until
            # puts "here3"
            token = char
            building_inline_documentation_start = true
          end

          if @language.is_equal?(char) and charno == 1 and multiline_comment
            puts "here4"
            token = char
            building_inline_documentation_stop = true
          end

          if @language.is_symbol?(char)
            # puts "it is a symbol:"+char
            if @language.transliterator.symbol(char) == "#" or char == "#" and lastchar != "?"
              # puts "here1"
              comment << char
              commenting = true
            else
              token_complete = true
              if @language.transliterator.symbol(char) == "'" or char == "'" then 
                # puts "here15"
                parse_until = "'"
                interpolable = false
              elsif @language.transliterator.symbol(char) == '"' or char == '"' then 
                # puts "here16"
                parse_until = '"'
                interpolable = true
              elsif @language.transliterator.symbol(char) == "`" or char == "`" then 
                # puts "here17"
                parse_until = "`"
                interpolable = true
              elsif @language.transliterator.symbol(char) == "/" or char == "/" then 
                parse_until = "/"
                interpolable = true
              elsif ( @language.transliterator.symbol(char) == "!" or char == "!" ) and 
                  lastchar == "%" then
                parse_until = "!"
                interpolable = true
              end
            end
          end

          if @language.is_space?(char) and
              ( not commenting and not multiline_comment and (parse_until == false) )
            # puts "here6"
            token_complete = true
          end

          if token_complete
            if @language.is_space?(token) or token.empty?
              # p "here3"
              print token
              print @language.space(char) if @language.is_space?(char)
              if @language.is_symbol?(char)
                print ((k = @language.transliterator.symbol(char)).nil? ? char : k )
              end
            elsif building_inline_documentation_start and @language.is_space?(char)
              print "=",(k=@language.translate(token[1..-1])),char
              building_inline_documentation_start = false
              multiline_comment = true if "begin" == k
            elsif building_inline_documentation_stop and @language.is_space?(char)
              print "=",(k=@language.translate(token[1..-1])),char
              building_inline_documentation_stop = false
              multiline_comment = false if "end" == k
            else
              print @language.process_token(token) unless token.nil?
              print @language.space(char) if @language.is_space?(char)
              if @language.is_symbol?(char) 
                print  ((k = @language.transliterator.symbol(char)).nil? ? char : k )
              end
            end
            token = ""
            token_complete = false
          end

          if  ( commenting or multiline_comment ) and line_complete
            # p "here9"
            print comment
            commenting = line_complete = false
            comment = ""
          end

        end
      end
      lastchar = char
    end
  end

  attr_reader :encoding, :languageArray

  def process_token(token)
    @language.process_token(token)
  end

  def translate(line)
    if @language.class == NoLanguage
      outstring = String.new
      tokenizing = false
      token = ""
      in_quotes = false
      is_number = false

      line.chars do |single|
        if in_quotes
          outstring << single
          in_quotes = false if single == @start_quote
        else
          if @language.is_space?(single)
            if tokenizing == true
              outstring << process_token(token)
              token = ""
              tokenizing = false
            end
            outstring << single
          elsif @language.is_quote?(single)
            if tokenizing == true
              process_token(token)
              token = ""
              tokenizing = false
            end
            outstring << single
            @start_quote = single
            in_quotes = true
          else
            if tokenizing
              token << single
            else
              if not tokenizing and @language.is_number?(single)
                is_number = true
              else
                is_number = false
              end
              tokenizing = true
              token << single
            end
          end
        end
      end

      return outstring

    else #THIS FILE HAS NOT DEFINED A LANGUAGE SO THE LINE IS NOT TRANSLATED.
      "language " + @languageArray.language + " not implemented."
      #tokenizer, etc.
    end
  end

end
