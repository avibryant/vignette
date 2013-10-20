module Rumour
  class Daemon
    TTL = 3

    def initialize(address)
      @local_address = address
      @connection = UDPConnection.new(@local_address, MarshalProtocol.new)
      @node = Node.new do |envelope,addr|
        unless(addr == @local_address)
          log(envelope, "->", addr)
          @connection.send_to(envelope, addr)
        end
      end
    end

    def start
      Thread.new{listen}
    end

    def listen
      loop do
        envelope, from_address = @connection.receive_from
        log(envelope, "<-", from_address)
        @node.receive(envelope, from_address)
      end
    end

    def update(key, vector)
      message = Message.new(key, vector)
      envelope = Envelope.new(@local_address, TTL, message)
      @node.receive(envelope, @local_address)
    end

    def bootstrap(remote_address)
      message = Message.new("bootstrap", {0 => 0})
      envelope = Envelope.new(@local_address, TTL, message)
      @node.receive(envelope, remote_address)
      update("bootstrap", {0 => 1})
    end

    def log(envelope, action, address)
      puts "#{envelope} #{action} #{address}"
    end
  end
end
