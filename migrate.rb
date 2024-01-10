#!/usr/bin/env ruby
require 'dotenv'
Dotenv.load("#{__dir__}/.env")

OPENAI_KEY=ENV['OPENAI_KEY']

REPLACE = ENV['REPLACE'] == 'true'

if OPENAI_KEY.nil? || OPENAI_KEY.empty?
  $stdout.puts "Error no OPENAI_KEY env variable defined"
  exit 1
end

require "openai"

CLIENT = OpenAI::Client.new(access_token: OPENAI_KEY)

MODEL = "gpt-4-1106-preview"
# MODEL = "gpt-3.5-turbo-16k"

def prompt(text, history=[], system: "I am a helpful assistant.")
  puts "Prompting.."
  messages = [
    { role: "system", content: system }
  ] + history + [
    { role: "user", content: text}
  ]

  result = CLIENT.chat(
    parameters: {
      model: MODEL,
      messages:,
      temperature: 0.0
    })
  # puts "Got response: #{result.inspect}"
  content = result.dig("choices", 0, "message", "content")
  raise "No content: #{result.inspect}" if content.nil?
  content
rescue => e
  $stderr.puts "Error: #{e.message}\n#{result.inspect}\n\n#{e.backtrace.join("\n")}"
  exit 1
end

def split_vue_file(original)
  original_style = original.match(/^(<style.*?>(.*?)^<\/style>)/m)&.[](1)
  original_template = original.match(/^(<template.*?>(.*?)^<\/template>)/m)[1]
  original_script = original.match(/^(<script.*?>(.*?)^<\/script>)/m)[1]
  [original_style, original_template, original_script]
end

path = ARGV[0]

contents = File.read(path)

# require './vue_3'
# result = migrate_to_vue3(contents)

require "#{__dir__}/i18n.rb"
result = apply_i18n(path, contents)

if REPLACE
  File.write(path, result)
else
  puts result
end

