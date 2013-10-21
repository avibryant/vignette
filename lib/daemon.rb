module Rumour
  class Daemon
    TTL = 5

    def initialize(address)
      @local_address = address
      @connection = UDPConnection.new(@local_address, MarshalProtocol.new)
      @node = Node.new(@local_address) do |envelope,addr|
        unless(addr == @local_address || envelope.ttl <= 0)
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
      @node.bootstrap(remote_address)
    end

    def log(envelope, action, address)
      puts "#{envelope} #{action} #{address}"
    end
  end
end
