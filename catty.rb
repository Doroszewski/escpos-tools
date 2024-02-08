#!/usr/bin/ruby

#require 'open3'
require 'optparse'
require 'yaml'

options = {
  :cut       => false,
  :device    => '/dev/ttyS0',
  :encoding  => 'CP852',
  :init      => false,
  :replace   => '█',
  :quotation => 0,
  :size      => 0
}

begin
  config_home = ENV['XDG_CONFIG_HOME'] || "#{ENV['HOME']}/.config"
  config_path = "#{config_home}/escpos-tools.yaml"
  config_hash = YAML.load_file(config_path)
rescue
  config_hash = {}
end

options[:device]   = config_hash['device'].to_s   if config_hash['device']
options[:encoding] = config_hash['encoding'].to_s if config_hash['encoding']
options[:init]     = config_hash['init']          if config_hash['init']

parser = OptionParser.new
parser.banner
parser.version = '0.3, 2024'
parser.on('-c', '--cut', 'Cut the paper at the end') do 
  options[:cut] = _1
end
parser.on('-d', '--device=DEVICE', 'Use DEVICE instead of /dev/ttyS0') do
  options[:device] = _1
end
parser.on('-e', '--encoding=ENCODING', 'Use ENCODING') do
  options[:encoding] = _1
end
parser.on('-i', '--init', 'Start with executing the init script') do
  options[:init] = true
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
    warn '-s (--size) must be 1, 2, 3 or 4!'
    exit 1
  end
end
parser.parse!

if options[:init]
  system('stty', '-F', options[:device], '19200') or exit($?)
  f = File.open(options[:device], 'w')
  f.write "\x1B@" # Reset
  if options[:encoding] == 'CP852'
    f.write "\x1B\x74\x12"
  else
    abort 'Encodings other than CP-852 have not been implemented yet!'
  end
else
  f = File.open(options[:device], 'w')
end

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

if options[:cut]
  f.write "\n\n\n\n\n\em"
end

# OPIS
#   Prosty skrypt, który przerzuca całe wejście do /dev/ttyS0 po konwersji
#   kodowania.
# HISTORIA ZMIAN
#   2024-02-08 – +obsługa pliku konfiguracyjnego, +wewnętrzna inicjalizacja
#   2023-04-28 – trzecia wersja, dodanie parametru --size
#   2022-11-12 – druga wersja, użycie wewnętrznej procedury Ruby'e zamiast
#                `iconv`
#   2022-09-30 – pierwsza wersja
