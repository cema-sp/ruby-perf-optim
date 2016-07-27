GC.disable
before = ObjectSpace.count_objects

Array.new(10000).each do |i|
  [0,1].each do |j|
    # j
  end
end

after = ObjectSpace.count_objects
puts '# of arrays: %d' % (after[:T_ARRAY] - before[:T_ARRAY])
puts '# of nodes: %d' % (after[:T_NODE] - before[:T_NODE])

GC.enable
GC.start
GC.disable

before2 = ObjectSpace.count_objects

Array.new(10000).each do |i|
  [0, 1].each_with_index do |j, index|
    # [j, index]
  end
end

after2 = ObjectSpace.count_objects
puts '# of arrays: %d' % (after2[:T_ARRAY] - before2[:T_ARRAY])
puts '# of nodes: %d' % (after2[:T_NODE] - before2[:T_NODE])

