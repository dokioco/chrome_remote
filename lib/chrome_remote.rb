require "chrome_remote/version"
require "chrome_remote/client"
require "json"
require "net/http"

module ChromeRemote
  class << self
    DEFAULT_OPTIONS = {
      host: "localhost",
      port: 9222
    }

    def client(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      Client.new(options)
    end

  end
end
