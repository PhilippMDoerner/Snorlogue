import std/[strformat, strutils]
import norm/model

type Page* = enum
  CREATE = "create"
  DELETE = "delete"
  DETAIL = "detail"
  LIST = "list"
  OVERVIEW = "overview"
  BACKEND
  SQL = "sql"
  CONFIG = "config"

proc generateUrlStub*(urlPrefix: static string, action: Page, modelName: string): string =
  result.add(fmt"/{urlPrefix}")
  case action:
  of Page.OVERVIEW, Page.SQL, Page.CONFIG:
    result.add fmt"/{$action}"
  of Page.BACKEND:
    result.add fmt"/{modelName}"
  else:
    result.add fmt"/{modelName}/{$action}"

proc generateUrlStub*[T: Model](urlPrefix: static string, action: Page, model: typedesc[T]): string =
  let modelName = ($model).toLower()
  result = generateUrlStub(urlPrefix, action, modelName)