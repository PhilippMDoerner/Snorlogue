import prologue
import norm/[sqlite, model]
import snorlogue
import std/[strutils, options, strformat, logging, times]
from os import `putEnv`
import ../testModels/creature

let logFile = open("testServerSqlite.log", fmWrite)
addHandler(newFileLogger(logFile, levelThreshold = lvlDebug))
addHandler(newConsoleLogger())

proc main() =
  withDb:
    db.createTables(Creature())

  var app: Prologue = newApp()
  app.addCrudRoutes(Creature, afterCreateAction = afterCreateAction)
  app.addAdminRoutes()
  app.run()

main()