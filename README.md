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

2. GC::Profiler has memory and CPU overhead (See [wrapper.rb] for custom wrapper example).

3. Save memory by avoiding copiyng objects, modify them in place if it is possible (use ! methods).

  See [004_string_bang.rb](004_string_bang.rb)

4. If your String is less than 40 bytes - user '<<', not '+=' method to concatenate it and Ruby will not allocate additional object.

  See [004_array_bang.rb](004_array_bang.rb) (w/ GC)

5. Read files line by line. And keep in mind not only total memory consumption but also peaks.

  See [005_files.rb](005_files.rb) (w/ and w/o GC)

6. Callbacks cause object to stay in memory. If you store callbacks, do not forget to remove them after they called.
  See [006_callbacks_1.rb](006_callbacks_1.rb)
  See [006_callbacks_2.rb](006_callbacks_2.rb)
  See [006_callbacks_3.rb](006_callbacks_3.rb)
  Try to avoid `&block` and use `yield` instead.

