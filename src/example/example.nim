import prologue
import norm/[sqlite, model]
import ../snorlogue
import std/[strutils, options, strformat, logging]
from os import `putEnv`

putEnv("DB_HOST", "db.sqlite3")
addHandler(newConsoleLogger(levelThreshold = lvlDebug))

type Creature* = ref object of Model
  name*: string
  description*: Option[string]
  image* {.subdir:"creature_images".}: FilePath

proc `$`*(model: Creature): string = model.name

proc afterCreateAction(connection: DbConn, model: Creature): void =
  echo fmt"Just created Creature '{model.name}'!"

proc main() =
  var app: Prologue = newApp()
  app.addCrudRoutes(Creature, afterCreateAction = afterCreateAction)
  app.addAdminRoutes()
  app.run()

main()
