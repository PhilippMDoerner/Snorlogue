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
  ## Generates a URL to the specified `Page<#Page>`_.
  ## These URLs are incomplete for `CREATE`, `DELETE` and `DETAIL` pages,
  ## as they do not provide any URL parameters that may be necessary to select 
  ## a specific model entry from the database.
  ## This only generates the core URL and should only be used within this package.
  result.add(fmt"/{urlPrefix}")
  case action:
  of Page.OVERVIEW, Page.SQL, Page.CONFIG:
    result.add fmt"/{$action}"
  of Page.BACKEND:
    result.add fmt"/{modelName}"
  else:
    result.add fmt"/{modelName}/{$action}"

proc generateUrlStub*[T: Model](urlPrefix: static string, action: Page, model: typedesc[T]): string =
  ## Helper proc for `generateUrlStub`.
  ## Generates a URL to a specified `Page<#Page>`_ for a given model.
  ## Pages to use this with are only model-specific ones such as `BACKEND`, 
  ## `CREATE`, `DELETE`, `DETAIL` and `LIST`.
  ## 
  ## These URLs are incomplete for CREATE, DELETE and DETAIL pages,
  ## as they do not provide any URL parameters that may be necessary to select a 
  ## specific model entry from the database.
  ## This only generates the core URL and should only be used within this package.

  let modelName = ($model).toLower()
  result = generateUrlStub(urlPrefix, action, modelName)