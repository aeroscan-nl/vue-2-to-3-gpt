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

MODEL = "gpt-4"

SYSTEM = <<~SYSTEM_PROMPT
  You are an experienced Vue.js programmer who is migrating Vue component files from Vue 2 to Vue 3 one at a time.
  You respond with the given code migrated to the Vue 3.0 compositional style. You are concise in your answer, giving
  no further commentary and you migrate all the given code. The migrated code should have the exact same behavior as
  the original code.

  Example input:

  ```
  #{File.read("#{__dir__}/example-vue-2.vue")}
  ```

  Example output:
  ```
  #{File.read("#{__dir__}/example-vue-3.vue")}
  ```
SYSTEM_PROMPT

def prompt(text, history=[])
  puts "Prompting.."
  messages = [
    { role: "system", content: SYSTEM }
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
  result.dig("choices", 0, "message", "content")
rescue => e
  $stderr.puts "Error: #{e.message}\n#{result.inspect}\n\n#{e.backtrace.join("\n")}"
  exit 1
end

path = ARGV[0]
original = File.read(path)

# extract the <style>, <template> and <script> elements from the original vue file

original_style = original.match(/^<style.*?>(.*?)^<\/style>/m)&.[](1)
original_template = original.match(/^<template.*?>(.*?)^<\/template>/m)[1]
original_script = original.match(/^<script.*?>(.*?)^<\/script>/m)[1]

# first we prompt just the script
result_script = prompt(original_script)

puts "Result script:\n\n#{result_script}"

history = [
  { role: "assistant", content: result_script }
]

result_template = prompt("Thank you for migrating the script, please also migrate the accompanying template: \n\n#{original_template}", history)

puts "Result template:\n\n#{result_template}"

result = "// template\n #{result_template}\n\n// style\n#{original_style}\n\n// script\n#{result_script}"

if REPLACE
  File.write(path, result)
else
  puts result
end

