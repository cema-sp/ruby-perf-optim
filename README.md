# Ruby Performance Optimization

This notes are adapted from these sources:

1. [Ruby Performance Optimization]
2. [SpeedShop]

## What makes Ruby so slow

1. GC often makes Ruby slow (especially for Ruby `<= 2.0`). And that is because of high memory consumption & allocation
2. Ruby has significant memory overhead
3. GC in Ruby `>= 2.1` is 5 times faster than in previous versions
4. Raw performance of Ruby `1.9 - 2.3` is about the same

See [001_gc.rb](001_gc.rb).

## Optimize memory

Use **GC::Profiler** to get some GC runs information.

1. 80% of performance optimization comes from memory optimization

  See [002_memory.rb](002_memory.rb)

2. GC::Profiler has memory and CPU overhead

  See [wrapper.rb](wrapper.rb) for custom wrapper example.

3. Save memory by avoiding copying objects, modify them in place if it is possible (use ! bang-methods)

  See [004_string_bang.rb](004_string_bang.rb)

4. If your String is less than 40 bytes - use `<<` method instead of `+=` to concatenate it and Ruby will not allocate an additional object

  See [004_array_bang.rb](004_array_bang.rb) (w/ GC)

5. Read files line by line. And keep in mind not only total memory consumption but also peaks

  See [005_files.rb](005_files.rb) (w/ and w/o GC)

6. Callbacks (Procs & lambdas) cause its context (seized variables & object in which callback was created) to stay in memory until callback finalized. If you store callbacks, do not forget to remove them after they called.

  See [006_callbacks_1.rb](006_callbacks_1.rb)  
  See [006_callbacks_2.rb](006_callbacks_2.rb)  
  See [006_callbacks_3.rb](006_callbacks_3.rb)  

7. Try to avoid `&block` and use `yield` instead (former copies context stack while latter not)

8. Iterators use block arguments, so use them carefully

  Note following:

  1. GC will not collect iterable object (Array or Hash) before all iterations finished
  2. Iterators create temp objects

  Solutions:

  1. Free objects from the collection during iteration & use `each!` pattern

    See [007_iter_1.rb](007_iter_1.rb)

  2. Look at C code to find object allocations

    See [007_iter_2.rb](007_iter_2.rb) (for Ruby `< 2.3.0`)

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


9. Date parsing is slow, it is better to use defined date format and `strptime` method

  See [008_date_parsing.rb](008_date_parsing.rb)

10. `Object#class`, `Object#is_a?`, `Object#kind_of?` are slow when used inside iterators

11. Use SQL for aggregation & calculation if it is possible

  See [009_db/](009_db) (database query itself is only 30ms)

12. Use native (_compiled C_) gems if possible

## Optimize Rails

### What is fast?

For **App Server**:

  * fast: `<50ms`
  * ok:   `<300ms`
  * slow: `>300ms`

For **API**: 2 times faster!

For **Frontend**:

  * fast: `<500ms`
  * ok:   `<2s`
  * slow: `>2s`

### Tips

1. ActiveRecord uses 3x DB data size memory and often calls GC
2. Use `#pluck`, `#select` to load only necessary data
3. Preload associations if you plan to use them
4. Use `#find_by_sql` to aggregate associations data
5. Use `#find_each` & `#find_in_batches`
6. To perform simple operations use following methods:  

  * `ActiveRecord::Base.connection.execute`  
  * `ActiveRecord::Base.connection.exec_query`  
  * `ActiveRecord::Base.connection.select_values`  
  * `#update_all` 

7. Use `render partial: 'a', collection: @col`, which loads partial template only once
8. Paginate large views
9. You may disable logging to increase performance
10. Watch your helpers, they may be iterators-unsafe

### Caching

Use Rails `cache(obj) {}` method to cache ActiveRecord objects expired by either:

  - class
  - id
  - `updated_at`
  - view

Avoid 'Russian doll' (nested) cache blocks or cache 'id-arrays' like following:

~~~erb
<% cache(["list", items.maximum(:updated_at)]) do %>
  <ul>
    <% items.each do |item| %>
      <% cache(item) do %>
        ...
      <% end %>
    <% end %>
  </ul>
<% end %>
~~~

If you refer relations in views, do not forget to `touch` objects: `belongs_to :obj, touch: true`

