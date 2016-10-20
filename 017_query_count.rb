require 'rubygems'
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'activesupport'
  gem 'activerecord'
  gem 'pg'
end

require 'active_record'

puts "Loaded gems"

class Migration < ActiveRecord::Migration[5.0]
  def up
    create_table :things do |t|
      t.string :col0
      t.string :col1
      t.string :col2
      t.string :col3
      t.string :col4
    end

    create_table :minions do |t|
      t.integer :thing_id
      t.string :name
    end

    sql = <<-END
      INSERT INTO
        things(col0, col1, col2, col3, col4)
        (SELECT
          rpad('x', 100, 'x'),
          rpad('x', 100, 'x'),
          rpad('x', 100, 'x'),
          rpad('x', 100, 'x'),
          rpad('x', 100, 'x')
        FROM generate_series(1, 100)
        );
    END

    ActiveRecord::Base.connection.execute sql
  end

  def down
    drop_table :things
    drop_table :minions
  end
end

class Thing < ActiveRecord::Base
  has_many :minions
end

class Minion < ActiveRecord::Base
  belongs_to :thing
end

def migrate(dir = :up)
  Migration.new.migrate(dir)
end

def track_queries
  results = []
  ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    query_name = event.payload[:name]

    next if %w(SCHEMA).include? query_name # skip schema lookups
    results << query_name
  end
  yield
  ActiveSupport::Notifications.unsubscribe('sql.active_record')
  results
end
# ------ main ------

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: '017_things',
  host: 'localhost',
  username: 'postgres'
)

cmd = ARGV[0]

case cmd
when '--migrate'
  migrate(:up)
when '--rollback'
  migrate(:down)
when '--each'
  puts "Queries:\n"
  puts (track_queries { Thing.limit(10).each { |thing| thing.minions.load } })
when '--include'
  puts "Queries:\n"
  puts (track_queries { Thing.limit(10).includes(:minions).load })
else
  puts "No command provided!"
  exit!(1)
end

exit!(0)

