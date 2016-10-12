require 'rubygems'
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'ruby-prof'
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(File.open('callgrind.out.012_app', 'w+'))

