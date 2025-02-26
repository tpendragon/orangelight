# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_examples "a simple search" do
  it 'uses a wildcard for left anchored search' do
    visit '/catalog'
    select('Title starts with', from: 'search_field')
    fill_in('Search...', with: 'The')
    click_on('Search')
    expect(page).to have_content('The senses : a comprehensive reference')
  end
  it 'does not do boolean searching' do
    visit '/catalog'
    select('Title starts with', from: 'search_field')
    fill_in('Search...', with: 'The OR Black')
    click_on('Search')
    expect(page).to have_content('No results found for your search')
  end
end

RSpec.shared_examples "an advanced search" do
  it 'uses a wildcard for left anchored search' do
    visit '/advanced'
    select('Title starts with', from: 'Options for advanced search')
    fill_in('Advanced search terms', with: 'The')
    click_on('Search')
    expect(page).to have_content('The senses : a comprehensive reference')
  end
  it 'uses a wildcard for left anchored search from the second search box' do
    visit '/advanced'
    fill_in('Advanced search terms', with: 'senses')
    page.find('.first-or').choose
    select('Title starts with', from: 'Options for advanced search - second parameter')
    fill_in('Advanced search terms - second parameter', with: 'The')
    click_on('Search')
    expect(page).to have_content('The senses : a comprehensive reference')
  end
  it 'does not do boolean searching', js: true do
    visit '/advanced'
    select('Title starts with', from: 'Options for advanced search')
    fill_in('Advanced search terms', with: 'The')
    page.find('.first-or').choose
    select('Title starts with', from: 'Options for advanced search - second parameter')
    fill_in('Advanced search terms - second parameter', with: 'Black')
    click_on('Search')
    expect(page).to have_content(/Title starts with.{1,2}The/)
    expect(page).to have_content(/Title starts with.{1,4}Black/)
  end
end

RSpec.describe 'left anchored searching', type: :system, left_anchor: true do
  before { stub_holding_locations }
  context 'old query dsl and advanced search' do
    before do
      allow(Flipflop).to receive(:view_components_advanced_search?).and_return(false)
      allow(Flipflop).to receive(:json_query_dsl?).and_return(false)
    end

    it_behaves_like 'a simple search'
    it_behaves_like 'an advanced search'
  end
  context 'new query dsl and advanced search' do
    before do
      allow(Flipflop).to receive(:view_components_advanced_search?).and_return(true)
      allow(Flipflop).to receive(:json_query_dsl?).and_return(true)
    end

    it_behaves_like 'a simple search'
    it_behaves_like 'an advanced search'
  end
end
