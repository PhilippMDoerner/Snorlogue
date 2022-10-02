import norm/model
import std/[strformat, strutils, tables, math, options]
import utils/formUtils

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  newException(Defect, "snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'")


type Page* = enum
  CREATE = "create"
  DELETE = "delete"
  DETAIL = "detail"
  LIST = "list"
  OVERVIEW = "overview"
  BACKEND
  SQL = "sql"

proc generateUrlStub*(action: Page, modelName: string): string =
  result = case action:
  of Page.OVERVIEW, Page.SQL:
    fmt"/{$action}"
  of Page.BACKEND:
    fmt"/{modelName}"
  else:
    fmt"/{modelName}/{$action}"

proc generateUrlStub*[T: Model](action: Page, model: typedesc[T]): string =
  let modelName = ($model).toLower()
  result = generateUrlStub(action, modelName)

proc extractFields*[T: Model](model: T): seq[ModelField] =
  result = @[]
  for name, value in model[].fieldPairs:
    result.add(convertToModelField(value, name))



type PageContext* = object of RootObj
  overviewUrl*: string

type ModelListContext*[T] = object of PageContext
  modelName*: string
  models*: seq[T]
  totalModelCount*: int64
  deleteUrlStub*: string
  createUrl*: string
  detailUrlStub*: string
  listUrlStub*: string
  pageIndices*: seq[int]
  currentPageIndex*: int
  isFirstPage*: bool
  isLastPage*: bool

proc getPaginationIndices(pageIndex: int, maxPageIndex: int): seq[int] =
  let isLastPage = pageIndex == maxPageIndex
  let isFirstPage = pageIndex == 0

  if(not isFirstPage): result.add(pageIndex - 1)
  result.add(pageIndex)
  if(not isLastPage): result.add(pageIndex + 1)

proc initListContext*[T](models: seq[T], totalModelCount: int64, pageIndex: int, pageSize: int): ModelListContext[T] =
  let maxPageIndex: int = floor(totalModelCount.int / pageSize).int
  let isLastPage = pageIndex == maxPageIndex
  let isFirstPage = pageIndex == 0

  result = ModelListContext[T](
    overviewUrl: fmt"{generateUrlStub(Page.OVERVIEW, T)}/",

    modelName: $T,
    models: models,
    totalModelCount: totalModelCount,
    createUrl: fmt"{generateUrlStub(Page.CREATE, T)}/",
    deleteUrLStub: fmt"{generateUrlStub(Page.DELETE, T)}/",
    detailUrlStub: fmt"{generateUrlStub(Page.DETAIL, T)}/",
    listUrlStub: fmt"{generateUrlStub(Page.LIST, T)}/",
    pageIndices: getPaginationIndices(pageIndex, maxPageIndex),
    currentPageIndex: pageIndex,
    isFirstPage: isFirstPage,
    isLastPage: isLastPage
  )


type ModelDetailContext*[T] = object of PageContext
  modelName*: string
  model*: T
  fields*: seq[ModelField]
  deleteUrl*: string
  updateUrl*: string
  listUrl*: string

proc initDetailContext*[T: Model](model: T): ModelDetailContext[T] =
  let fields: seq[ModelField] = extractFields(model)

  ModelDetailContext[T](
    overviewUrl: fmt"{generateUrlStub(Page.OVERVIEW, T)}/",

    modelName: $T,
    model: model,
    fields: fields,
    deleteUrl: fmt"{generateUrlStub(Page.DELETE, T)}/{model.id}/",
    updateUrl: fmt"{generateUrlStub(Page.BACKEND, T)}/",
    listUrl: fmt"{generateUrlStub(Page.LIST, T)}/"
  )


type ModelDeleteContext*[T] = object of PageContext
  deleteUrl*: string
  detailUrl*: string
  model*: T
  modelName*: string

proc initDeleteContext*[T: Model](model: T): ModelDeleteContext[T] =
  ModelDeleteContext[T](
    overviewUrl: fmt"{generateUrlStub(Page.OVERVIEW, T)}/",

    model: model,
    deleteUrl: fmt"{generateUrlStub(Page.BACKEND, T)}/",
    detailUrl: fmt"{generateUrlStub(Page.DETAIL, T)}/{model.id}/",
    modelName: $T
  )


type ModelCreateContext*[T] = object of PageContext
  modelName*: string
  listUrl*: string
  createUrl*: string
  fields*: seq[ModelField]

proc initCreateContext*[T: Model](model: T): ModelCreateContext[T] =
  let fields: seq[ModelField] = extractFields(model)

  ModelCreateContext[T](
    overviewUrl: fmt"{generateUrlStub(Page.OVERVIEW, T)}/",
    
    modelName: $T,
    fields: fields,
    listUrl: fmt"{generateUrlStub(Page.LIST, T)}/",
    createUrl: fmt"{generateUrlStub(Page.BACKEND, T)}/",
  )


type OverviewContext* = object of PageContext
  modelLinks*: Table[string, string]
  sqlUrl*: string


proc initOverviewContext*(modelNames: seq[string]): OverviewContext =
  var modelLinks = initTable[string, string]()
  for modelName in modelNames:
    modelLinks[modelName] = fmt"{generateUrlStub(Page.LIST, modelName.toLower())}/"

  OverviewContext(
    overviewUrl: fmt"""{generateUrlStub(Page.OVERVIEW, "")}/""",

    sqlUrl: fmt"""{generateUrlStub(Page.SQL, "")}/""",
    modelLinks: modelLinks
  )

type SqlContext* = object of PageContext
  sqlUrl*: string
  query*: string
  rows*: Option[seq[Row]]
  columns*: Option[seq[string]]

proc initSqlContext*(query: string, rows: Option[seq[Row]], columnNames: Option[seq[string]]): SqlContext =
  let columns: seq[string] = @[]

  SqlContext(
    overviewUrl: fmt"""{generateUrlStub(Page.OVERVIEW, "")}/""",

    sqlUrl: fmt"""{generateUrlStub(Page.SQL, "")}/""",
    query: query,
    rows: rows,
    columns: columnNames
  )