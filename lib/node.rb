module Rumour
  class Node
    def initialize(&send)
      @cache = Cache.new
      @neighbours = {}
      @send = send
    end

    def receive(envelope, from_address)
      @neighbours[from_address] = Time.now
      forward_msg, backward_msg = @cache.update(envelope.message)

      if forward_msg
        candidates = @neighbours.keys - [from_address, envelope.source]
        neighbour = candidates.shuffle[0]
        if neighbour
          forward = Envelope.new(
            envelope.source,
            envelope.ttl - 1,
            forward_msg)
          @send.call(forward, neighbour)
        end
      end

      if backward_msg
        backward = Envelope.new(
          envelope.source,
          envelope.ttl,
          backward_msg)
        @send.call(backward, from_address)
        if from_address != envelope.source
          @send.call(backward, envelope.source)
        end
      end
    end
  end
end