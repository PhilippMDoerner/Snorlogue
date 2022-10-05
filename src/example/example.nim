import prologue
import norm/[sqlite, model]
import snorlogue
import std/[strutils, options]
from os import `putEnv`

putEnv("DB_HOST", ":memory:")
addHandler(newConsoleLogger(levelThreshold = lvlDebug))

type Creature* = ref object of Model
  name*: string
  description*: Option[string]
  image*: Filename


var app = newApp()
app.addCrudRoutes(Creature)
app.addAdminRoutes()
app.run()


