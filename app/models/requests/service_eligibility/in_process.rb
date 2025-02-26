# frozen_string_literal: true
module Requests
  module ServiceEligibility
    class InProcess
      def initialize(requestable:, user:)
        @requestable = requestable
        @user = user
      end

      def to_s
        'in_process'
      end

      def eligible?
        requestable_eligible? && user_eligible?
      end

    private

      def user_eligible?
        user.cas_provider? || user.alma_provider?
      end

      def requestable_eligible?
        !requestable.aeon? && !requestable.charged? && requestable.in_process?
      end
      attr_reader :requestable, :user
    end
  end
end
