# frozen_string_literal: true

require 'rails_helper'

describe 'submitting biased results', js: true do
  before do
    visit '/feedback/biased_results?report_biased_results_form[q]=cats'
  end

  it 'submits the message' do
    fill_in(id: 'name', with: 'John Smith')
    fill_in(id: 'email', with: 'jsmith@localhost.localdomain')
    fill_in(id: 'message', with: 'Lorem ipsum dolor sit amet, consectetur...')
    click_on('Send')
  end

  # it 'renders an accessible icon for returning' do
  #   expect(page).to have_selector '.icon-moveback[aria-hidden="true"]'
  # end
  it 'shows the search query' do
    expect(page).to have_content('It looks like you were searching for the term(s) cats')
    expect(page).to have_link('search results', href: "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/catalog?q=cats")
  end
end
