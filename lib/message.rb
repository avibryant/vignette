module Rumour
  class Message
    attr_reader :key, :vector, :ttl

    def initialize(key, vector, ttl = 50)
      @key, @vector, @ttl = key, vector, ttl
    end

    def self.from_bytes(bytes)
      Marshal.load(bytes)
    end

    def to_bytes
      Marshal.dump(self)
    end
  end
end

=begin
possible wire format:
1 byte: TTL
2 bytes: key size
key
1 byte: vector format
2 bytes: vector size
vector

Vector formats:
2-byte sparse (10 bits of index, 6 bits of value)
6-byte sparse (2 bytes of index, 4 bytes of value)
1-byte dense
4-byte dense
=end