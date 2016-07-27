class Thing; end

list = Array.new(1000) { Thing.new }
puts ObjectSpace.each_object(Thing).count

list.each.with_index do |item, i|
  GC.start
  puts ObjectSpace.each_object(Thing).count if i == 500
end

list = nil
GC.start
puts ObjectSpace.each_object(Thing).count

puts 'With shift deallocation'

list = Array.new(1000) { Thing.new }
puts ObjectSpace.each_object(Thing).count

while list.count > 0
  GC.start
  puts ObjectSpace.each_object(Thing).count if list.count == 500
  item = list.shift
end

GC.start
puts ObjectSpace.each_object(Thing).count

# each! Pattern

puts 'With each! pattern'

class Array
  def each!
    while count > 0
      yield shift # Shift 1 item and execute block on it without &block capturing
    end
  end
end

Array.new(1000).each { |e| e }
GC.start
puts ObjectSpace.each_object(Thing).count

