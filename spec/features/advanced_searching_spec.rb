# frozen_string_literal: true

require 'rails_helper'

describe 'advanced searching', advanced_search: true do
  before do
    stub_holding_locations
  end

  it 'does not have a basic search bar' do
    visit '/advanced'
    expect(page).not_to have_selector('.search-query-form')
  end

  it 'renders an accessible button for starting over the search' do
    visit '/advanced'
    expect(page).to have_selector '.icon-refresh[aria-hidden="true"]'
  end

  it 'has the expected facets' do
    visit '/advanced'
    expect(page.find_all('.advanced-facet-label').map(&:text)).to match_array(["Access", "Format", "Language", "Holding location", "Publication year"])
  end

  it 'provides labels to form elements' do
    visit '/advanced'
    expect(page).to have_selector('label', exact_text: 'Options for advanced search')
    expect(page).to have_selector('label', exact_text: 'Advanced search terms')
    expect(page).to have_selector('label', exact_text: 'Options for advanced search - second parameter')
    expect(page).to have_selector('label', exact_text: 'Advanced search terms - second parameter')
    expect(page).to have_selector('label', exact_text: 'Options for advanced search - third parameter')
    expect(page).to have_selector('label', exact_text: 'Advanced search terms - third parameter')
    expect(page).to have_selector('label', exact_text: 'Publication date range (starting year)')
    expect(page).to have_selector('label', exact_text: 'Publication date range (ending year)')
  end

  it 'allows searching by format', js: true do
    visit '/advanced'
    expect(page).to have_selector('label', exact_text: 'Format')
    format_input = find_field('format')
    format_input.click
    drop_down = format_input.sibling(".dropdown-menu")
    expect(drop_down).to have_content("Musical score")
    expect(drop_down).to have_content("Senior thesis")
    format_input.fill_in(with: "co")
    expect(drop_down).to have_content("Musical score")
    expect(drop_down).to have_content("Coin")
    expect(drop_down).not_to have_content("Senior thesis")
    page.find('li', text: 'Musical score').click
    click_button("advanced-search-submit")
    expect(page).to have_content("Il secondo libro de madregali a cinque voci / di Giaches de Wert.")
    expect(page).not_to have_content("Огонек : роман")
  end

  it 'allows searching by publication date', js: true do
    visit '/advanced'
    find('#range_pub_date_start_sort_begin').fill_in(with: '1990')
    find('#range_pub_date_start_sort_end').fill_in(with: '1995')
    click_button('advanced-search-submit')
    expect(page).to have_content('Aomen')
  end

  context 'with the old advanced search form' do
    before do
      allow(Flipflop).to receive(:view_components_advanced_search?).and_return(false)
      allow(Flipflop).to receive(:json_query_dsl?).and_return(false)
      visit '/advanced'
    end
    it 'can exclude terms from the search' do
      # defaults to keyword
      fill_in(id: 'q1', with: 'gay')
      choose(id: 'op3_NOT')
      # defaults to title
      fill_in(id: 'q3', with: 'RenoOut')
      click_button('advanced-search-submit')
      expect(page.find(".page_entries").text).to eq('1 entry found')
      expect(page).to have_content('Seeking sanctuary')
      expect(page).to have_content('Title NOT RenoOut')
      expect(page).not_to have_content('Reno Gay Press and Promotions')
    end
  end

  context 'when editing the search', js: true do
    it 'shows the selected value in the combobox' do
      visit '/advanced'
      format_input = find_field('format')
      format_input.click
      page.find('li', text: 'Audio').click
      click_button("advanced-search-submit")
      click_link('Edit search')

      expect(page).to have_field('Format', with: /Audio/)
    end
  end

  context 'with the built-in advanced search form' do
    before do
      allow(Flipflop).to receive(:view_components_advanced_search?).and_return(true)
      allow(Flipflop).to receive(:json_query_dsl?).and_return(true)
      visit '/advanced'
    end

    it 'does not have a basic search bar' do
      visit '/advanced'
      expect(page).not_to have_selector('.search-query-form')
    end

    it 'has the expected facets' do
      visit '/advanced'
      expect(page.find_all('.advanced-facet-label').map(&:text)).to include('Language')
      expect(page.find_all('.advanced-facet-label').map(&:text)).to match_array(["Access", "Format", "Language", "Holding location", "Publication year"])
    end

    it 'renders an accessible button for starting over the search' do
      expect(page).to have_selector '.icon-refresh[aria-hidden="true"]'
    end

    it 'has the correct limit text' do
      expect(page).to have_content('Limit results by')
    end

    it 'has drop-downs for search fields' do
      search_fields = page.find_all('.search-field')
      expect(search_fields.size).to eq(3)
    end

    it 'can run a search' do
      # defaults to keyword
      fill_in(id: 'clause_0_query', with: 'gay')
      click_button('advanced-search-submit')
      expect(page.find(".page_entries").text).to eq('1 - 2 of 2')
      expect(page).to have_content('Seeking sanctuary')
      expect(page).to have_content('RenoOut')
    end

    it 'can exclude terms from the search', js: false do
      # defaults to keyword
      fill_in(id: 'clause_0_query', with: 'gay')
      choose(id: 'clause_2_op_must_not')
      # defaults to title
      fill_in(id: 'clause_2_query', with: 'RenoOut')
      click_button('advanced-search-submit')
      expect(page.find(".page_entries").text).to eq('1 entry found')
      expect(page).to have_content('Seeking sanctuary')
      expect(page).not_to have_content('Reno Gay Press and Promotions')
    end

    it 'shows constraint-value on search results page' do
      # defaults to keyword
      fill_in(id: 'clause_0_query', with: 'gay')
      choose(id: 'clause_2_op_must_not')
      # defaults to title
      fill_in(id: 'clause_2_query', with: 'RenoOut')
      click_button('advanced-search-submit')
      expect(page).to have_content('Title NOT RenoOut')
    end
  end

  context 'with a numismatics advanced search type' do
    it 'provides labels to numismatics form elements' do
      visit '/numismatics'
      expect(page).to have_selector('label', exact_text: 'Object Type')
      expect(page).to have_selector('label', exact_text: 'Denomination')
      expect(page).to have_selector('label', exact_text: 'Metal')
      expect(page).to have_selector('label', exact_text: 'City')
      expect(page).to have_selector('label', exact_text: 'State')
      expect(page).to have_selector('label', exact_text: 'Region')
      expect(page).to have_selector('label', exact_text: 'Ruler')
      expect(page).to have_selector('label', exact_text: 'Artist')
      expect(page).to have_selector('label', exact_text: 'Find Place')
      expect(page).to have_selector('label', exact_text: 'Year')
      expect(page).to have_selector('label', exact_text: 'Keyword')
    end
  end

  context 'when editing the search', js: true do
    it 'shows the selected value in the combobox' do
      visit '/advanced'
      format_input = find_field('format')
      format_input.click
      page.find('li', text: 'Audio').click
      click_button("advanced-search-submit")
      click_link('Edit search')

      expect(page).to have_field('Format', with: /Audio/)
    end
  end
end
