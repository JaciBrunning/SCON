module SCON
  class Generator

    def generate! hashorarray
      if hashorarray.is_a? Hash
        return generate_type! hashorarray, :hash
      elsif hashorarray.is_a? Array
        return generate_type! hashorarray, :array
      else
        throw TypeError.new("Only Hash or Array types can be generated!")
      end
    end

private
    def generate_type! hash, type
      @unique_keys = {}
      @header_bytes = []
      @body_bytes = []
      @body_bytes << 0xF0 if type == :hash

      if type == :hash
        generate_keys hash
      elsif type == :array
        generate_keys_array hash
      end
      select_keys
      encode_keys

      encode_body hash

      @body_bytes.flatten.pack("c*")
    end

    # Hash Methods
    def generate_keys hash
      hash.each do |key, value|
        keys = key.to_s
        @unique_keys[keys] ||= 0
        @unique_keys[keys] += 1

        if value.is_a? Hash
          generate_keys value
        elsif value.is_a? Array
          generate_keys_array value
        end
      end
    end

    def generate_keys_array array
      array.each do |v|
        generate_keys v if v.is_a? Hash
      end
    end

    def select_keys
      selected = @unique_keys.select { |k, v| v >= 2 }
      @unique_keys = selected.map { |k, v| k }
    end

    def encode_keys
      if @unique_keys.length > 0
        @header_bytes << 0xF1
        @unique_keys.each do |key|
          @header_bytes << Conversions.string_bytes(key)
        end
        @body_bytes.unshift(@header_bytes)
        @header_bytes = nil
      end
    end

    #General Methods
    def encode_body object
      if object.is_a? Hash
        object.each do |k, v|
          encode_value k, v, :hash
        end
      elsif object.is_a? Array
        counter = 0
        object.each_with_index do |v, i|
          encode_value i, v, :array, counter
          counter += 1
        end
      end
    end

    def encode_value key, value, parent_type, array_counter=0
      instruct, serial = 0, nil
      if value.is_a? Hash
        @body_bytes << Constants::DATA[:obj_start]
        encode_key key, parent_type, array_counter
        value.each do |k, v|
          encode_value k, v, :hash
        end
        @body_bytes << Constants::DATA[:obj_end]
        return
      elsif value.is_a? Array
        @body_bytes << Constants::DATA[:arr_start]
        encode_key key, parent_type, array_counter
        counter = 0
        value.each_with_index do |v, i|
          encode_value i, v, :array, counter
          counter += 1
        end
        @body_bytes << Constants::DATA[:arr_end]
        return
      elsif value.is_a? Fixnum
        instruct, serial = auto_number(value)
      elsif value.is_a? Float
        instruct = Constants::DATA[:float]
        serial = Conversions.float_bytes(value)
      elsif value.is_a? String
        bytes = Conversions.string_bytes(value)
        instruct = bytes[0]
        serial = bytes[1]
      elsif value.is_a?(TrueClass)
        instruct = Constants::DATA[:true]
      elsif value.is_a?(FalseClass)
        instruct = Constants::DATA[:false]
      elsif value.nil?
        instruct = Constants::DATA[:nil]
      end

      @body_bytes << instruct
      encode_key key, parent_type, array_counter
      @body_bytes << serial unless serial.nil?
    end

    def encode_key key, parent_type, array_counter
      if parent_type == :hash
        keys = key.to_s
        encode_key_hash keys
      end
    end

    def encode_key_hash keys
      if @unique_keys.include? keys
        index = @unique_keys.index(keys)
        @body_bytes << auto_number(index)
      else
        @body_bytes << Conversions.string_bytes(keys)
      end
    end

    def auto_number value
      returnval = []
      if value <= 0x99 && value >= 0      # Byte, no following data bytes
        returnval[0] = value
      elsif value <= ((2**16)/2-1) && value >= -(((2**16)/2-1))     # Short, following bytes
        returnval[0] = Constants::DATA[:short]
        returnval[1] = Conversions.short_bytes(value)
      elsif value <= ((2**32)/2-1) && value >= -(((2**32)/2-1))     # Integer, following bytes
        returnval[0] = Constants::DATA[:integer]
        returnval[1] = Conversions.int_bytes(value)
      else    # Long, following bytes
        returnval[0] = Constants::DATA[:long]
        returnval[1] = Conversions.long_bytes(value)
      end
      returnval
    end

  end
end
