import prologue
import norm/[postgres, model]
import snorlogue
import std/[strutils, options, strformat, sugar, logging, times]
import ../testModels/creature

proc addLogger*() =
  addHandler(newConsoleLogger(levelThreshold = lvlDebug))

  let logFile = open("testServerSqlite.log", fmWrite)
  addHandler(newFileLogger(file = logFile))

  logging.setLogFilter(lvlDebug)

proc getStartUpEvents*(): seq[Event] =
  result.add(initEvent(() => addLogger()))

proc main() =
  withDb:
    db.createTables(Creature())

  var app: Prologue = newApp(
    startUp = getStartUpEvents()
  )
  app.addCrudRoutes(Creature, afterCreateAction = afterCreateAction)
  app.addAdminRoutes()
  app.run()

main()
