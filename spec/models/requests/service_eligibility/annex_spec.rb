# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Requests::ServiceEligibility::Annex, requests: true do
  describe '#eligible?' do
    it 'returns true if the item is in the annex' do
      requestable = instance_double(Requests::Requestable)
      allow(requestable).to receive_messages(
          aeon?: false,
          charged?: false,
          in_process?: false,
          on_order?: false,
          annex?: true,
          recap?: false,
          recap_pf?: false,
          held_at_marquand_library?: false
        )
      eligibility = described_class.new(requestable:, user: FactoryBot.create(:user))

      expect(eligibility.eligible?).to be(true)
    end
    it 'returns false if the item is not in the annex' do
      requestable = instance_double(Requests::Requestable)
      allow(requestable).to receive_messages(
          aeon?: false,
          charged?: false,
          in_process?: false,
          on_order?: false,
          annex?: false,
          recap?: false,
          recap_pf?: false,
          held_at_marquand_library?: false
        )
      eligibility = described_class.new(requestable:, user: FactoryBot.create(:user))

      expect(eligibility.eligible?).to be(false)
    end
  end
end
