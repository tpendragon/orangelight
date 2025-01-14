# frozen_string_literal: true

# If the user enters a url that has invalid parameters
# this middleware will return a 400 status
# and the load balancer will display its own error page

module Orangelight
  module Middleware
    class InvalidParameterHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        validate_for!(env)
        @app.call(env)
      rescue ActionController::BadRequest => bad_request_error
        raise bad_request_error if raise_error?(bad_request_error.message)

        Rails.logger.error "Invalid parameters passed in the request: #{bad_request_error} within the environment #{@request.inspect}"
        bad_request_response(env)
      end

      private

        def bad_request_body
          'Bad Request'
        end

        def bad_request_headers(env)
          {
            'Content-Type' => "#{request_content_type(env)}; charset=#{default_charset}",
            'Content-Length' => bad_request_body.bytesize.to_s
          }
        end

        def bad_request_response(env)
          [
            bad_request_status,
            bad_request_headers(env),
            [bad_request_body]
          ]
        end

        def bad_request_status
          400
        end

        def default_charset
          ActionDispatch::Response.default_charset
        end

        def default_content_type
          'text/html'
        end

        # Check if facet fields have empty value lists
        def facet_fields_values(params)
          facet_parameter = params.fetch(:f, [])
          raise ActionController::BadRequest, "Invalid facet parameter passed: #{facet_parameter}" unless facet_parameter.is_a?(Array) || facet_parameter.is_a?(Hash)

          facet_parameter.collect do |facet_field, value_list|
            raise ActionController::BadRequest, "Facet field #{facet_field} has a scalar value #{value_list}" if value_list.is_a?(String)

            next unless value_list.nil?
            raise ActionController::BadRequest, "Facet field #{facet_field} has a nil value"
          end
        end

        # Check if params have key with leading or trailing whitespaces
        def check_for_white_spaces(params)
          params.each_key do |k|
            next unless ((k[0].match?(/\s/) || k[-1].match?(/\s/)) && (k.is_a? String)) == true
            raise ActionController::BadRequest, "Param '#{k}' contains a space"
          end
        end

        ##
        # Previously, we were rescuing only from exceptions we recognized.
        # The problem with that is that there will be exceptions we don't recognize and
        # haven't been able to diagnose (see, e.g., https://github.com/pulibrary/orangelight/issues/1455)
        # and when those happen we want to provide the user with a graceful way forward,
        # not just an error screen. Therefore, we should rescue all errors, log the problem,
        # and redirect the user somewhere helpful.
        def raise_error?(_message)
          false
        end

        def request_content_type(env)
          request = request_for(env)
          request.formats.first || default_content_type
        end

        def request_for(env)
          ActionDispatch::Request.new(env.dup)
        end

        def valid_message_patterns
          [
            /invalid %-encoding/,
            /Facet field/,
            /Invalid facet/,
            /contains a space/
          ]
        end

        def validate_for!(env)
          # calling request.params is sufficient to trigger an error
          # see https://github.com/rack/rack/issues/337#issuecomment-46453404
          params = request_for(env).params
          check_for_white_spaces(params)
          facet_fields_values(params)
        end
    end
  end
end
