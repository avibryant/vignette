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
    #return a new message with just the differences
    def merge!(other)
      news_to_me = {}
      my_news = {}
      other.vector.each do |i,v|
        v2 = vector[i] || 0
        if(v > v2)
          vector[i] = v
          news_to_me[i] = v
        elsif(v < v2)
          my_news[i] = v2
        end
      end

      unless news_to_me.empty?
        forward = Message.new(key, news_to_me)
      end

      unless my_news.empty?
        backward = Message.new(key, my_news)
      end

      [forward, backward]
    end

    def to_s
      "#{key}=#{vector.inspect}"
    end
  end
end