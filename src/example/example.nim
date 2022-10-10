import prologue
import norm/[sqlite, model]
import ../snorlogue
import std/[strutils, options, strformat, logging]
from os import `putEnv`

putEnv("DB_HOST", "db.sqlite3")
addHandler(newConsoleLogger(levelThreshold = lvlDebug))

type CreatureFamily* = enum
  HUMANOID
  CELESTIAL
  DEMONIC

type Creature* = ref object of Model
  name*: string
  description*: Option[string]
  family*: CreatureFamily

func dbType*(T: typedesc[CreatureFamily]): string = "INTEGER"
func dbValue*(val: CreatureFamily): DbValue = dbValue(val.int)
proc to*(dbVal: DbValue, T: typedesc[CreatureFamily]): CreatureFamily = dbVal.i.CreatureFamily

withDb:
  db.createTables(Creature())

proc `$`*(model: Creature): string = model.name

proc afterCreateAction(connection: DbConn, model: Creature): void =
  echo fmt"Just created Creature '{model.name}'!"

proc main() =
  var app: Prologue = newApp()
  app.addCrudRoutes(Creature, afterCreateAction = afterCreateAction)
  app.addAdminRoutes()
  app.run()

main()
