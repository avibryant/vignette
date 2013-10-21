module Rumour
  Message = Struct.new(:key, :vector, :ttl)

  class MarshalProtocol

    def max_len
      1500
    end

    def to_bytes(message)
      Marshal.dump(message)
    end

    def from_bytes(bytes)
      Marshal.load(bytes)
    end
  end
end