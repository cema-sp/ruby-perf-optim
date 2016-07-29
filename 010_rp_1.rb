require 'date'
require 'ruby-prof'

GC.disable # for CPU profiling

RubyProf.start
Date.parse('2014-07-01')
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)

File.open('010_rp_1.prof', 'w+') do |file|
  printer.print(file)
end

