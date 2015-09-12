module SCON
  module Constants
    DATA = {
      :byte => 0xA0,
      :short => 0xA1,
      :integer => 0xA2,
      :long => 0xA3,
      :float => 0xA4,
      :double => 0xA5,

      :nil => 0xC0,
      :true => 0xC1,
      :false => 0xC2,

      :string => 0xD0,

      :obj_start => 0xFA,
      :obj_end => 0xFB,
      :arr_start => 0xFC,
      :arr_end => 0xFD,
      :arr_padding => 0xFE
    }
  end
end
