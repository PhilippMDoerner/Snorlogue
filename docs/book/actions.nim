import nimib, nimibook


nbInit(theme = useNimibook)

nbText: """
# Snorlogue Actions
Sometimes you may want to perform action before or after you perform an update, insert or delete action on the database.
Snorlogue supports this by accepting `ActionProc` procedures and executing them as specified in the docs for `addCrudRoutes`.

Say for example, that you have a model with a file field and want to change the filepath that is stored by default:
"""

nbCode:
  import norm/[sqlite, model]
  import std/[strformat, options]
  import snorlogue

  # Define the type
  type Image* = ref object of Model
    imageFile*: Filename

  proc `$`*(entry: Image): string = fmt"Image #{entry.creature_id}"

  # Create the table
  withDb:
    var image = Image()
    db.createTables(image)

  # Setup the server
  let action: ActionProc = proc(connection: DbConn, entry: Image) = 
    entry.imageFile = entry.imageFile.string.split('/')[^1].Filename

  var app: Prologue = newApp()
  app.addCrudRoutes(Image, beforeCreateAction = action, beforeUpdateAction = action)
  app.addAdminRoutes()
  app.run()

nbText: """
This will fire up a server with CRUD routes for an Image filetype.
Every time before an `Image` entry is created or updated, it will take the filepath that would be stored in the database and removes anything before the last `/`.
"""

nbSave
