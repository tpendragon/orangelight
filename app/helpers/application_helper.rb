# frozen_string_literal: false

module ApplicationHelper
  require './lib/orangelight/string_functions'

  # Check the Rails Environment. Currently used for Matomo to support production.
  def rails_env?
    Rails.env.production?
  end

  # Generate an Array of <div> elements wrapping links to proxied service endpoints for access
  # Takes first 2 links for pairing with online holdings in search results
  # @param electronic_access [Hash] electronic resource information
  # @return [Array<String>] array containing the links in the <div>'s
  def search_links(electronic_access)
    urls = []
    unless electronic_access.nil?
      links_hash = JSON.parse(electronic_access)
      links_hash.first(2).each do |url, text|
        link = link_to(text.first, EzProxyService.ez_proxy_url(url), target: '_blank', rel: 'noopener')
        link = "#{text[1]}: ".html_safe + link if text[1]
        urls << content_tag(:div, link, class: 'library-location')
      end
    end
    urls
  end

  def show_regular_search?
    !((%w[generate numismatics advanced_search].include? params[:action]) || (%w[advanced].include? params[:controller]))
  end

  # Returns electronic portfolio links for Alma records.
  # @param document [SolrDocument]
  # @return [Array<String>] array containing the links
  def electronic_portfolio_links(document)
    return [] if document.try(:electronic_portfolios).blank?
    document.electronic_portfolios.map do |portfolio|
      content_tag(:div, class: 'library-location') do
        link_to(portfolio["title"], portfolio["url"], target: '_blank', rel: 'noopener')
      end
    end
  end

  # Retrieve a URL for a stack map location URL given a record, a call number, and the library in which it is held
  # @param location [Hash] location information for the item holding
  # @param document [SolrDocument] the Solr Document for the record
  # @param call_number [String] the call number for the holding
  # @param library [String] the library in which the item is held
  # @return [StackmapService::Url] the stack map location
  def locate_url(location, document, call_number, library = nil)
    locator = StackmapLocationFactory.new(resolver_service: ::StackmapService::Url)
    ::StackmapService::Url.new(document:, loc: location, cn: call_number).url unless locator.exclude?(call_number:, library:)
  end

  # Generate the link markup (styled with a glyphicon image) for a given item holding within a library
  # @param location [Hash] location information for the item holding
  # @param document [SolrDocument] the Solr Document for the record
  # @param call_number [String] the call number for the holding
  # @param library [String] the library in which the item is held
  # @return [String] the markup
  def locate_link_with_glyph(location, document, call_number, library, location_name)
    link = locate_url(location, document, call_number, library)
    if link.nil? || (find_it_location?(location) == false)
      ''
    else
      stackmap_span_markup(location, library, location_name)
    end
  end

  def stackmap_span_markup(location, library, location_name)
    ' ' + content_tag(
      :span, '',
      data: {
        'map-location': location.to_s,
        'location-library': library,
        'location-name': location_name
      }
    )
  end

  # Generate the markup for the block containing links for requests to item holdings
  # holding record fields: 'location', 'library', 'location_code', 'call_number', 'call_number_browse',
  # 'shelving_title', 'location_note', 'electronic_access_1display', 'location_has', 'location_has_current',
  # 'indexes', 'supplements'
  # process online and physical holding information at the same time
  # @param [SolrDocument] document - record display fields
  # @return [String] online - online holding info html
  # @return [String] physical - physical holding info html
  def holding_request_block(document)
    adapter = HoldingRequestsAdapter.new(document, Bibdata)
    markup_builder = HoldingRequestsBuilder.new(adapter:,
                                                online_markup_builder: OnlineHoldingsMarkupBuilder,
                                                physical_markup_builder: PhysicalHoldingsMarkupBuilder)
    online_markup, physical_markup = markup_builder.build
    [online_markup, physical_markup]
  end

  # Determine whether or not a ReCAP holding has items restricted to supervised use
  # @param holding [Hash] holding values
  # @return [TrueClass, FalseClass]
  def scsb_supervised_items?(holding)
    if holding.key? 'items'
      restricted_items = holding['items'].select { |item| item['use_statement'] == 'Supervised Use' }
      restricted_items.count == holding['items'].count
    else
      false
    end
  end

  # Blacklight index field helper for the facet "series_display"
  # @param args [Hash]
  def series_results(args)
    series_display =
      if params[:f1] == 'in_series'
        same_series_result(params[:q1], args[:document][args[:field]])
      else
        args[:document][args[:field]]
      end
    series_display.join(', ')
  end

  # Retrieve the same series for that one being displayed
  # @param series [String] series name
  # @param series_display [Array<String>] series being displayed
  # @param [Array<String>] similarly named series
  def same_series_result(series, series_display)
    series_display.select { |t| t.start_with?(series) }
  end

  # Determines whether or not this is an aeon location (for an item holding)
  # @param location [Hash] location values
  # @return [TrueClass, FalseClass]
  def aeon_location?(location)
    location.nil? ? false : location[:aeon_location]
  end

  # Retrieve the location information for a given item holding
  # @param [Hash] holding values
  def holding_location(holding)
    location_code = holding.fetch('location_code', '').to_sym
    resolved_location = Bibdata.holding_locations[location_code]
    resolved_location ? resolved_location : {}
  end

  # Location display in the search results page
  def search_location_display(holding, document)
    location = holding_location_label(holding)
    render_arrow = (location.present? && holding['call_number'].present?)
    arrow = render_arrow ? ' &raquo; ' : ''
    cn_value = holding['call_number_browse'] || holding['call_number']
    locate_link = locate_link_with_glyph(holding['location_code'], document, cn_value, holding['library'], holding['location'])
    location_display = content_tag(:span, location, class: 'results_location') + arrow.html_safe +
                       content_tag(:span, %(#{holding['call_number']}#{locate_link}).html_safe, class: 'call-number')
    location_display.html_safe
  end

  SEPARATOR = '—'.freeze
  QUERYSEP = '—'.freeze
  # rubocop:disable Metrics/AbcSize
  def subjectify(args)
    all_subjects = []
    sub_array = []
    args[:document][args[:field]].each_with_index do |subject, i|
      spl_sub = subject.split(QUERYSEP)
      sub_array << []
      subjectaccum = ''
      spl_sub.each_with_index do |subsubject, j|
        spl_sub[j] = subjectaccum + subsubject
        subjectaccum = spl_sub[j] + QUERYSEP
        sub_array[i] << spl_sub[j]
      end
      all_subjects[i] = subject.split(QUERYSEP)
    end
    subject_list = args[:document][args[:field]].each_with_index do |_subject, i|
      lnk = ''
      lnk_accum = ''
      full_sub = ''
      all_subjects[i].each_with_index do |subsubject, j|
        lnk = lnk_accum + link_to(subsubject,
                                  "/?f[subject_facet][]=#{CGI.escape sub_array[i][j]}", class: 'search-subject', 'data-original-title' => "Search: #{sub_array[i][j]}")
        lnk_accum = lnk + content_tag(:span, SEPARATOR, class: 'subject-level')
        full_sub = sub_array[i][j]
      end
      lnk += '  '
      lnk += link_to('[Browse]', "/browse/subjects?q=#{CGI.escape full_sub}", class: 'browse-subject', 'data-original-title' => "Browse: #{full_sub}", 'aria-label' => "Browse: #{full_sub}", dir: full_sub.dir.to_s)
      args[:document][args[:field]][i] = lnk.html_safe
    end
    content_tag :ul do
      subject_list.each { |subject| concat(content_tag(:li, subject, dir: subject.dir)) }
    end
  end
  # rubocop:enable Metrics/AbcSize

  def title_hierarchy(args)
    titles = JSON.parse(args[:document][args[:field]])
    all_links = []
    dirtags = []

    titles.each do |title|
      title_links = []
      title.each_with_index do |part, index|
        link_accum = StringFunctions.trim_punctuation(title[0..index].join(' '))
        title_links << link_to(part, "/?search_field=left_anchor&q=#{CGI.escape link_accum}", class: 'search-title', 'data-original-title' => "Search: #{link_accum}", title: "Search: #{link_accum}")
      end
      full_title = title.join(' ')
      dirtags << StringFunctions.trim_punctuation(full_title.dir.to_s)
      all_links << title_links.join('<span> </span>').html_safe
    end

    if all_links.length == 1
      all_links = content_tag(:div, all_links[0], dir: dirtags[0])
    else
      all_links = all_links.map.with_index { |l, i| content_tag(:li, l, dir: dirtags[i]) }
      all_links = content_tag(:ul, all_links.join.html_safe)
    end
    all_links
  end

  def action_notes_display(args)
    action_notes = JSON.parse(args[:document][args[:field]])
    lines = []
    action_notes.each do |note|
      lines << if note["uri"].present?
                 link_to(note["description"], note["uri"])
               else
                 note["description"]
               end
    end

    if lines.length == 1
      lines = content_tag(:div, lines[0])
    else
      lines = lines.map.with_index { |l| content_tag(:li, l) }
      lines = content_tag(:ul, lines.join.html_safe)
    end
    lines
  end

  def name_title_hierarchy(args)
    name_titles = JSON.parse(args[:document][args[:field]])
    all_links = []
    dirtags = []
    name_titles.each do |name_t|
      name_title_links = []
      name_t.each_with_index do |part, i|
        link_accum = StringFunctions.trim_punctuation(name_t[0..i].join(' '))
        if i.zero?
          next if args[:field] == 'name_uniform_title_1display'
          name_title_links << link_to(part, "/?f[author_s][]=#{CGI.escape link_accum}", class: 'search-name-title', 'data-original-title' => "Search: #{link_accum}")
        else
          name_title_links << link_to(part, "/?f[name_title_browse_s][]=#{CGI.escape link_accum}", class: 'search-name-title', 'data-original-title' => "Search: #{link_accum}")
        end
      end
      full_name_title = name_t.join(' ')
      dirtags << StringFunctions.trim_punctuation(full_name_title.dir.to_s)
      name_title_links << link_to('[Browse]', "/browse/name_titles?q=#{CGI.escape full_name_title}", class: 'browse-name-title', 'data-original-title' => "Browse: #{full_name_title}", dir: full_name_title.dir.to_s)
      all_links << name_title_links.join('<span> </span>').html_safe
    end

    if all_links.length == 1
      all_links = content_tag(:div, all_links[0], dir: dirtags[0])
    else
      all_links = all_links.map.with_index { |l, i| content_tag(:li, l, dir: dirtags[i]) }
      all_links = content_tag(:ul, all_links.join.html_safe)
    end
    all_links
  end

  def format_icon(args)
    icon = render_icon(args[:document][args[:field]][0]).to_s
    formats = format_render(args)
    content_tag :ul do
      content_tag :li, " #{icon} #{formats} ".html_safe, class: 'blacklight-format', dir: 'ltr'
    end
  end

  def format_render(args)
    args[:document][args[:field]].join(', ')
  end

  def location_has(args)
    location_notes = JSON.parse(args[:document][:holdings_1display]).collect { |_k, v| v['location_has'] }.flatten
    if location_notes.length > 1
      content_tag(:ul) do
        location_notes.map { |note| content_tag(:li, note) }.join.html_safe
      end
    else
      location_notes
    end
  end

  def bibdata_location_code_to_sym(value)
    Bibdata.holding_locations[value.to_sym]
  end

  def render_location_code(value)
    values = normalize_location_code(value).map do |loc|
      location = Bibdata.holding_locations[loc.to_sym]
      location.nil? ? loc : "#{loc}: #{location_full_display(location)}"
    end
    values.count == 1 ? values.first : values
  end

  # Depending on the url, we sometimes get strings, arrays, or hashes
  # Returns Array of locations
  def normalize_location_code(value)
    case value
    when String
      Array(value)
    when Array
      value
    when Hash, ActiveSupport::HashWithIndifferentAccess
      value.values
    else
      value
    end
  end

  def holding_location_label(holding)
    loc_code = holding['location_code']
    location = bibdata_location_code_to_sym(loc_code) unless loc_code.nil?
    # If the Bibdata location is nil, use the location value from the solr document.
    alma_location_display(holding, location) unless location.blank? && holding.blank?
  end

  # Alma location display on search results
  def alma_location_display(holding, location)
    if location.nil?
      [holding['library'], holding['location']].select(&:present?).join(' - ')
    else
      [location['library']['label'], location['label']].select(&:present?).join(' - ')
    end
  end

  # location = Bibdata.holding_locations[value.to_sym]
  def location_full_display(loc)
    loc['label'] == '' ? loc['library']['label'] : loc['library']['label'] + ' - ' + loc['label']
  end

  def html_safe(args)
    args[:document][args[:field]].each_with_index { |v, i| args[:document][args[:field]][i] = v.html_safe }
  end

  def current_year
    DateTime.now.year
  end

  # Construct an adapter for Solr Documents and the bib. data service
  # @return [HoldingRequestsAdapter]
  def holding_requests_adapter
    HoldingRequestsAdapter.new(@document, Bibdata)
  end

  # Returns true for locations with remote storage.
  # Remote storage locations have a value of 'recap_rmt' in Alma.
  def remote_storage?(location_code)
    Bibdata.holding_locations[location_code]["remote_storage"] == 'recap_rmt'
  end

  # Returns true for locations where the user can walk and fetch an item.
  # Currently this logic is duplicated in Javascript code in availability.es6
  def find_it_location?(location_code)
    return false if remote_storage?(location_code)
    return false if (location_code || "").start_with?("plasma$", "marquand$")

    return false if StackmapService::Url.missing_stackmap_reserves.include?(location_code)

    true
  end

  # Testing this feature with Voice Over - reading the Web content
  # If language defaults to english 'en' when no language_iana_primary_s exists then:
  # for cyrilic: for example russian, voice over will read each character as: cyrilic <character1>, cyrilic <character2>
  # for japanese it announces <character> ideograph
  # If there is no lang attribute it announces the same as having lang='en'
  def language_iana
    @document[:language_iana_s].present? ? @document[:language_iana_s].first : 'en'
  end

  def should_show_viewer?
    request.human? && controller.action_name != "librarian_view"
  end
end
