module Rumour
  class Cache
    attr_reader :messages

    def initialize
      @messages = {}
    end

    def update(message)
      if(current = @messages[message.key])
        if(message.vector.empty?)
          [nil, current]
        else
          current.merge!(message)
        end
      else
        @messages[message.key] = message
        [message, nil]
      end
    end
  end
end