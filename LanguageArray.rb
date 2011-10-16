require "Language.rb"

class LanguageArrayError < RuntimeError
end

class LanguageArray < Hash
  def initialize(dn)
    Dir.entries(dn).each do |fn|
      next if fn.scan(/^\./)[0]
      fname = dn + "/" + fn
      fd = File.open(fname)
      fd.each do |nicknames|
        nicknames.split(' ').each do |nick|
          store(nick,fname)
        end
        break
      end
      fd.close
    end
    @language = nil
  end

  alias :lookup :[]

  def [](o)
    unless (p = o.scan(/#(.*)/)[0]).nil?
      fn = lookup(p[0])
      Language.new(fn)
    end
  end
end
