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