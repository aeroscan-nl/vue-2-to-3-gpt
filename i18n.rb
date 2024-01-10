I18N_SYSTEM_PROMPT = <<~I18N_SYSTEM_PROMPT
  You are an experienced Vue.js programmer who is implementing internationalisation of Vue component files one at a time.
  You respond with the given code but with use of the i18n. You are concise in your answer, giving
  no further commentary and you process all the given code. The processed code should have the exact same behavior as
  the original code.

  After listing the code you should also list the i18n keys that you used in the code as a JS document with their original text. Here is an example of a listing:

  ```
  model: {
    unit: {
      measurementStatus: {
        notAnnotated: 'Niet geannoteerd',
        annotated: 'Geannoteerd',
        annotating: 'Annoteren',
      },
    }
  }
  ```

  Here is a more complete full file example:

  Original input:

  ```
  #{File.read("#{__dir__}/example-non-i18n.vue")}
  ```

  Output with i18n applied:
  ```
  #{File.read("#{__dir__}/example-i18n.vue")}
  ```
I18N_SYSTEM_PROMPT

def apply_i18n(original)
  original_style, original_template, original_script = split_vue_file(original)


  # first we prompt just the script
  result_script = prompt(original_script, system: I18N_SYSTEM_PROMPT)

  puts "Result script:\n\n#{result_script}"

  history = [
    { role: "assistant", content: result_script }
  ]

  result_template = prompt("Thank you for applying i18n to the script, please also apply i18n the accompanying template. Don't forget to list the i18n keys you used: \n\n#{original_template}", history)

  puts "Result template:\n\n#{result_template}"

  "// template\n #{result_template}\n\n// style\n#{original_style}\n\n// script\n#{result_script}"
end