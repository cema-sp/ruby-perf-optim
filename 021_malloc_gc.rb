require 'pp'

def stats
  GC.stat.select { |k, v| %i(count malloc_increase_bytes_limit malloc_increase_bytes).include?(k) }
end

# ------ main ------

data = 'x' * 1024 * 1024 * 10 # 10 Mb

buffers = []
GC.start

puts "Before any copy:"
pp stats

10.times do |i|
  buffers[i] = data.dup
  buffers[i][0] = 'a' # copy!

  puts "After copy \##{i + 1}"
  pp stats
end

puts "Done!"

