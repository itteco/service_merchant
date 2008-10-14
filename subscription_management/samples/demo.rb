#!/usr/bin/ruby
#
# Demo of configuration file reading and parsing
require 'yaml'

PRESET_FILE = 'presets.yml'
# Reads settings from specified file with applied presets.yml
def read_settings(filename)
  raw_config = [File.read(PRESET_FILE), File.read(filename)].join("\n")
  YAML.load(raw_config)
end

Dir["*.yml"].each do |file|
  puts "file: #{file}\n============\n"
  settings = read_settings(file)
  settings.delete('defaults') unless file == 'presets.yml'
  puts settings.inspect
  puts "\n\n"
end
