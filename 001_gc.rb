#!/usr/bin/ruby

require 'benchmark'

no_gc = ARGV[0] == '-o'

num_rows = 100_000
num_cols = 10

data = Array.new(num_rows) do
  Array.new(num_cols) { 'x' * 1000 }
end

mem_before = "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

GC.disable if no_gc
time = Benchmark.realtime do
  csv = data.map do |row|
    row.join(',')
  end.join("\n")
end

mem_after = "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

puts "Time: #{time} (GC #{no_gc ? 'disabled' : 'enabled'})"
puts "MEM: #{mem_before} -> #{mem_after}"

