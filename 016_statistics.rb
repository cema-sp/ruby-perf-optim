require 'benchmark'
require 'pry'

def not_optimal(data)
  data.inject(1) { |prod, i| prod * i }
end

def optimal(data)
  prod = 1
  data.each do |i|
    prod *= i
  end
  prod
end

def measure(trials)
  measures = []

  trials.times do
    GC.start

    read, write = IO.pipe
    pid = fork do
      read.close # forked process doesn't need it
      GC.start

      time = Benchmark.realtime { yield }
      write.write(time)
      exit(0)
    end

    Process.waitpid(pid)
    write.close
    measures << read.read.to_f
  end

  measures
end

def round(num, digits)
  unit = num.to_i
  roundables = ((num - unit) * (10 ** (digits + 2))).to_i
  fractions = roundables / 100
  last = roundables % 100
  last_fraction = fractions % 10

  if last > 50 || (last == 50 && last_fraction.odd?)
    fractions += 1
  end

  (unit + fractions.to_f / (10 ** digits)).round(digits)
end

# ------ benchmarks ------

trials = 33
elements = 100_000

data = Array.new(elements) { 10 }

before = measure(trials) { not_optimal(data) }
after  = measure(trials) { optimal(data) }

before.map!{ |m| round(m, 3) }
after.map!{ |m| round(m, 3) }

# puts "\tBefore:"
# before.each do |time|
#   puts time
# end
#
# puts "\tAfter:"
# after.each do |time|
#   puts time
# end

mx = before.inject(&:+) / trials
my = after.inject(&:+) / trials

sdx = Math.sqrt(before.inject(0) { |acc, x| acc + (x - mx)**2 } / (trials - 1))
sdy = Math.sqrt(after.inject(0) { |acc, y| acc + (y - my)**2 } / (trials - 1))

mo = mx - my

err = Math.sqrt((sdx**2 / trials) + (sdy**2 / trials))

interval = (mo - 2 * err)..(mo + 2 * err)

puts
puts "mx = #{mx}; my = #{my}"
puts "sdx = #{sdx}; sdy = #{sdy}"
puts "mo = #{mo}"
puts "err = #{err}"
puts "interval = #{interval}"

if interval.begin > 0
  puts "\n\tOPTIMIZED!\n"
else
  if interval.end < 0
    puts "\n\tREGRESSION!\n"
  else
    puts "\n\tUNCHANGED!\n"
  end
end

