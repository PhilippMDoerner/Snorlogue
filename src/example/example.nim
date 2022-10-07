import prologue
import norm/[sqlite, model]
import ../snorlogue
import std/[strutils, options, logging]
from os import `putEnv`

putEnv("DB_HOST", "db.sqlite3")
addHandler(newConsoleLogger(levelThreshold = lvlDebug))

type Creature* = ref object of Model
  name*: string
  description*: Option[string]
  image*: Filename

proc `$`*(model: Creature): string = model.name


proc main() =

  withDb:
    var creature1 = Creature(name: "Bat", description: some "Flies in the dark", image: "/some/test/filepath".Filename)
    db.createTables(creature1)
    db.insert(creature1)

  var app = newApp()
  app.addCrudRoutes(Creature)
  app.addAdminRoutes()
  app.run()

main()
