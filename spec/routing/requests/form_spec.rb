# frozen_string_literal: true
require 'rails_helper'

describe Requests::FormController, type: :routing do
  describe 'routing' do
    it 'routes to request #index' do
      expect(get: '/requests').to route_to('requests/form#index')
    end

    it 'generates a request form via #generate' do
      expect(get: '/requests/1235').to route_to('requests/form#generate', system_id: '1235')
    end

    it 'generates a request form for a specific mfhd via #generate' do
      expect(get: '/requests/1235?mfhd=1234').to route_to('requests/form#generate', system_id: '1235', mfhd: '1234')
    end

    it 'submits via post to #submit' do
      expect(post: '/requests/submit').to route_to('requests/form#submit')
    end
  end
end
