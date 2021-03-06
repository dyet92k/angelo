module Angelo
  class Responder
    class Eventsource < Responder

      def initialize _headers = nil, &block
        headers _headers if _headers
        super :get, &block
      end

      def request= request
        @params = nil
        @request = request
      end

      def handle_request
        if !@response_handler
            raise NotImplementedError
        end
        @base.filter :before
        @body = catch(:halt) do
          @base.eventsource do |socket|
            @base.instance_exec(socket, &@response_handler)
          end
        end
        if HALT_STRUCT === @body
          raise RequestError.new 'unknown sse error' unless @body.body == :sse
        end

        # TODO any real reason not to run afters with SSE?
        # @base.filter :after

        respond
      rescue IOError => ioe
        warn "#{ioe.class} - #{ioe.message}"
      rescue RequestError => re
        headers SSE_HEADER
        handle_error re, re.type
      rescue => e
        handle_error e
      end

      def respond
        Angelo.log :sse, @connection, @request, nil, :ok
        @request.respond 200, headers, nil
      end

    end
  end
end
