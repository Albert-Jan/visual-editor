# Rules (WIP)
Visual Editor (as in Quill) has a list of rules that are executed after each document change. Rules contain logic to be executed once a certain trigger/condition is fulfilled. For ex: One rule is to break out of blocks when 2 new white lines are inserted. Such a rule will attempt to go trough the entire document and scan for lines of text that match the condition: 2 white lines one after the other. Once such a pair is detected, then we modify the second line styling to remove the block attribute. The example above illustrates one potential use case for rules. However there are many other operations that can be shared between multiple text editing operations. Most of them will need: index, length, document and the new attribute. Some rules will apply only to the current text selection, some will apply to the entire document. Each rule is free to decide how to approach solving it's particular problem. When the toolbar buttons are pressed, we prepare a style change for the document. Most of the toolbar buttons will use the current selection to apply style changes via controller.formatSelection(). However it's possible to write code that does not depend on the selection and can be given any arbitrary range (including the full doc).

# Applying Rules 
RulesController is responsible for storing all predefined rules and custom rules which can be set using setCustomRules(). It also contains the applyRulesByType which is used in DocumentM delete(), format() and insert() methods to apply rules by each type.

# Rules list
Rules are split into 3 types: 
1. Insert
2. Format
3. Delete

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.