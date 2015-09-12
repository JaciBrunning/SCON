$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'scon'
require 'json'
require 'msgpack'
require 'cbor'

TESTS = [
  { :compact => true, :schema => 0 },
  (0...10).to_a,
  { :test => { :test => true, :data => "Hello World" }, :array => [1, 2, 3], :test2 => { :test => false, :array => [{:data => "Hello"}, "World"], :data => 2.3 }}
]

TESTS << (0..10000).map { |x| { :id => x, :name => "My Name", :boolean => true, :test_long_key_name => -258.52325 } }
TESTS << [0, Array.new(100).fill(nil), 100]

TESTS.each_with_index do |value, i|
  puts "Test:     #{i}"
  puts "JSON:     #{JSON.generate(value).bytes.length} Bytes"
  puts "MsgPack:  #{value.to_msgpack.bytes.length} Bytes"
  puts "CBOR:     #{value.to_cbor.bytes.length} Bytes"
  puts "SCON:     #{SCON.generate!(value).bytes.length} Bytes"
  puts
end
