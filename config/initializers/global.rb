# frozen_string_literal: true

Global.configure do |config|
  config.environment = Rails.env.to_s
  config.config_directory = Rails.root.join('config', 'global')
  config.yaml_whitelist_classes = []
end
