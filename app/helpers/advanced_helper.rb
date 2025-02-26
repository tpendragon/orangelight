# frozen_string_literal: true

# Helper methods for the advanced search form
module AdvancedHelper
  include BlacklightAdvancedSearch::AdvancedHelperBehavior

  # Fill in default from existing search, if present
  # -- if you are using same search fields for basic
  # search and advanced, will even fill in properly if existing
  # search used basic search on same field present in advanced.
  def label_tag_default_for(key)
    if params[key].present?
      params[key]
    elsif params['search_field'] == key || guided_context(key)
      params['q']
    else
      param_for_field key
    end
  end

  def advanced_key_value
    key_value = []
    advanced_search_fields.each do |field|
      key_value << [field[1][:label], field[0]]
    end
    key_value
  end

  # carries over original search field and original guided search fields if user switches to guided search from regular search
  def guided_field(field_num, default_val)
    return advanced_search_fields[params[:search_field]].key || default_val if first_search_field_selector?(field_num) && no_advanced_search_fields_specified? && params[:search_field] && advanced_search_fields[params[:search_field]]
    params[field_num] || param_for_field(field_num) || default_val
  end

  # carries over original search query if user switches to guided search from regular search
  def guided_context(key)
    first_search_field?(key) &&
      params[:f1].nil? && params[:f2].nil? && params[:f3].nil? &&
      params[:search_field] && advanced_search_fields[params[:search_field]]
  end

  # carries over guided search operations if user switches back to guided search from regular search
  def guided_radio(op_num, op)
    if params[op_num]
      params[op_num] == op
    else
      op == 'AND'
    end
  end

  def generate_solr_fq
    filters.map do |solr_field, value_list|
      value_list = value_list.values if value_list.is_a?(Hash)

      "#{solr_field}:(" +
        Array(value_list).collect { |v| '"' + v.gsub('"', '\"') + '"' }.join(' OR  ') +
        ')'
    end
  end

  private

    def advanced_search_fields
      blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end

    def first_search_field_selector?(key)
      [:f1, :clause_0_field].include? key
    end

    def no_advanced_search_fields_specified?
      [:f1, :f2, :f3, :clause_0_field, :clause_1_field, :clause_2_field].none? do |key|
        params[key].present?
      end
    end

    def param_for_field(field_identifier)
      if field_identifier.to_s.start_with? 'clause'
        components = field_identifier.to_s.split('_')
        params.dig(*components)
      end
    end

    def first_search_field?(key)
      [:q1, :clause_0_query].include? key
    end
end

module BlacklightAdvancedSearch
  class QueryParser
    include AdvancedHelper
    def keyword_op
      # for guided search add the operations if there are queries to join
      # NOTs get added to the query. Only AND/OR are operations
      @keyword_op = []
      unless @params[:q1].blank? || @params[:q2].blank? || @params[:op2] == 'NOT'
        @keyword_op << @params[:op2] if @params[:f1] != @params[:f2]
      end
      unless @params[:q3].blank? || @params[:op3] == 'NOT' || (@params[:q1].blank? && @params[:q2].blank?)
        @keyword_op << @params[:op3] unless [@params[:f1], @params[:f2]].include?(@params[:f3]) && ((@params[:f1] == @params[:f3] && @params[:q1].present?) || (@params[:f2] == @params[:f3] && @params[:q2].present?))
      end
      @keyword_op
    end

    def keyword_queries
      unless @keyword_queries
        @keyword_queries = {}

        return @keyword_queries unless @params[:search_field] == ::AdvancedController.blacklight_config.advanced_search[:url_key]

        # Spaces need to be stripped from the query because they don't get properly stripped in Solr
        q1 = %w[left_anchor in_series].include?(@params[:f1]) ? prep_left_anchor_search(@params[:q1]) : odd_quotes(@params[:q1])
        q2 = @params[:f2] == 'left_anchor' ? prep_left_anchor_search(@params[:q2]) : odd_quotes(@params[:q2])
        q3 = @params[:f3] == 'left_anchor' ? prep_left_anchor_search(@params[:q3]) : odd_quotes(@params[:q3])

        @been_combined = false
        @keyword_queries[@params[:f1]] = q1 if @params[:q1].present?
        @keyword_queries[@params[:f2]] = prepare_q2(q2) if @params[:q2].present?
        @keyword_queries[@params[:f3]] = prepare_q3(q3) if @params[:q3].present?
      end
      @keyword_queries
    end

    private

      # Remove stray quotation mark if there are an odd number of them
      # @param query [String] the query
      # @return [String] the query with an even number of quotation marks
      def odd_quotes(query)
        if query&.count('"')&.odd?
          query.sub(/"/, '')
        else
          query
        end
      end

      # Escape spaces for left-anchor search fields and adds asterisk if not present
      # Removes quotation marks
      # @param query [String] the query within which whitespace is being escaped
      # @return [String] the escaped query
      def prep_left_anchor_search(query)
        if query
          cleaned_query = query.gsub(/(\s)/, '\\\\\\\\\1')
          cleaned_query = cleaned_query.delete('"')
          cleaned_query = cleaned_query.gsub(/(["\{\}\[\]\^\~\(\)])/, '\\\\\\\\\1')
          if cleaned_query.end_with?('*')
            cleaned_query
          else
            cleaned_query + '*'
          end
        end
      end

      def prepare_q2(q2)
        if @keyword_queries.key?(@params[:f2])
          @been_combined = true
          "(#{@keyword_queries[@params[:f2]]}) " + @params[:op2] + " (#{q2})"
        elsif @params[:op2] == 'NOT'
          'NOT ' + q2
        else
          q2
        end
      end

      def prepare_q3(q3)
        if @keyword_queries.key?(@params[:f3])
          kq3 = @keyword_queries[@params[:f3]]
          kq3 = "(#{kq3})" unless @been_combined
          "#{kq3} " + @params[:op3] + " (#{q3})"
        elsif @params[:op3] == 'NOT'
          'NOT ' + q3
        else
          q3
        end
      end
  end
end

module BlacklightAdvancedSearch
  module ParsingNestingParser
    # Iterates through the keyword queries and appends each operator the extracting queries
    # @param [ActiveSupport::HashWithIndifferentAccess] _params
    # @param [Blacklight::Configuration] config
    # @return [Array<String>]
    def process_query(_params, config)
      if config.advanced_search.nil?
        Blacklight.logger.error "Failed to parse the advanced search, config. settings are not accessible for: #{config}"
        return []
      end

      queries = []
      ops = keyword_op
      keyword_queries.each do |field, query|
        query_parser_config = config.advanced_search[:query_parser]
        begin
          parsed = ParsingNesting::Tree.parse(query, query_parser_config)
        rescue Parslet::ParseFailed => parse_failure
          Blacklight.logger.warn "Failed to parse the query: #{query}: #{parse_failure}"
          next
        end

        # Test if the field is valid
        next unless config.search_fields[field]
        local_param = local_param_hash(field, config)
        queries << parsed.to_query(local_param)
        queries << ops.shift
      end
      queries.join(' ')
    end
  end
end
