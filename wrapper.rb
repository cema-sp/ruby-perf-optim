require 'json'
require 'benchmark'
require 'ap'

def measure(&block)
  no_gc = (ARGV[0] == '--no-gc')

  if no_gc
    GC.disable
  else
    GC.start
  end

  memory_before = `ps -o rss= -p #{Process.pid}`.to_i/1024
  gc_stats_before = GC.stat

  time = Benchmark.realtime do
    yield
  end

  puts "Objects: #{ObjectSpace.count_objects}"
  unless no_gc
    GC.start(full_mark: true, immediate_sweep: true, immediate_mark: false)
    puts "Objects after GC: #{ObjectSpace.count_objects}"
  end

  gc_stats_after = GC.stat
  memory_after = `ps -o rss= -p #{Process.pid}`.to_i/1024

  ap({
    RUBY_VERSION => {
      gc: no_gc ? 'disabled' : 'enabled',
      time: time.round(2),
      gc_count: gc_stats_after[:count] - gc_stats_before[:count],
      memory: "%d MB" % (memory_after - memory_before)
    }
  })
end

