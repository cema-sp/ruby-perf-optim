require 'rubygems'
require 'bundler/inline'
require 'benchmark'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'ruby-prof'
end

exit(0) unless ARGV[0]

GC.enable_stats
RubyProf.measure_mode = RubyProf.const_get(ARGV[0])

result = RubyProf.profile do
  str = 'x' * 1024 * 1024 * 10 # 10 Mb
  str.upcase # initial version
  # str.upcase! # optimized version
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('015_rp_memory.prof', 'w'), min_percent: 3)

printer = RubyProf::CallTreePrinter.new(result)
printer.print(print_file: true, path: './015_rp_memory')

