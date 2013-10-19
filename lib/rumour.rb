require 'socket'

module Rumour
  MAX_LEN = 1500
  NEIGHBORS = "N"
  VALUES = "V"

  def self.start(port, seed)
    sock = UDPSocket.new
    sock.bind("0.0.0.0", port)
    node = Node.new(sock)
    node.process(Message.new(NEIGHBORS, seed.to_s, {}))
    node.process(Message.new(NEIGHBORS, port.to_s, {}))
    node.listen_forever
  end

  def self.inject(seed, key, n)
    n.times do
      message = Message.new(VALUES, key, {rand(512) => rand(32)})
      UDPSocket.new.send(message.to_bytes, 0, "127.0.0.1", seed)
    end
  end

  class Message
    attr_reader :type, :key, :vector

    def self.from_bytes(str)
      Marshal.load(str)
    end

    def initialize(type, key, vector)
      @type, @key, @vector = type, key, vector
    end

    def update(message)
      updated = {}
      message.vector.each do |i,v|
        if(v > (@vector[i] || 0))
          @vector[i] = v
          updated[i] = v
        end
      end

      unless updated.empty?
        Message.new(@type, @key, updated)
      end
    end

    def to_bytes
      Marshal.dump(self)
    end

    def to_s
      [@type, @key, @vector].inspect
    end
  end

  class MessageCache
    def initialize
      @messages = {}
    end

    def update(message)
      if(current = @messages[message.key])
        current.update(message)
      else
        @messages[message.key] = message
        message
      end
    end

    def messages
      @messages
    end
  end

  class Node
    def initialize(udp)
      @udp = udp
      @neighbours = MessageCache.new
      @values = MessageCache.new
    end

    def listen_forever
      loop{listen_once}
    end

    def listen_once
      bytes, sender = @udp.recvfrom(MAX_LEN)
      message = Message.from_bytes(bytes)
      process(message)
    end

    def process(message)
      log("Got #{message}")
      case message.type
      when NEIGHBORS
        update(@neighbours, message)
      when VALUES
        update(@values, message)
      else
        raise "Unknown message type: #{type}"
      end
    end

    def update(cache, message)
      if updated = cache.update(message)
        gossip(updated)
      end
    end

    def random_neighbours(n)
      @neighbours.messages.keys.shuffle[0..n].map{|k| k.to_i}
    end

    def gossip(message)
      random_neighbours(2).each do |neighbor|
        tell(message, neighbor)
      end
    end

    def tell(message, neighbour)
      log("Sending #{message} to #{neighbour}")
      @udp.send(message.to_bytes, 0, "127.0.0.1", neighbour)
    end

    def log(str)
      $stderr.puts "[#{@udp.addr[1]}] #{str}"
    end
  end
end