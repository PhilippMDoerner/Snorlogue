import nimib, nimibook


nbInit(theme = useNimibook)

nbText: """
# File Fields
In order to deal with fields representing Files, Snorlogue provides a `FilePath` type. They do *not* contain the actual
file itself, but a path to the file itself.
This path is relative to the media directory, that can be configured via the `media-root` setting.
If no such setting is provided, snorlogue will default to the path in `MEDIA_ROOT_DEFAULT`.

A simple example could look like this:
"""

nbCode:
  import norm/[sqlite, model]
  import std/options
  import snorlogue
  import prologue

  # Define the type
  type Creature* = ref object of Model
    name*: string
    img*: FilePath

  proc `$`*(entry: Creature): string = entry.name

  putEnv("DB_HOST", ":memory:")

  # Create the table.
  withDb:
    var dummyCreature = Creature(img: "".FilePath, name: "Potato")
    db.createTables(dummyCreature)
    db.insert(dummyCreature)

  # Setup the server
  var app: Prologue = newApp()
  app.addCrudRoutes(Creature)
  app.addAdminRoutes()
  # app.run()

nbText: """
Should you try to create a Creature, you will be greeted by a Form consisting only of a file-upload button.
The file in this scenario will be stored in a directory relative to where the binary is, so `{getCurrentDir()}/media/{fileName}`.

If you want to store files for this particular field in a subdirectory instead, you can use Snorlogue's `subdir` pragma.
Using it will cause your files to be stured under `{getCurrentDir()}/media/{subdirPragmaValue}/{fileName}`
"""
# TODO: Finish this example
# Do not forget to note caveats about large files

nbCode:
  # Define the type
  type Creature2* = ref object of Model
    name*: string
    img* {.subdir: "creature_image".}: FilePath

  proc `$`*(entry: Creature2): string = entry.name

  # Create the table.
  withDb:
    var dummyCreature = Creature2(img: "".FilePath, name: "Potato")
    db.createTables(dummyCreature)
    db.insert(dummyCreature)

  # Setup the server
  var app2: Prologue = newApp()
  app2.addCrudRoutes(Creature)
  app2.addAdminRoutes()
  # app2.run()

nbText: """
The file in this scenario would be stored in a directory `{getCurrentDir()}/media/creature_image/{fileName}`.

# Caveat: Large Files
Snorlogue does not support upload of large files (>50MB).
The reason for that is that [prologue has issues with large file uploads](https://github.com/planety/prologue/issues/103).

"""

nbSave