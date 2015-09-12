module SCON
  class Parser

    def parse! data
      @data = data.bytes
      if @data[0] == 0xF1  # Has Key Lookup
        @keyassoc = []
        @data.shift
        while (temp = parse_inline_string(@data)) != false
          @keyassoc << temp
        end
      end

      if @data[0] == 0xF0    # Is a Hash
        @data.shift
        root = {}
        hash_parse_entries root
        return root
      else                  # Is an Array
        root = []
        array_parse_entries root
        return root
      end
    end

private

  def parse_inline_string data
    if (data[0] > 0xD0) && (data[0] < (0xD0 + 32))
      count = data.shift
      return data.shift(count - 0xD0).pack("c*")
    elsif data[0] == 0xD0
      data.shift
      str = []
      while (tmp = data.shift) != 0xFF
        str << tmp
      end
      return str.pack("c*").force_encoding("utf-8")
    elsif data[0] == Constants::DATA[:zero_string]
      data.shift
      return ""
    else
      return false
    end
  end

  def parse_string instruct
    if (instruct > 0xD0) && (instruct < (0xD0 + 32))
      return @data.shift(instruct - 0xD0).pack("c*")
    elsif instruct == 0xD0
      str = []
      while (tmp = @data.shift) != 0xFF
        str << tmp
      end
      return str.pack("c*").force_encoding("utf-8")
    else
      return false
    end
  end

  def parse_value instruct
    if instruct <= 0x99 && instruct >= 0      # Byte, no following data bytes
      return instruct
    elsif instruct == Constants::DATA[:byte]
      return @data.shift[0]
    elsif instruct == Constants::DATA[:short]
      return @data.shift(2).pack("c*").unpack("s<")[0]
    elsif instruct == Constants::DATA[:integer]
      return @data.shift(4).pack("c*").unpack("i<")[0]
    elsif instruct == Constants::DATA[:long]
      return @data.shift(8).pack("c*").unpack("q<")[0]
    elsif instruct == Constants::DATA[:float]
      return @data.shift(4).pack("c*").unpack("e")[0]
    elsif instruct == Constants::DATA[:double]
      return @data.shift(8).pack("c*").unpack("E")[0]
    elsif instruct == Constants::DATA[:nil]
      return nil
    elsif instruct == Constants::DATA[:true]
      return true
    elsif instruct == Constants::DATA[:false]
      return false
    elsif (tmp = parse_string(instruct)) != false
      return tmp
    elsif instruct == Constants::DATA[:obj_start]
      root = {}
      hash_parse_entries root
      return root
    elsif instruct == Constants::DATA[:arr_start]
      root = []
      array_parse_entries root
      return root
    end
  end

  def hash_parse_entries parent
    closed = false
    while !closed
      data_type = @data.shift

      if data_type == Constants::DATA[:obj_end]
        closed = true
        next
      end

      index_meta = @data.shift
      index_val = parse_value index_meta
      data_value = parse_value data_type

      if index_val.is_a? Fixnum
        parent[@keyassoc[index_val]] = data_value
      elsif index_val.is_a? String
        parent[index_val] = data_value
      end

      closed = true if @data.length == 0
    end
  end

  def array_parse_entries parent
    closed = false
    while !closed
      data_type = @data.shift

      if data_type == Constants::DATA[:arr_end]
        closed = true
        next
      end
      if data_type == Constants::DATA[:arr_padding]
        count = parse_value @data.shift
        count.times { parent << nil }
        data_type = @data.shift
      end
      data_value = parse_value data_type
      parent << data_value

      closed = true if @data.length == 0
    end
  end

  end
end
