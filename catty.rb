#!/usr/bin/ruby

#require 'open3'
require 'optparse'

options = {
  :device    => '/dev/ttyS0',
  :encoding  => 'CP852',
  :init      => false,
  :replace   => '█',
  :quotation => 0,
  :size      => 0
}

parser = OptionParser.new
parser.banner
parser.version = '2.0, 2022'
parser.on('-d', '--device=DEVICE', 'Use DEVICE instead of /dev/ttyS0') do
  options[:device] = _1
end
parser.on('-e', '--encoding=ENCODING', 'Use ENCODING') do
  options[:encoding] = _1
end
parser.on('-i', '--init', 'Start with executing the init script') do
  options[:init] = true
  system("./#{$0.sub('catty.rb', 'init.sh')}") or STDERR.puts('Init failed')
end
parser.on('-q', '--quotation-marks=ID',
          'Choose the style of quotation marks') do
  options[:quotation] = _1.to_i
end
parser.on('-s', '--size=ID', 'Choose the character size') do
  x = _1.to_i
  if (x == 0 || x == 1 || x == 2 || x == 3 || x == 4)
    options[:size] = x
  else
    STDERR.puts '-s (--size) must be 1, 2, 3 or 4!'
    exit 1
  end
end
parser.parse!

f = File.open(options[:device], 'w')

unless (options[:size] == 0)
  f.write("\e!")
  case options[:size]
  when 1
    f.write("\x01")
  when 2
    f.write("\x00")
  when 3
    f.write('1')
  when 4
    f.write('0')
  end
end

ARGF.each do | l |
  if    options[:quotation] == 0
    l.gsub!(/[„”]/, '"')
  elsif options[:quotation] == 1
    l.gsub!('„', '«')
    l.gsub!('”', '»')
  end
  l.gsub!('…', '...')
  l.encode!(options[:encoding],
            invalid: :replace,
            undef:   :replace,
            replace: options[:replace])
  f.write(l)
end

# OPIS
#   Prosty skrypt, który przerzuca całe wejście do /dev/ttyS0 po konwersji
#   kodowania.
# HISTORIA ZMIAN
#   2023-04-28 – trzecia wersja, dodanie parametru --size
#   2022-11-12 – druga wersja, użycie wewnętrznej procedury Ruby'e zamiast
#                `iconv`
#   2022-09-30 – pierwsza wersja
