# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchBuilder do
  subject(:search_builder) { described_class.new([]) }

  describe '#excessive_paging' do
    let(:excessive) { 9999 }
    let(:reasonable) { 123 }

    it 'allows reasonable paging with a search query' do
      search_builder.blacklight_params[:page] = reasonable
      search_builder.blacklight_params[:q] = 'anything'
      expect(search_builder.excessive_paging?).to be false
    end

    it 'allows reasonable paging with a facet query' do
      search_builder.blacklight_params[:page] = reasonable
      search_builder.blacklight_params[:f] = 'anything'
      expect(search_builder.excessive_paging?).to be false
    end

    it 'does not allow paging without a search or facet' do
      search_builder.blacklight_params[:page] = reasonable
      expect(search_builder.excessive_paging?).to be true
    end

    it 'does not allow excessive paging with a search query' do
      search_builder.blacklight_params[:page] = excessive
      search_builder.blacklight_params[:q] = 'anything'
      expect(search_builder.excessive_paging?).to be true
    end

    it 'does not allow excessive paging with a facet query' do
      search_builder.blacklight_params[:page] = excessive
      search_builder.blacklight_params[:f] = 'anything'
      expect(search_builder.excessive_paging?).to be true
    end

    it 'allows paging for advanced search' do
      search_builder.blacklight_params[:page] = reasonable
      search_builder.blacklight_params[:search_field] = 'advanced'
      expect(search_builder.excessive_paging?).to be false
    end
  end
end