Main Rails cache stores:

  - **ActiveSupport::FileStore** - shared between processes, and cheap, but has no LRU
  - **ActiveSupport::MemoryStore** - fast, but expensive and could not be shared
  - **Memcache / dalli** - shared and distributed, but expensive ,tough in config and
    has record size limits
  - **Redis** - shared & distributed, could persist and evict old records, but expensive 
    and supports only strings
  - **LRURedux** - very fast, but not shared, expensive and low-level

### Heroku

You should avoid falling into swap on Heroku, so calculate number of workers carefully 
(128Mb for master and 256Mb for each worker).

If you have `> 60 req/s`, use **unicorn** / **puma** / **passenger** (not **thin** / **webrick**).

Try [derailed_benchmarks] to see memory consumption.

Check out 24-hours memory consumption graphs.

Worker killers may be useful if you have undefined memory leaks. Check that killer 
perform not more frequently than once an hour.

Serve assets from S3 / CDN or exclude them from monitoring.

### Tools

* [wrk]
* [Apache Bench]

## Profiling

_Profiling = measuring CPU/Memory usage + interpreting results_

__For CPU profiling disable GC!__

### ruby-prof

__ruby-prof__ gem has both API (for isolated profiling) and CLI (for startup profiling) interfaces. It also has a Rack Middleware for Rails.

See [010_rp_1.rb](010_rp_1.rb)

Some programs may spend more time on startup than on actual code execution.  
Sometimes `GC.disable` may take a significant amount of time because of _lazy GC sweep_.

Use `Rack::RubyProf` middleware to profile Rails apps. Include it before `Rack::Runtime` to include other middlewares in the report.  
To disable GC, use custom middleware (see [010_rp_rails/config/application.rb](010_rp_rails/config/application.rb)).

Rails profiling best practices:

1. Disable GC
2. Always profile in _production_ mode
3. Profile twice and discard cold-start results
4. Profile w/ & w/o caching if you use it
5. Profile with data of production DB size

The most useful report types for ruby-prof (see [011_rp_rep.rb](011_rp_rep.rb)):

1. __Flat__ (Shows which functions are slow)
2. __Call graph__ (Shows callers and callees)
3. __Stack report__ (Shows execution paths; good for small chunks of code)

You also should try [rack-mini-profiler] with flamegraphs.

#### Callgrind format

Ruby-prof can generate callgrind files with CallTreePrinter (see [011_rp_rep.rb](011_rp_rep.rb)).  
Callgrind profiles have double counting ~~issue~~!  
Callgrind profiles show loops as recursion.  
It is better to start from the bottom of Call Graph and optimize its leaves first.

## Optimizing with Profiler

Always start optimizing with writing tests & benchmarks.  
**!** Profiler adds up to **10x** time to function calls.  
If you optimized individual functions but the whole thing is still slow, look at the code at a higher abstraction level.

Optimization tips:

1. Optimization with the profiler is a craft (not engineering)
2. Always write test
3. Never forget about the big picture
4. Profiler obscures measurements, benchmarks needed

## Profile Memory

80% of Ruby performance optimization comes from memory optimization.

You have 3 options for memory profiling:

1. Massif / Stackprof profiles
2. Patched Ruby interpreter & ruby-prof
3. Printing `GC#stat` & `GC::Profiler` measurements

### Specific tools

To detect if memory profiling needed you should use *monitoring* and *profiling* tools.

Good tool for profiling is **Valgrind Massif** but it shows memory allocations only for C/C++ code.

Another tool is **Stackprof** that shows number of object allocations (that is proportional to memory consumption) (see [014_stackprof.rb](014_stackprof.rb)). But if your code allocates a small number of large objects, it won't help.  
Stackprof could generate flamegraphs and it's OK to use it in production because it has no overhead.

### Patched Ruby & RubyProf

You need RailsExpress patched Ruby (google it). Then set RubyProf *measure mode* and use one the of printers (see [015_rp_memory.rb](015_rp_memory.rb)). Don't forget to enable memory stats with `GC.enable_stats`.

Modes for memory profiling:

* MEMORY - mem usage
* ALLOCATIONS - # of object allocations
* GC_RUNS - # of GC runs (useless for optimization)
* GC_TIME - GC time (useless for optimization)

Memory profile shows only new memory allocations (not the total amount of memory at the time) and doesn't show GC reclaims.

