require 'pp'

def stats
  GC.stat.select { |k, v| %i(count heap_allocated_pages heap_eden_pages).include?(k) }
end

# ------ main ------

GC.start

puts "\tBefore allocation"
pp stats

x = Array.new(18_000) { Object.new }

puts "\tAfter 18.000 small objects allocation"
pp stats

x = nil

puts "\tAfter 18.000 small objects finalized"
pp stats

y = Array.new(18_000) { Object.new }

puts "\tAfter 18.000 more small objects allocation"
pp stats

z = Array.new(18_000) { Object.new }

puts "\tAnd 18.000 more small objects allocation"
pp stats

