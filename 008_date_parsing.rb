require 'date'
require 'benchmark'

date = '2014-05-23'
time = Benchmark.realtime do
  100_000.times do
    Date.parse(date)
  end
end

puts 'Date#parse: %.3f' % time

GC.start
time = Benchmark.realtime do
  100_000.times do
    Date.strptime(date, '%Y-%m-%d')
  end
end

puts 'Date.strptime: %.3f' % time

GC.start
time = Benchmark.realtime do
  100_000.times do
    Date.civil(date[0, 4].to_i, date[5, 2].to_i, date[8, 2].to_i)
  end
end

puts 'Manual parsing: %.3f' % time