**!** Ruby allocates temp object for string > 23 chars.

### Manual way

We can measure current memory usage, but it is not very useful.

On Linux we can use OS tools:

~~~ruby
memory_before = `ps -o rss= -p #{Process.pid}`.to_i / 1024
do_something
memory_after = `ps -o rss= -p #{Process.pid}`.to_i / 1024
~~~

`GC#stat` and `GC::Profiler` can reveal some information.

## Measure

For adequate measurements, we should make a number of measurements and take median value.  
A lot of external (CPU, OS, latency, etc.) and internal (GC runs, etc.) factors affect measured numbers.
It is impossible to entirely exclude them.

### Minimize external factors

* Disable dynamic CPU frequency (`governor`, `cpupower` in Linux)
* Warm up machine

### Minimize internal factors

Two things can affect application: GC and System calls (including I/O calls).

You may disable GC for measurements or force it before benchmarking with `GC.start` (but not in a loop **!** because of a new object being created in it).  
On Linux & Mac OS process fork is able to fix that issue:

~~~ruby
100.times do
  GC.start
  pid = fork do
    GC.start
    m = Benchmark.realtime { ... }
  end

  Process.waitpid(pid)
end
~~~

### Analyze with Statistics

*Confidence interval* - interval within which we can confidently state the true optimization lies.  
*Level of confidence* - the size of the confidence interval.

Analysis algorithm:

1. Estimate means:

  `mx = sum(xs) / count(xs); my = sum(ys) / count(ys)`

2. Calculate standard deviation:

  `sdx = sqrt(sum(sqr(xi - mx)) / count(xs) - 1); sdy = sqrt(sum(sqr(yi - my)) / count(ys) - 1)` 

3. Calculate optimization mean:

  `mo = mx - my`

4. Calculate standard error:

  `err = sqrt(sqr(sdx) / count(xs) + sqr(sdy) / count(ys))`

5. Get the confidence interval:

  `interval = (mo - 2 * err)..(mo + 2 * err)`

Both lower and upper bounds of confidence interval should be > 0 (see [016_statistics.rb](016_statistics.rb)). Always make more than **30** measurements for good results.

For Ruby, round measures to the tenth of milliseconds (e.g. 1.23 s). For rounding use tie-breaking "round half to even" rule (round 5 to even number: 1.25 ~= 1.2, 1.35 ~= 1.4).

For better results, you may exclude outliers and first (cold) measure results.

### Use benchmark tools

* [benchmark/ips] - measures Ruby code iteration per second

### Test Rails performance

For Rails performance testing, use special gems (e.g. *rails-perftest*) or write your own custom assertions.

Tips:

* It is a good practice to create Rails performance *integration* tests
* But don't forget to turn on caching and set log level to `:info`
* Database size may affect your results, so rollback transactions or clear data
* Write performance test for complex DB queries
* Test DB queries count and try to reduce it (may use *assert_value* gem) (see [017_query_count.rb](017_query_count.rb))
* Generate enough data for performance test

## Think Outside the Box

Ruby program may be optimized not only by optimizing its code. Application may use various dependencies, services, and third party software.

### Restart long-running processes

Sometimes it is OK to restart long-running ruby processes.
Memory consumption grows with time and GC slows down with more memory allocated.

**!** In most cases ruby won't give objects heap memory back to OS.

Applications cycling ways:

1. Hosting platform tools (Heroku, etc.)
2. Process management tools (monit, god, runit, systemd, etc.)
3. OS limits (setrlimit)
4. Cycle Unicorn workers

### Use process forks & background jobs

Objects-heavy calculations should be started in forks, so when forked process exits, heap memory will be returned to OS (see [018_heavy_forks.rb](018_heavy_forks.rb)).
There are 3 common ways to return result from fork: files, DB, I/O pipe.

**!** Doesn't work with threads, only forks (threads share ObjectSpace).

For Rails use background jobs (*delayed_job*) and workers (*sidekiq*).

**!** Sidekiq uses threads, so you should monitor and restart Sidekiq workers yourself.

### Do OOBGC (Out-of-Band GC)

*Not useful since Ruby 2.2*.

OOBGC - starting GC when an application has a low workload.  
Unicorn has the direct support of OOBGC via *unicorn/oob_gc* middleware.

