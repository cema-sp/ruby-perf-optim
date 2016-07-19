require 'wrapper'
require 'csv'

puts 'Just read file in memory:'
measure do
  File.read('003_10mb.csv')
end

puts 'Read file and manipulate string:'
measure do
  File.readlines('003_10mb.csv').map! do |line|
    line.split(',')
  end
end

puts 'Just read file in memory with CSV lib:'
measure do
  CSV.read('003_10mb.csv')
end

puts 'Read file line by line:'
measure do
  file = File.open('003_10mb.csv', 'r')
  while line = file.gets
    line.split(',')
  end
end

puts 'Read file line by line with CSV lib:'
measure do
  file = CSV.open('003_10mb.csv')
  while line = file.readline
    line
  end
end

