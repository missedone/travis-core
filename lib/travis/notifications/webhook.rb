require 'faraday'

module Travis
  module Notifications
    class Webhook
      autoload :Payload, 'travis/notifications/webhook/payload'

      EVENTS = 'build:finished'

      include Logging

      class << self
        def payload_for(build)
          Payload.new(build).to_hash
        end

        def http_client
          @http_client ||= Faraday.new do |f|
            f.request :url_encoded
            f.adapter :net_http
          end
        end

        def http_client=(http_client)
          @http_client = http_client
        end
      end

      def notify(event, build, *args)
        send_webhook_notifications(build.webhooks, build) if build.send_webhook_notifications?
      end
      instrument :notify

      protected

        def send_webhook_notifications(targets, build)
          targets.each do |webhook|
            self.class.http_client.post(webhook) do |req|
              req.body = { :payload => self.class.payload_for(build).to_json }
              req.headers['Authorization'] = authorization(build)
            end
          end
        end

        def authorization(build)
          Digest::SHA2.hexdigest(build.repository.slug + build.request.token)
        end
    end
  end
end
