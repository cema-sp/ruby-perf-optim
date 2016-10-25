# require 'pretty_print'
require 'pp'

def stats
  GC.stat.select { |k, v| %i(count heap_allocated_pages).include?(k) }
end

# ------ main ------

GC.start

puts "\tBefore allocation"
pp stats

x = Array.new(15_000) { Object.new }

puts "\tAfter 15.000 small objects allocation"
pp stats

x = nil

puts "\tAfter 15.000 small objects finalized"
pp stats

y = Array.new(15_000) { Object.new }

puts "\tAfter 15.000 more small objects allocation"
pp stats

