module Rumour
  class UDPConnection
    def initialize(address, protocol)
      @protocol = protocol
      @socket = UDPSocket.new
      ip, port = split_address(address)
      @socket.bind(ip, port)
    end

    def receive_from
      bytes, addr = @socket.recvfrom(@protocol.max_len)
      message = @protocol.from_bytes(bytes)
      from_address = "#{addr[3]}:#{addr[1]}"
      [message, from_address]
    end

    def send_to(message, address)
      bytes = @protocol.to_bytes(message)
      ip, port = split_address(address)
      @socket.send(bytes, 0, ip, port)
    end

    def split_address(address)
      ip, port = address.split(":")
      [ip, port.to_i]
    end
  end
end