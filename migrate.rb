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

# MODEL = "gpt-4"
MODEL = "gpt-4o"
# MODEL = "gpt-3.5-turbo-16k"

def prompt(text, history=[], system: "I am a helpful assistant.")
  puts "Prompting.."
  messages = [
    { role: "system", content: system }
  ] + history + [
    { role: "user", content: text}
  ]

  content = ""

  result = CLIENT.chat(
    parameters: {
      model: MODEL,
      messages:,
      temperature: 0.0,
      stream: proc do |chunk, _bytesize|
        chunk_content = chunk.dig("choices", 0, "delta", "content")
        print chunk_content
        content << chunk_content if chunk_content
      end
    })
  # puts "Got response: #{result.inspect}"
  # content = result #.dig("choices", 0, "message", "content")
  raise "No content: #{result.inspect}" if content.empty?
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

require_relative './vue_3'
result = migrate_to_vue3(contents)

# require_relative "./i18n"
# result = apply_i18n(path, contents)

if REPLACE
  File.write(path, result)
else
  puts result
end

