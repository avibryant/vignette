module Rumour
  class MarshalProtocol

    def max_len
      1500
    end

    def to_bytes(envelope)
      Marshal.dump(envelope)
    end

    def from_bytes(bytes)
      Marshal.load(bytes)
    end
  end
end