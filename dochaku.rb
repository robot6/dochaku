
VV=0.1
Name="iruby"
Help = <<DOC
iruby recodes ruby file from one language to English ruby
Usage: iruby infile
   infile - contains code to be converted
DOC

Banner = <<DOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% iruby                 VERSION #{VV} %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DOC

$LOAD_PATH << './lib'

require "Translator"

class IrubyError < RuntimeError
end


begin
  if ARGV.empty? then
    puts Help
    puts Name+" version "+VV.to_s
  else
    if ARGV.size != 1 then
      puts Help
      puts Name+" version "+VV.to_s
    elsif ARGV[0] == "-h"
      puts Help
    elsif ARGV[0] == "-v"
      puts Name + " version " + VV.to_s
    elsif ARGV[0] == "-b"
      puts Banner
    else
      inputFilename = ARGV[0]
      if not File.exists?(inputFilename) then
        raise IrubyError,"Input file "+inputFilename+" does not exist."
      else
        t = Translator.new("languages")
        t.translateFileOut(inputFilename)
      end
    end
  end
end
