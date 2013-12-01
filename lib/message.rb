require 'msgpack'

module Vignette
  class Message
    attr_reader :key, :vector, :ttl

    def initialize(key, vector, ttl = 50)
      @key, @vector, @ttl = key, vector, ttl
    end

    def self.from_bytes(bytes)
      hash = MessagePack.unpack(bytes)
      Message.new(hash["key"], hash["vector"], hash["ttl"])
    end

    def to_hash
      { "key" => key, "vector" => vector, "ttl" => ttl}
    end

    def to_bytes
      to_hash.to_msgpack
    end

    def to_s
      to_hash.to_s
    end
  end
end
