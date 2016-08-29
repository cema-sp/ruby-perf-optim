require 'date'
require 'rubygems'
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'ruby-prof'
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

def parse_row(row)
  row.split(',').map! { |col| parse_col(col) }
end

def parse_col(col)
  if col =~ /^\d+$/
    col.to_i
  elsif col =~ /^\d{4}-\d{2}-\d{2}$/
    Date.parse(col)
  else
    col
  end
end

def find_youngest(people)
  people.map! { |person| person[2] }.max
end

# ----- main -----

data = gen_test_data
GC.disable
result = RubyProf.profile do
  people = parse_data(data)
  find_youngest(people)
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('011_rp_rep_flat.prof', 'w+'), min_percent: 3)

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open('011_rp_rep_graph.prof.html', 'w+'), min_percent: 3)

printer = RubyProf::CallStackPrinter.new(result)
printer.print(File.open('011_rp_rep_stack.prof.html', 'w+'))

