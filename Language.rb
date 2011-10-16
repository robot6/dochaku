require "Transliterator.rb"

# language file structure:
# - first line is a list of synonyms for the language which can appera in 
#        the first line of a language file
# - lines starting with "-" indicate a kind of rule section
# --t is to be sent to the Transcriber
# --sov/svo/osv/ovs/vso/vos are natural orderings 
# --postposition/preposition are natural orderings
# --operators blocks off a region for operator aliases
# --keywords blocks off a region for keyword aliases
# - all other lines are aliases

class LanguageError < RuntimeError
end

# for the period before the language is defined, we don't have a language.
# this class fills in, helping out so that we can get to defining a language.
class NoLanguage
  def is_pound?(c) c == "#" end
  def is_space?(c) not c.scan(/[ \t\b\v\f\n\r]/)[0].nil? end
  def is_idchar?(c) not c.scan(/[A-Za-z0-9_]/).nil? end
  def is_number?(c) not c.scan(/[0-9\.]/).nil? end
  def is_symbol?(c) not is_idchar?(c) and not is_space?(c) end
end



class Language
  attr_accessor :name, :filename, :sov, :aliases, :unaliases, :links, :transliterator

  def is_space?(c) @transliterator.is_space?(c) end
  def is_quote?(c) @transliterator.is_quote?(c) end
  def is_number?(c) @transliterator.is_number?(c) end
  def is_pound?(c) @transliterator.is_pound?(c) end
  def is_symbol?(c) not is_idchar?(c) and not is_space?(c) and
    not is_idchar2?(c) and not is_english?(c) and not is_number?(c) end
  def is_idchar2?(c) not @characters.index(c).nil? end
  def is_idchar?(c) @transliterator.is_idchar?(c) or is_idchar2?(c) end
  def is_percent?(c) @transliterator.is_percent?(c) end
  def is_slash?(c) @transliterator.is_slash?(c) end
  def is_equal?(c) @transliterator.is_equal?(c) end
  def is_english?(c) @transliterator.is_english?(c) end
  def space(c) @transliterator.space(c) end

  def character(c)
    @transliterator.is_char?(c)
  end

  def process_token(token)
    # let's see if this token is in the aliases.
    if x = @unaliases[token]
      # puts "language has processed " + token + " as: " + x
      # p @unaliases
      return x
    else
      t = @transliterator.english(token)
      # puts "language is sending " + token + " to the transliterator: " + t
      # if it's not then transliterate it.
      return t
    end
  end

  def process_alias(line, filename, lineno)
    als = line.split(@transliterator.spaces_re)
    if not als[0].nil?
      if als[0][0..0] != "#" # ignore any line starting with a #
        number_of_als = als.size
        if number_of_als < 2
          raise LanguageError, " on line #{lineno} in file #{filename}"
        end
        while number_of_als >= 2
          number_of_als -= 1
          @aliases.store(als[0],als[number_of_als])
        end
      end
    end         
  end

  def add_aliases(fn)
    fd = File.open(fn)
    fd.each { |line| process_alias(line,fn,fd.lineno)}
    p @aliases
  end

  def setup
    # called after add_aliases
    # this extracts all the characters used in the tables
    @characters = []
    @aliases.each do |k,v|
      v.each_char { |c| @characters << c }
    end
    @characters.sort!
    @characters.uniq!
    @unaliases = @aliases.invert
  end
    

  def initialize(fn)
    @filename = fn
    @name = File.basename(fn)
    @aliases = Hash.new
    @transliterator = Transliterator.new
    fd = File.open(fn)
    fd.each do |line|
      next if fd.lineno == 1 

      if line[0] == "-"

        key = line.scan(/^-(.*)/)[0]

        case key[0]

        when "sov", "svo", "osv", "ovs", "vso", "vos"
          @sov = key

        when "postposition", "preposition"
          @links = key

        when "operators"
          
        when "keywords"

        when "names"

        when "messages"
          
        else

          case key[0][0..0]

          when "t"            # check to see if it is a transliteration line
            @transliterator.processLine(key[0])

          else
            raise LanguageError, " on line #{fd.lineno} in language #{@filename}"
          end

        end

      elsif line[0] == "#"
      else

        # store the aliases in the hash
        process_alias(line,@filename, fd.lineno)

      end
    end
    fd.close
    @transliterator.setup
  end

end
