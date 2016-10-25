require 'bigdecimal'

def heavy_function
  # Allocate ~450k objects
  Array.new(100_000) { BigDecimal(rand(), 3) }.inject(&:+)
end

# Disable to measure allocation statistics
GC.disable
puts "Total Ruby objects before operation: #{ObjectSpace.count_objects[:TOTAL]}"

read, write = IO.pipe

pid = fork do
  GC.enable # In forked process

  read.close
  result = heavy_function
  Marshal.dump(result, write)

  exit!(0)
end

write.close
result = Marshal.load(read.read)

Process.waitpid(pid)
puts "Result: #{result.inspect}"

puts "Total Ruby objects after operation: #{ObjectSpace.count_objects[:TOTAL]}"

