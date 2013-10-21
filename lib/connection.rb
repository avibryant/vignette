module Rumour
  class Connection
    def initialize(address)
      @local_address = address
      @db = DB.new
      @udp = UDP.new(@local_address)
      @actor = Actor.new(@local_address, @db) do |message,addr|
        unless(addr == @local_address || message.ttl <= 0)
          log(message, "->", addr)
          @udp.send(message, addr)
        end
      end
    end

    def start
      Thread.new{listen}
    end

    def listen
      loop do
        message, from_address = @udp.receive
        log(message, "<-", from_address)
        @actor.receive(message, from_address)
      end
    end

    def update(key, vector)
      @actor.update(Message.new(key, vector), @local_address)
    end

    def lookup(key)
      @db.lookup(key)
    end

    def bootstrap(remote_address)
      @actor.bootstrap(remote_address)
    end

    def log(message, action, address)
#      puts "#{message} #{action} #{address}"
    end
  end
end
