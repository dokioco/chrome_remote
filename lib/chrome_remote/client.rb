require "chrome_remote/web_socket_client"

module ChromeRemote
  class Client
    attr_reader :ws, :options, :handlers, :target_id

    def initialize(options)
      @options = options
      @ws = WebSocketClient.new(get_ws_url)
      @handlers = Hash.new { |hash, key| hash[key] = [] }
    end

    def destroy
      Net::HTTP.get(@options[:host], "/json/close/#{@target_id}", @options[:port])
    end

    def send_cmd(command, params = {})
      msg_id = generate_unique_id

      ws.send_msg({method: command, params: params, id: msg_id}.to_json)

      msg = read_until { |msg| msg["id"] == msg_id }
      msg["result"]
    end

    def on(event_name, &block)
      handlers[event_name] << block
    end

    def listen_until(&block)
      read_until { block.call }
    end

    def listen
      read_until { false }
    end

    def wait_for(event_name=nil)
      if event_name
        msg = read_until { |msg| msg["method"] == event_name }
      elsif block_given?
        msg = read_until { |msg| yield(msg["method"], msg["params"]) }
      end
      msg["params"]
    end

    private

    def get_ws_url
      response = Net::HTTP.get(@options[:host], "/json/new?", @options[:port])
      # TODO handle unsuccesful request

      response = JSON.parse(response)
      @target_id = response["id"]

      # TODO handle no entry found
      response["webSocketDebuggerUrl"]
    end

    def generate_unique_id
      @last_id ||= 0
      @last_id += 1
    end

    def read_msg
      msg = JSON.parse(ws.read_msg)

      # Check if it’s an event and invoke any handlers
      if event_name = msg["method"]
        handlers[event_name].each do |handler|
          handler.call(msg["params"])
        end
      end

      msg
    end

    def read_until(&block)
      loop do
        msg = read_msg
        return msg if block.call(msg)
      end
    end
  end
end
