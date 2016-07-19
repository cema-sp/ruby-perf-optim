require 'wrapper'

str = 'X' * 1024 * 1024 * 10 # 10Mb string

measure do
  str = str.downcase
end

measure do
  str = str.downcase!
end