For Ruby 2.1+ you can use gem *gctool*. But be careful with threads: starting GC in one thread will affect all other threads of the process.

### Tune your Database

For PostgreSQL:

* Let DB use maximum memory
* DB should have enough space for sorts and aggregations
* Log slow queries to reproduce problem

PostgreSQL configuration best practives:

~~~conf
effective_cache_size <RAM * 3/4>
shared_buffers <RAM * 1/4>
# aggregations memory
work_mem <2^(log(RAM / MAX_CONN)/log(2))>
# vacuum & indices creation
maintenance_work_mem <2^(log(RAM / 16)/log(2))>
log_autovacuum_min_duration 1000ms
log_min_duration_statement 1000ms
auto_explain.log_min_duration 1000ms
shared_preload_libraries 'auto_explain'
custom_variable_classes 'auto_explain'
auto_explain.log_analyze off
~~~

### Buy more resources

Most important criteria:

1. RAM
2. I/O performance (disk)
3. Database config
4. Other

## Tune Up the GC

Ruby stores objects in its own heap (*objects heap*) and uses OS heap for data that doesn't fit into objects.

Every object in Ruby is `RVALUE` struct. Its size:

* 20 bytes for 32-bit OS (4-byte aligned)
* 24 bytes for 32-bit OS (8-byte aligned)
* 40 bytes for 64-bit OS

Check `RVALUE` size with following commands:

~~~
gdb `rbenv which ruby`
p sizeof(RVALUE)
~~~

**!** A medium-sized Rails App allocates ~ 0.5M objects at startup.

Ruby heap space (*objects heap*) -> N heap pages -> M heap slots. Heap slot contains one object.  
To allocate a new object, Ruby takes an unused slot. If no unused slot found, interpreter allocates more heap pages.

### Ruby 1.8

Allocates 10_000 slots at startup (1 page) and then adds by 1 page (page = prev_page * 1.8)

### Ruby 1.9 - 2.0

Heap page = 16kB (~ 408 objects).  
Allocates 10_000 slots (24 pages) and then adds by N 16kB pages (N = prev_pages * 1.8 - prev_pages).

Some GC stats (`GC.stat`) for Ruby 1.9:

* count - GC runs
* heap_used - pages allocated (heap_used * 408 * 40b = memory allocated)
* heap_increment - more pages to allocate before GC run
* heap_length = heap_used + heap_increment
* heap_live_num - live object in heap
* heap_free_num - free slots in heap
* heap_final_num - object to finalize by GC

### Ruby 2.1

GC_HEAP_GROWTH_FACTOR - growth factor (default = 1.8)  
GC_HEAP_GROWTH_MAX_SLOTS - slots growth constraint

Allocates 1 page + 24 pages and then adds by N pages (N = prev_nonempty_pages * GC_HEAP_GROWTH_FACTOR - prev_nonempty_pages).

