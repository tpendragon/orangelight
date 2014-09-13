require "rails_helper"

describe "blacklight tests" do

	before(:all) do
		fixture=File.expand_path('../../fixtures/fixtures1.xml',__FILE__)  	
	    system "curl http://localhost:8983/solr/blacklight-core/update?commit=true --data-binary @#{fixture} -H 'Content-type:text/xml; charset=utf-8'"

	end	
	describe "ICU folding keyword search" do

	  it "finds an Arabic entry from a Romanized search term" do
	    get "/catalog.json?&search_field=all_fields&q=dawwani"
	    r = JSON.parse(response.body)
	    expect(r["response"]["docs"].select{|d| d["id"] == "4705304"}.length).to eq 1 
	  end

	end
end