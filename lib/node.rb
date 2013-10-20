module Rumour
  class Node
    def initialize
      @cache = Cache.new
      @neighbours = {}
    end

    #takes an Envelope and the Address of the immediate sender
    #yields pairs of Envelope, Address that should be sent
    def receive(envelope, from_address)
      update_neighbours(from_address)
      to_forward = update_cache(envelope)
      if(to_forward)
        pick_recipients(from_address, envelope.source).each do |forward_to|
          yield(to_forward, forward_to)
        end
      end
    end

    private

    def update_neighbours(address)
      @neighbours[address] = Time.now
    end

    def update_cache(envelope)
      updated_message = @cache.update(envelope.message)
      if updated_message
        Envelope.new(
          envelope.source,
          envelope.ttl - 1,
          updated_message)
      end
    end

    def pick_recipients(from_address, source_address)
      recipients = [from_address, source_address]
      neighbour_candidates = @neighbours.keys - recipients
      recipients << pick_neighbour(neighbour_candidates)
      recipients.compact.uniq
    end

    def pick_neighbour(candidates)
      candidates.shuffle[0]
    end
  end
end