In Ruby 2.1 pages added on demand (heap_length != N of allocated pages, it's just counter).

Some GC stats (`GC.stat`) for Ruby 2.1:

* heap_free_num - free slots in allocated heap pages
* heap_swept_slot - slots swept (freed) on last GC

*Eden* - occupied heap pages.  
*Tomb* - empty heap pages.

To allocate a new object Ruby first looks for free space in *eden* and only then in *tomb*.

**!** Ruby frees (gives it back to OS) objects heap memory by pages.

Algorithm to determine number of pages to free:

1. `sw`, - number of pages touched on sweep (number of objects / HEAP_OBJ_LIMIT)
2. `rem = max(total_heap_pages * 0.8, init_slots)`, - pages that should stay
3. `fr = total_heap_pages - rem`, - pages to free

Usually objects heap growth is 80% while reduction is 10%.

### Ruby 2.2

Some GC stats (`GC.stat`) for Ruby 2.2:

* heap_allocated_pages = heap_used
* heap_allocatable_pages = heap_increment
* heap_sorted_pages = heap_length
* heap_available_slots = heap_live_slots + heap_free_slots + heap_final_slots

Growth is the same as in Ruby 2.1 but relative to *eden* pages, not allocated pages.

### Object Memory

If Ruby object is bigger than half of 40 bytes (on 64-bit OS) it will be stored **entirely** outside the *objects heap*. This *object memory* will be freed and returned to OS after GC (see [019_obj_memory.rb](019_obj_memory.rb)).

Ruby string (`RSTRING` struct) can store only 23 bytes of payload.  
`ObjectSpace.memsize_of(obj)` - shown object size in memory in bytes.

For example, 24 chars String will have a size of 65 bytes (24 outside the heap + 1 for upkeep + 40 bytes inside heap).

It may be OK to allocate a big object in memory because it doesn't affect GC performance (but may lead to GC run), but it is crucial to allocate a large amount of small objects in *objects heap*.

## What triggers GC

Two main purposes are:

* No more free slots in the *objects heap* space
* Current memory allocation limit (malloc) has been exceeded

### Heap Usage

If there are no more free slots in *objects heap*, Ruby invoces GC to free *enough slots*, which is `max(allocated_slots * 0.2, GC_HEAP_FREE_SLOTS)` (see [020_heap_gc.rb](020_heap_gc.rb)).

### Malloc Limit

GC will be triggered when you allocate more than the current memory limit (Ruby <= 2.0 `GC_MALLOC_LIMIT` ~= 8M bytes (7.63 Mb)) (see [021_malloc_gc.rb](021_malloc_gc.rb)).

Malloc limit adjusted in runtime proportional to memory usage by an application, but not any good.

Ruby 2.1 introduced **generational GC** - it divides all objects into *new* and *old* (survived a GC) generations with own limits `GC_MALLOC_LIMIT_MIN`, `GC_OLDMALLOC_LIMIT_MIN` (both 16 Mb initially).  
They can grow up to `GC_MALLOC_LIMIT_MAX`, `GC_OLDMALLOC_LIMIT_MAX` (32 Mb and 128 Mb by default).  
Growth factors are `GC_MALLOC_LIMIT_GROWTH_FACTOR` and `GC_OLDMALLOC_LIMIT_GROWTH_FACTOR` (1.4 and 1.2 by default). And reduction factor is 0.98.

Ruby 2.2 introduced **incremental GC** - several mark steps followed by several sweeps (smaller "stop the world").

Ruby uses *mark & sweep* GC and stops the world for *mark* steps.  
Generational GC divides all GC invocations to *minor* (only for new objects) and *major* (for both new and old ones).

Some related `GC.stat` params:

* malloc_limit - malloc limit for the new generation
* malloc_increase - memory allocated by the new generation since the last GC
* oldmalloc_limit
* oldmalloc_increase

## GC Tuning

### Ruby >= 2.1

Tune up following env vars:

* RUBY_GC_HEAP_INIT_SLOTS - initial slots number (default is 10_000)
* RUBY_GC_HEAP_FREE_SLOTS - minimum number of slots to free (default is 4096)
* RUBY_GC_HEAP_GROWTH_FACTOR - (default is 1.8)
* RUBY_GC_HEAP_GROWTH_MAX_SLOTS - (default is 0 = unlimited)
* RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR - affects *major* GC invocation time (default is 2)
* RUBY_[parameters for malloc limits]

### Ruby <= 2.0

Tune up following env vars:

* RUBY_HEAP_MIN_SLOTS - initial slots number
* RUBY_FREE_MIN - minimum number of slots to free
* RUBY_GC_MALLOC_LIMIT - change it to 16 Mb + (default is 8 Mb)

To change other Ruby GC parameters for versions below 2.0, you have to recompile interpreter.

## Static Analysis Tools

* [fasterer] - gives performance suggestions

## Links

* [Fast Ruby] - collection of useful tips & tricks

[Ruby Performance Optimization]: https://pragprog.com/book/adrpo/ruby-performance-optimization "Ruby Performance Optimization"
[SpeedShop]: https://www.speedshop.co/blog/ "SpeedShop"
[rack-mini-profiler]: https://github.com/MiniProfiler/rack-mini-profiler "Rack mini profiler"
[wrk]: https://github.com/wg/wrk "wrk"
[Apache Bench]: https://httpd.apache.org/docs/2.4/programs/ab.html "Apache Bench"
[derailed_benchmarks]: https://github.com/schneems/derailed_benchmarks "derailed_benchmarks"
[fasterer]: https://github.com/DamirSvrtan/fasterer "fasterer"
[benchmark/ips]: https://github.com/evanphx/benchmark-ips "benchmark/ips"
[Fast Ruby]: https://github.com/JuanitoFatas/fast-ruby "Fast Ruby"
