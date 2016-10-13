require 'date'
require 'rubygems'
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'ruby-prof'
  gem 'minitest'
end

# require 'ruby-prof'

def gen_test_data
  50_000.times.map do |i|
    name = %w(John Piter Silvia).sample + ' ' +
           %w(Lloyd Franco DeSilva).sample

    [i, name, Time.at(rand * Time.now.to_i).strftime('%Y-%m-%d')].join ','
  end.join("\n")
end

def parse_data(data)
  data.split("\n").map! { |row| parse_row(row) }
end

# initial version
# def parse_row(row)
#   row.split(',').map! { |col| parse_col(col) }
# end

# optimized version
def parse_row(row)
  col1, col2, col3 = row.split(',')
  [
    col1.to_i,
    col2,
    Date.new(
      col3[0,4].to_i,
      col3[5,2].to_i,
      col3[8,2].to_i
    )
  ]
end

# initial version
# def parse_col(col)
#   if col =~ /^\d+$/
#     col.to_i
#   elsif col =~ /^\d{4}-\d{2}-\d{2}$/
#     Date.parse(col)
#   else
#     col
#   end
# end

# optimized version
def parse_col(col)
  if col =~ /^\d+$/
    col.to_i
  elsif matches = /^(\d{4})-(\d{2})-(\d{2})$/.match(col)
    Date.new(matches[1].to_i, matches[2].to_i, matches[3].to_i)
  else
    col
  end
end

def find_youngest(people)
  people.map! { |person| person[2] }.max
end

# ----- tests -----

require 'minitest'

class AppTest < Minitest::Test
  def setup
    @parsed_data = parse_data(gen_test_data)
  end

  def test_parsing
    assert_equal @parsed_data.length, 50_000
    assert @parsed_data.all? do |row|
      row.length == 3 && row[0].class == Fixnum && row[2].class == Date
    end
  end

  def test_find_youngest
    youngest = find_youngest(@parsed_data)
    assert @parsed_data.all? do |row|
      youngest >= row
    end
  end
end
# ----- options -----

def run_tests
  Minitest.run([AppTest])
end

def run_benchmark
  require 'benchmark'

  data = gen_test_data
  result = Benchmark.realtime do
    people = parse_data(data)
    find_youngest(people)
  end

  puts "%5.3f" % result

  exit(0)
end

def run_profiler
  data = gen_test_data
  GC.disable
  result = RubyProf.profile do
    people = parse_data(data)
    find_youngest(people)
  end

  printer = RubyProf::CallTreePrinter.new(result)
  printer.print(print_file: true, path: './012_profiling')
end

# ----- main -----

if ARGV[0] == "--test"
  ARGV.clear
  run_tests
  exit(0)
elsif ARGV[0] == "--benchmark"
  run_benchmark
  exit(0)
else
  run_profiler
end

