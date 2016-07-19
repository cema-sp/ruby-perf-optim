class LargeObject
  def initialize
    @data = 'x' * 1024 * 1024 * 20 # 20 Mb
  end
end

def do_something
  obj = LargeObject.new
  trap('TERM') { puts obj.inspect }
end

do_something
GC.start(full_mark: true, immediate_sweep: true)
puts "LargeObject instances: #{ObjectSpace.each_object(LargeObject).count}"

