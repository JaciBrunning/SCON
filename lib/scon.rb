require "scon/version"
require "scon/constants"
require "scon/generator"
require "scon/parser"

module SCON

  def SCON.generate! hashorarray
    SCON::Generator.new.generate! hashorarray
  end

  def SCON.parse! data
    SCON::Parser.new.parse! data
  end

  class Conversions

    def self.int_bytes int
      [int].pack("i<").bytes
    end

    def self.short_bytes short
      [short].pack("s<").bytes
    end

    def self.long_bytes long
      [long].pack("l<").bytes
    end

    def self.string_bytes str
      bytes = str.bytes
      instr = 0xD0
      if bytes.length < 32
        instr += bytes.length
      else
        bytes << 0x03
      end
      [instr, bytes]
    end

    def self.float_bytes float
      [float].pack("e").bytes
    end

  end

end
