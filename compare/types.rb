$:.unshift File.join(File.dirname(__FILE__), "../lib")
require 'scon'
require 'json'
require 'msgpack'
require 'cbor'

def test name, value
  puts "\033[32mTesting: \033[36m#{name}\033[32m \033[36m(#{value.inspect})\033[0m"
  results = {}
  results[:json] = JSON.generate([value]).bytes.length
  results[:msgpack] = [value].to_msgpack.bytes.length
  results[:cbor] = [value].to_cbor.bytes.length
  results[:scon] = SCON.generate!([value]).bytes.length

  smallest = results.first[1]
  winners = []
  results.each do |k, v|
    if v < smallest
      winners = [k]
      smallest = v
    elsif v == smallest
      winners << k
    end
  end

  results = results.sort_by {|k, v| v}
  results.each do |k, v|
    if winners.include? k
      puts "\033[33m   #{k}: #{v} Bytes\033[0m"
    else
      puts "   #{k}: #{v} Bytes"
    end
  end
  puts
end

test "Byte", 0x10
test "Short", 2**16 / 2-10
test "Integer", 2**32/2-10
test "Long", 2**64/2-10
test "Float", 2.38

test "Nil", nil
test "True", true
test "False", false

test "String", "Hello World"
