require 'date'

GC.disable # for CPU profiling
Date.parse('2014-07-01')

# run: `ruby-prof -p flat -m 1 -f 010_rp_2.prof 010_rp_2.rb`

