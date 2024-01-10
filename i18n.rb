
def apply_i18n(path, original)
  system_prompt = <<~I18N_SYSTEM_PROMPT
    You are an experienced Vue.js programmer who is implementing internationalisation of Vue component files one at a time.
    You respond with the given code but with use of the i18n-vue plugin. You are concise in your answer, giving
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

    When choosing a path for an i18n key please structure it in a way that is structured like the path of the file. For example in the above listing the path of the file was:

    `src/model/Unit.Vue`

    Here is a more complete full file example:

    Original input:

    ```
    #{File.read("#{__dir__}/example-non-i18n.vue")}
    ```

    Output with i18n applied:
    ```
    #{File.read("#{__dir__}/example-i18n.vue")}
    ```

    In your response do not summarize or skip over parts of the code. Respond with every line even when there are no changes. If you get this wrong you will have failed the assignment and we will lose our jobs.
  I18N_SYSTEM_PROMPT

  original_style, original_template, original_script = split_vue_file(original)


  # first we prompt just the script
  result_script = prompt("Apply i18n to the following script that is located at: #{path}\n\n#{original_script}", system: system_prompt)

  puts "Result script:\n\n#{result_script}"

  history = [
    { role: "assistant", content: result_script }
  ]

  result_template = prompt("Thank you for applying i18n to the script, please also apply i18n the accompanying template. Don't forget to list the i18n keys you used and include every single line of the template: \n\n#{original_template}", history)

  puts "Result template:\n\n#{result_template}"

  "// template\n #{result_template}\n\n// style\n#{original_style}\n\n// script\n#{result_script}"
end