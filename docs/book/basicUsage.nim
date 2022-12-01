import nimib, nimibook


nbInit(theme = useNimibook)

nbText: """
# How Snorlogue uses models

Snorlogue uses [norm models](https://norm.nim.town/models.html) as a representation of your database in nim types.
By knowing the model type, it can generate code to interact with the database, figure out which HTML input fields would best represent the individual model fields, how to parse an HTML-Form into a model type etc.

To register a model, just use the `addCrudRoute` proc provided by Snorlogue.
Once you registered your models, call `addAdminRoutes` to add the pages providing an overview over the registered models and an SQL route.

Lets set up an Sqlite database with a simple norm model called `Creature`:
"""

nbCode:
  import norm/[sqlite, model]
  import std/options

  # Define the type
  type Creature* = ref object of Model
    name*: string
    description*: Option[string]

  proc `$`*(entry: Creature): string = entry.name

  putEnv("DB_HOST", ":memory:") # For norm to find the database, see: https://norm.nim.town/config.html

  # Create the table.
  withDb:
    var creature1 = Creature(name: "Bat", description: some "Flies in the dark")
    db.createTables(creature1)
    db.insert(creature1)

nbText: """

The Creature model has 3 fields in total: name, description and id, which is inherited from `Model`.

Note how we also provide a `$` proc to tell snorlogue how to represent an instance of `Creature` as a string!
This is mandatory, as Snorlogue does not provide a default way to represent a model as a string, but needs this functionality to generate all the HTML.

Now you can add them to a prologue server:
"""
nbCode:
  import prologue
  import snorlogue
  # Setup the server
  var app: Prologue = newApp()
  app.addCrudRoutes(Creature)
  app.addAdminRoutes()
  #app.run() ## Can't compile a running HTTP server into docs ;-)


nbText: """
  And you're done! Your Prologue application now has access to the following GET routes:
  
    /admin/overview/
    /admin/sql/
    /admin/config
    /admin/creature/list/
    /admin/creature/list/<Page index>/
    /admin/creature/detail/<ID>/
    /admin/creature/delete/<ID>/
    /admin/creature/create/
  
  And the following POST route (which handles all form requests):
  
    /admin/creature/

  Click around and try them out!
"""

nbSave

