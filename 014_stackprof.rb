require 'date'
require 'rubygems'
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'stackprof'
end

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

def find_youngest(people)
  people.map! { |person| person[2] }.max
end

# ----- main -----

StackProf.run(mode: :object, out: '014_stackprof.dump', raw: true) do
  data = gen_test_data
  people = parse_data(data)
  find_youngest(people)
end

