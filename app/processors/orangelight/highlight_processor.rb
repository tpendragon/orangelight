# frozen_string_literal: true

module Orangelight
  class HighlightProcessor < Blacklight::Rendering::AbstractStep
    def render
      em_highlight = values.map { |value| value.gsub('<em>', '<span class="sr-only">Begin search term</span><em class="highlight-query">').gsub('</em>', '<span class="sr-only">End search term</span></em>').html_safe }
      next_step(em_highlight)
    end
  end
end
