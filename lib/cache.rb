module Rumour
  class Cache
    def initialize
      @messages = {}
    end

    def update(message)
      if(current = @messages[message.key])
        current.merge!(message)
      else
        @messages[message.key] = message
        [message, nil]
      end
    end
  end
end