require 'dotenv/load'

OPENAI_KEY=ENV['OPENAI_KEY']

if OPENAI_KEY.nil? || OPENAI_KEY.empty?
  $stdout.puts "Error no OPENAI_KEY env variable defined"
  exit 1
end

require "openai"

CLIENT = OpenAI::Client.new(access_token: OPENAI_KEY)

MODEL = "gpt-3.5-turbo-16k"

SYSTEM = <<~SYSTEM_PROMPT
  You are an experienced Vue.js programmer who is migrating Vue component files from Vue 2 to Vue 3 one at a time.
  You respond with the given code migrated to the Vue 3.0 compositional style.

  Example input:

  ```
  #{File.read("example-vue-2.vue")}
  ```

  Example output:
  ```
  #{File.read("example-vue-3.vue")}
  ```
SYSTEM_PROMPT

def prompt(text)
  result = CLIENT.chat(
    parameters: {
      model: MODEL,
      messages: [
        { role: "system", content: SYSTEM },
        { role: "user", content: text}],
      temperature: 0.7
    })
  result.dig("choices", 0, "message", "content")
rescue => e
  $stderr.puts "Error: #{e.message}\n#{result.inspect}\n\n#{e.backtrace.join("\n")}"
end

puts prompt(File.read(ARGV[0]))
