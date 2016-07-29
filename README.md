# Ruby Performance Optimization Book Examples

## Try to disable GC and define memory consumption

1. GC often makes Ruby slow (especialy <= v2.0 ). And that's because of high memory consumption
2. Ruby has significant memory overhead
3. GC in v2.1+ is 5 times faster!
4. Raw performance of v1.9 - v2.3 is about the same

See [001_gc.rb](001_gc.rb)

## Try to optimize memory

1. 80% of performance optimization comes from memory optimization
  See [002_memory.rb](002_memory.rb)

2. GC::Profiler has memory and CPU overhead (See [wrapper.rb](wrapper.rb) for custom wrapper example).

3. Save memory by avoiding copiyng objects, modify them in place if it is possible (use ! methods).

  See [004_string_bang.rb](004_string_bang.rb)

4. If your String is less than 40 bytes - user `<<`, not `+=` method to concatenate it and Ruby will not allocate additional object.

  See [004_array_bang.rb](004_array_bang.rb) (w/ GC)

5. Read files line by line. And keep in mind not only total memory consumption but also peaks.

  See [005_files.rb](005_files.rb) (w/ and w/o GC)

6. Callbacks cause object to stay in memory. If you store callbacks, do not forget to remove them after they called.
  See [006_callbacks_1.rb](006_callbacks_1.rb)
  See [006_callbacks_2.rb](006_callbacks_2.rb)
  See [006_callbacks_3.rb](006_callbacks_3.rb)
  Try to avoid `&block` and use `yield` instead.

7. Iterators use block arguments, so use them carefuly

  Issues:
  1. GC will not collect iterable before iterator is finished
  2. Iterators create temp objects

  Solutions:

  1. Free objects from collection during iteration & use `each!` pattern
    See [007_iter_1.rb](007_iter_1.rb)
  2. Look at C code to find object allocations
    See [007_iter_2.rb](007_iter_2.rb) (for ruby < 2.3.0)

    Table of `T_NODE` allocations per iterator item for ruby 2.1:

    | Iterator         | Enum | Array | Range |  
    | ---------------: | ---- | ----- | ----- |  
    | all?             | 3    | 3     | 3     |  
    | any?             | 2    | 2     | 2     |  
    | collect          | 0    | 1     | 1     |  
    | cycle            | 0    | 1     | 1     |  
    | delete_if        | 0    | —     | 0     |  
    | detect           | 2    | 2     | 2     |  
    | each             | 0    | 0     | 0     |  
    | each_index       | 0    | —     | —     |  
    | each_key         | —    | —     | 0     |  
    | each_pair        | —    | —     | 0     |  
    | each_value       | —    | —     | 0     |  
    | each_with_index  | 2    | 2     | 2     |  
    | each_with_object | 1    | 1     | 1     |  
    | fill             | 0    | —     | —     |  
    | find             | 2    | 2     | 2     |  
    | find_all         | 1    | 1     | 1     |  
    | grep             | 2    | 2     | 2     |  
    | inject           | 2    | 2     | 2     |  
    | map              | 0    | 1     | 1     |  
    | none?            | 2    | 2     | 2     |  
    | one?             | 2    | 2     | 2     |  
    | reduce           | 2    | 2     | 2     |  
    | reject           | 0    | 1     | 0     |  
    | reverse          | 0    | —     | —     |  
    | reverse_each     | 0    | 1     | 1     |  
    | select           | 0    | 1     | 0     |  

8. Date parsing is slow
  See [008_date_parsing.rb](008_date_parsing.rb)

9. `Object#class`, `Object#is_a?`, `Object#kind_of?` are slow when used inside iterators

10. Use SQL for aggregation & calculation if it is possible
  See [009_db](009_db) (database query itself is only 30ms)

11. Use native (compiled C) gems if possible

## Optimize Rails

1. ActiveRecord uses 3x DB data size memory and calls often calls GC

2. Use `#pluck`, `#select` to load only necessary data

3. Preload associations if you plan to use them

4. Use `#find_by_sql` to aggregate associations data

5. Use `#find_each` & `#find_in_batches`

6. Use `ActiveRecord::Base.connection.execute`, `ActiveRecord::Base.connection.exec_query`, `ActiveRecord::Base.connection.select_values`, `#update_all` to perform simple operations

7. Use `render partial: 'a', collection: @col`, which loads partial template only once

8. Paginate large views

9. You may disable logging to increase performance

10. Watch your helpers, they may be iterators-unsafe

## Profiling

_Profiling = measuring CPU/Memory usage + interpreting results_

__For CPU profiling disable GC!__

### ruby-prof

__ruby-prof__ gem has both API (for isolated profiling) and CLI (for startup profiling). It also has Rack Middleware for Rails.

See [010_rp_1.rb](010_rp_1.rb)

Some programs may spend more time on startup than on actual code execution.
Sometimes `GC.disable` may take significant amount of time because of _lazy GC sweep_.

Use `Rack::RubyProf` middleware to profile Rails apps. Include it before `Rack::Runtime` to include other middlewares in report.
To disable GC, use custom middleware [010_rp_rails/config/application.rb](010_rp_rails/config/application.rb).

Rails profiling best practices:

1. Disable GC
2. Always profile in _production_ mode
3. Profile twice and discard cold-start results
4. Profile w/ & w/o caching if you use it


