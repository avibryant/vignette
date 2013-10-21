module Rumour
  class Actor
    def initialize(address, &send)
      @cache = Cache.new
      @send = send
      @address = address
    end

    def neighbours
      @cache.keys.map{|ea| $1 if ea =~ /^n:(.*)/}.compact
    end

    def bootstrap(neighbour)
      @send.call(Message.new("n:%", {}, 2), neighbour)
    end

    def receive(message, from_address)
      synthetic = Message.new("n:#{from_address}", {0 => Time.now.to_i}, 2)
      update(synthetic, from_address)
      update(message, from_address)
    end

    def update(message, from_address)
      query_results = @cache.query(message.key, message.vector)
      query_results.each do |k,v|
        @send.call(Message.new(k, v, message.ttl - 1), from_address)
      end

      updates = @cache.update(message.key, message.vector)
      unless updates.empty?
        if neighbour = pick_neighbour(from_address)
          @send.call(Message.new(message.key, updates, message.ttl - 1), neighbour)
        end
      end
    end

    def pick_neighbour(exclude)
      candidates = neighbours - [exclude, @address]
      candidates.shuffle[0]
    end
  end
end