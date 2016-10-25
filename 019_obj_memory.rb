puts "memory usage at start %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

str = 'x' * 1024 * 1024 * 10 # 10 MB

puts "memory usage after allocation %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

str = nil
GC.start(full_mark: true, immediate_sweep: true)

puts "memory usage after GC %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

