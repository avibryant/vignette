module Rumour
  class UDPConnection
    def initialize(address, protocol)
      @protocol = protocol
      @socket = UDPSocket.new
      @socket.bind(address.ip, address.port)
    end

    def receive_from
      bytes, addr = @socket.recvfrom(@protocol.max_len)
      envelope = @protocol.from_bytes(bytes)
      from_address = Address.new(addr[3], addr[1])
      [envelope, from_address]
    end

    def send_to(envelope, to_address)
      bytes = @protocol.to_bytes(envelope)
      @socket.send(bytes, 0, to_address.ip, to_address.port)
    end
  end
end