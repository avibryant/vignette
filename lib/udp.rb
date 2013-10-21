module Vignette
  class UDP
    MAXLEN = 1500

    def initialize(address)
      @socket = UDPSocket.new
      ip, port = split_address(address)
      @socket.bind(ip, port)
    end

    def receive
      bytes, addr = @socket.recvfrom(MAXLEN)
      from_address = "#{addr[3]}:#{addr[1]}"
      [Message.from_bytes(bytes), from_address]
    end

    def send(message, address)
      ip, port = split_address(address)
      @socket.send(message.to_bytes, 0, ip, port)
    end

    def split_address(address)
      ip, port = address.split(":")
      [ip, port.to_i]
    end
  end
end