module Rumour
  class Daemon
    TTL = 5

    def initialize(address)
      @local_address = address
      @connection = UDPConnection.new(@local_address, MarshalProtocol.new)
      @actor = Actor.new(@local_address) do |message,addr|
        unless(addr == @local_address || message.ttl <= 0)
          log(message, "->", addr)
          @connection.send_to(message, addr)
        end
      end
    end

    def start
      Thread.new{listen}
    end

    def listen
      loop do
        message, from_address = @connection.receive_from
        log(message, "<-", from_address)
        @actor.receive(message, from_address)
      end
    end

    def update(key, vector)
      @actor.update(Message.new(key, vector, TTL), @local_address)
    end

    def bootstrap(remote_address)
      @actor.bootstrap(remote_address)
    end

    def log(message, action, address)
      puts "#{message} #{action} #{address}"
    end
  end
end
