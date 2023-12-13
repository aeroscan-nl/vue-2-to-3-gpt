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

SYSTEM = <<~SYSTEM_PROMPT
  You are an experienced Vue.js programmer who is migrating Vue component files from Vue 2 to Vue 3 one at a time.
  You respond with the given code migrated to the Vue 3.0 compositional style. You are concise in your answer, giving
  no further commentary and you migrate all the given code. The migrated code should have the exact same behavior as
  the original code.

  Don't forget that since the code is going to be Single-File Components you don't need to call `.value` on references
  and computed values in the template.

  The Vue 2 components make use of helpers from the NextTwinspect component, in the Vue 3.0 components you can make use
  of the `useNextTwinspect` composable which is located at `@/composables/useNextTwinspect` and it exports the following
  helpers:

  ```
  export function snack(message: string, color: string) {
    store.commit('setSnack', { message, color })
  }

  export function unsafeSnack(message: string, color: string) {
    store.commit('setSnack', { message, color, unsafe: true })
  }

  export function cesiumSnack(message: string, color: string) {
    const viewerStore = useCesiumViewerStore()
    viewerStore.setCesiumSnackbarDetails({ message, color })
  }

  export function priceCentsInEuro(price: number) {
    return price / 100
  }

  export function capitalize(string: string) {
    if (string) {
      return string[0].toUpperCase() + string.slice(1)
    }
  }

  export default function useNextTwinspect() {
    // ...
    return {
      currentUser,
      admin,
      canManage,
      aeroscan,
      selectedOrganizationId,
      setSelectedOrganizationId,
      blockRouteIfNameIsCurrentRouteName,
      hasPermanentNavigationDrawer,
      currentRoute,
      isIpadOrMobile,
      isSmallScreen,
      waitForTyping,
      debounceSearchQuery
    }
  }
  ```

  When migrating the props you should make sure to use `defineProps` with `withDefaults` to make sure all the types and defaults are properly set.
  Here's an example:

  Vue 2 input:

  ```
    @Prop() declare container: Deficiency | ElementComponent | ComponentGroup
    @Prop() declare scenario: Scenario
    @Prop({ default: false }) declare onlyEditor: boolean
    @Prop({ default: false }) declare isComponentGroupView: boolean
    @Prop() declare photos: Set<String>
  ```

  Vue 3 output:

  ```
  const props = withDefaults(defineProps<{
    container: Deficiency | ElementComponent | ComponentGroup,
    scenario: Scenario,
    onlyEditor?: boolean,
    isComponentGroupView?: boolean
  }>(), {
    onlyEditor: false,
    isComponentGroupView: false,
    photos: () => new Set<String>()
  })
  ```

  If you're writing a watcher for a value that's inside a reactive object, often with the name `state`
  make sure you use an anonymous function to access that value in the watcher like so:

  Vue 2 input:

  ```
  @Watch('inviteType')
  async invitationTypeChanged(type: string) {
    if (type === "unit") {
      await this.fetchUnits()
    }
  }
  ```

  Vue 3 output:

  ```
  watch(() => state.inviteType, async (type) => {
    if (type === "unit") {
      await fetchUnits()
    }
  })
  ```

  And here is a more complete full file example:

  Vue 2 input:

  ```
  #{File.read("#{__dir__}/example-vue-2.vue")}
  ```

  Vue 3 output:
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
  content = result.dig("choices", 0, "message", "content")
  raise "No content: #{result.inspect}" if content.nil?
  content
rescue => e
  $stderr.puts "Error: #{e.message}\n#{result.inspect}\n\n#{e.backtrace.join("\n")}"
  exit 1
end

path = ARGV[0]
original = File.read(path)

# extract the <style>, <template> and <script> elements from the original vue file

original_style = original.match(/^(<style.*?>(.*?)^<\/style>)/m)&.[](1)
original_template = original.match(/^(<template.*?>(.*?)^<\/template>)/m)[1]
original_script = original.match(/^(<script.*?>(.*?)^<\/script>)/m)[1]

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

