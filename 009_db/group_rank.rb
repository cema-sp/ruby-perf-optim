require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: '009_company',
  host: 'localhost',
  username: 'postgres'
)

class Empsalary < ActiveRecord::Base
  attr_accessor :rank
end

time = Benchmark.realtime do
  salaries = Empsalary.order(:department_id, :salary).all

  key, counter = nil, nil
  salaries.each do |s|
    if s.department_id != key
      key, counter = s.department_id, 0
    end

    counter += 1
    s.rank = counter
  end
end

puts 'Group rank with ActiveRecord: %5.3fs' % time

sql = <<SQL
  select
      department_id,
    employee_id,
    salary,
    rank() over(partition by department_id order by salary desc) as rank
  from
    empsalaries;
SQL

time = Benchmark.realtime do
  salaries = Empsalary.find_by_sql(sql).each { |s| s.rank = s[:rank] }
  # puts salaries.first(3).map{ |s| s.as_json }
end

puts 'Group rank with ActiveRecord: %5.3fs' % time

