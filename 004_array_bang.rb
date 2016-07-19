require 'wrapper'

data = Array.new(100) { 'x' * 1024 * 1024 } # 100 Mb

measure do
  data.map { |str| str.upcase }
end

measure do
  data.map! { |str| str.upcase! }
end

