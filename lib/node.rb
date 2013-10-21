module Rumour
  class Node
    SERVERS = "_servers"

    def initialize(local_address, &send)
      @cache = Cache.new
      @send = send
      @local_address = local_address
    end

    def neighbours
      if msg = @cache.messages[SERVERS]
        msg.vector.keys
      else
        []
      end
    end

    def bootstrap(address)
      @send.call(Envelope.new(@local_address, 2, Message.new(SERVERS, {})), address)
    end

    def receive(envelope, from_address)
      unless from_address == @local_address
        update(
            Envelope.new(from_address, envelope.ttl,
              Message.new(SERVERS, from_address => Time.now.to_i)),
            from_address)
      end
      update(envelope, from_address)
    end

    def update(envelope, from_address)
      forward_msg, backward_msg = @cache.update(envelope.message)

      if forward_msg
        candidates = neighbours - [from_address, @local_address]
        neighbour = candidates.shuffle[0]
        if neighbour
          @send.call(Envelope.new(
            from_address,
            envelope.ttl - 1,
            forward_msg), neighbour)
        end
      end

      if backward_msg
        backward = Envelope.new(
          @local_address,
          envelope.ttl - 1,
          backward_msg)
        @send.call(backward, from_address)
      end
    end
  end
end