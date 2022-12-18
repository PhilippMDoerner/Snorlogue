import nimibook

var book = initBookWithToc:
  entry("Welcome to Snorlogue!", "index.nim")
  entry("Basic Usage", "basicUsage.nim")
  entry("File Fields", "fileFields.nim")
  entry("Actions", "actions.nim")
  entry("Custom Datatypes", "customDatatypes.nim")
  entry("Changelog", "changelog.nim")

nimibookCli(book)
