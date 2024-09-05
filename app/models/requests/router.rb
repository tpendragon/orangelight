# frozen_string_literal: true
module Requests
  class Router
    attr_accessor :requestable
    attr_reader :user, :any_loanable

    delegate :cas_provider?, :alma_provider?, to: :user

    def initialize(requestable:, user:, any_loanable: false)
      @requestable = requestable
      @user = user
      @any_loanable = any_loanable
    end

    # Possible Services
    # :online
    # :annex
    # :on_shelf
    # :on_order
    # :in_process
    # :annex
    # :recap
    # :recap_edd
    # :ill
    # :paging
    # :trace

    # user levels
    # guest - Access patron - shouldn't show recap_edd
    # barcode - no ill, no bd
    # cas - all services

    def routed_request
      requestable.replace_existing_services calculate_services
      requestable
    end

    # top level call, returns a hash of symbols with service objects as values
    # services[:service_name] = Requests::Service::GenericService
    def calculate_services
      if (requestable.alma_managed? || requestable.partner_holding?) && requestable.online?
        ['online']
      elsif (requestable.alma_managed? || requestable.partner_holding?) && !requestable.aeon?
        calculate_alma_or_scsb_services
      else # Default Service is Aeon
        ['aeon']
      end
    end

    private

      # rubocop:disable Metrics/MethodLength
      def calculate_alma_or_scsb_services
        return [] unless auth_user?
        if requestable.charged?
          calculate_unavailable_services
        elsif requestable.in_process?
          ['in_process']
        elsif requestable.on_order?
          ['on_order']
        elsif requestable.annex?
          ['annex', 'on_shelf_edd']
        elsif requestable.recap? || requestable.recap_pf?
          calculate_recap_services
        elsif requestable.held_at_marquand_library?
          calculate_marquand_services
        else
          calculate_on_shelf_services
          # goes to stack mapping
          # suppressing Trace service for the moment, but leaving this code
          # see https://github.com/pulibrary/requests/issues/164 for info
          # if (requestable.open? && auth_user?)
          #   services << 'trace' # all open stacks items are traceable
          # end
        end
      end
      # rubocop:enable Metrics/MethodLength

      def calculate_on_shelf_services
        [
          ServiceEligibility::OnShelfEdd.new(requestable:, user:),
          ServiceEligibility::OnShelf.new(requestable:, user:)
        ].select(&:eligible?).map(&:to_s)
      end

      def calculate_recap_services
        if !requestable.item_data?
          ['recap_no_items']
        elsif (requestable.scsb_in_library_use? && requestable.item[:collection_code] != "MR") || (!requestable.circulates? && !requestable.recap_edd?) || requestable.recap_pf?
          ['recap_in_library']
        elsif requestable.scsb_in_library_use? && !requestable.eligible_for_library_services?
          ['ask_me']
        elsif auth_user?
          services = []
          services << 'recap' if !requestable.holding_library_in_library_only? && requestable.circulates? && requestable.eligible_for_library_services?
          services << 'recap_edd' if requestable.recap_edd?
          services
        end
      end

      def calculate_unavailable_services
        ill_eligibility = ServiceEligibility::ILL.new(requestable:, user:, any_loanable:)
        if ill_eligibility.eligible?
          [ill_eligibility.to_s]
        else
          []
        end
      end

      def calculate_marquand_services
        if requestable.item_at_clancy? && !requestable.clancy?
          ['clancy_unavailable']
        elsif requestable.clancy?
          ['clancy_in_library', 'clancy_edd']
        else
          ['marquand_in_library', 'marquand_edd']
        end
      end

      def any_loanable?
        @any_loanable
      end

      def access_user?
        if @user.guest == true
          true
        else
          false
        end
      end

      def auth_user?
        cas_provider? || alma_provider?
      end
  end
end
