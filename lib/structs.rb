module Rumour
  Address = Struct.new(:ip, :port)
  Envelope = Struct.new(:source, :ttl, :message)
  Message = Struct.new(:key, :vector)

  class Address
    def to_s
      "#{ip}:#{port}"
    end
  end

  class Envelope
    def to_s
      "<#{source} #{message} #{ttl}>"
    end
  end

  class Message
    #update this message to incorporate other as needed
    #return a new message with just the modifications
    def merge!(other)
      updates = {}
      other.vector.each do |i,v|
        if(v > (vector[i] || 0))
          vector[i] = v
          updates[i] = v
        end
      end

      unless updates.empty?
        Message.new(key, updates)
      end
    end

    def to_s
      "#{key}=#{vector.inspect}"
    end
  end
end