# Ruby Performance Optimization Book Examples

## Try to disable GC and define memory consumption

1. GC often makes Ruby slow (especialy <= v2.0 ). And that's because of high memory consumption
2. Ruby has significant memory overhead
3. GC in v2.1+ is 5 times faster!
4. Raw performance of v1.9 - v2.3 is about the same

See [001_gc.rb].

## Try to optimize memory

1. 80% of performance optimization comes from memory optimization

See [002_memory.rb]

