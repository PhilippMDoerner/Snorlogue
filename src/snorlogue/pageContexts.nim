import norm/[pragmas, model]
import std/[strformat, strutils, sequtils, tables, math, options, sugar]
import ./service/[modelAnalysisService, formService]
import ./constants

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}


type Page* = enum
  CREATE = "create"
  DELETE = "delete"
  DETAIL = "detail"
  LIST = "list"
  OVERVIEW = "overview"
  BACKEND
  SQL = "sql"

proc generateUrlStub*(urlPrefix: static string, action: Page, modelName: string): string =
  result.add(fmt"/{urlPrefix}")
  case action:
  of Page.OVERVIEW, Page.SQL:
    result.add fmt"/{$action}"
  of Page.BACKEND:
    result.add fmt"/{modelName}"
  else:
    result.add fmt"/{modelName}/{$action}"

proc generateUrlStub*[T: Model](urlPrefix: static string, action: Page, model: typedesc[T]): string =
  let modelName = ($model).toLower()
  result = generateUrlStub(urlPrefix, action, modelName)
  
proc hasFileField*(fields: seq[FormField]): bool =
  fields.any(field => field.kind == FormFieldKind.FILE)


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
  let isBeforeLastPage = pageIndex < maxPageIndex
  let isBeforeSecondLastPage = pageIndex < maxPageIndex - 1
  let isAfterFirstPage = pageIndex > 0
  let isAfterSecondPage = pageIndex > 1

  if(isAfterSecondPage): result.add(pageIndex - 2)
  if(isAfterFirstPage): result.add(pageIndex - 1)
  result.add(pageIndex)
  if(isBeforeLastPage): result.add(pageIndex + 1)
  if(isBeforeSecondLastPage): result.add(pageIndex + 2)

proc initListContext*[T](models: seq[T], urlPrefix: static string, totalModelCount: int64, pageIndex: int, pageSize: int): ModelListContext[T] =
  let maxPageIndex: int = floor(totalModelCount.int / pageSize).int
  let isLastPage = pageIndex == maxPageIndex
  let isFirstPage = pageIndex == 0

  result = ModelListContext[T](
    overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",

    modelName: $T,
    models: models,
    totalModelCount: totalModelCount,
    createUrl: fmt"{generateUrlStub(urlPrefix, Page.CREATE, T)}/",
    deleteUrLStub: fmt"{generateUrlStub(urlPrefix, Page.DELETE, T)}/",
    detailUrlStub: fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/",
    listUrlStub: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/",
    pageIndices: getPaginationIndices(pageIndex, maxPageIndex),
    currentPageIndex: pageIndex,
    isFirstPage: isFirstPage,
    isLastPage: isLastPage
  )


type ModelDetailContext*[T] = object of PageContext
  modelName*: string
  model*: T
  fields*: seq[FormField]
  hasFileField*: bool
  fkOptions*: Table[string, IntOption]
  deleteUrl*: string
  updateUrl*: string
  listUrl*: string

proc initDetailContext*[T: Model](model: T, urlPrefix: static string): ModelDetailContext[T] =
  let fields: seq[FormField] = extractFields[T](model)

  ModelDetailContext[T](
    overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",

    modelName: $T,
    model: model,
    fields: fields,
    hasFileField: hasFileField(fields),
    deleteUrl: fmt"{generateUrlStub(urlPrefix, Page.DELETE, T)}/{model.id}/",
    updateUrl: fmt"{generateUrlStub(urlPrefix, Page.BACKEND, T)}/",
    listUrl: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/"
  )


type ModelDeleteContext*[T] = object of PageContext
  deleteUrl*: string
  detailUrl*: string
  model*: T
  modelName*: string

proc initDeleteContext*[T: Model](model: T, urlPrefix: static string): ModelDeleteContext[T] =
  ModelDeleteContext[T](
    overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",

    model: model,
    deleteUrl: fmt"{generateUrlStub(urlPrefix, Page.BACKEND, T)}/",
    detailUrl: fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{model.id}/",
    modelName: $T
  )


type ModelCreateContext*[T] = object of PageContext
  modelName*: string
  listUrl*: string
  createUrl*: string
  fields*: seq[FormField]
  hasFileField*: bool

proc initCreateContext*[T: Model](model: T, urlPrefix: static string): ModelCreateContext[T] =
  let fields: seq[FormField] = extractFields(model)

  ModelCreateContext[T](
    overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",
    
    modelName: $T,
    fields: fields,
    hasFileField: hasFileField(fields),
    listUrl: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/",
    createUrl: fmt"{generateUrlStub(urlPrefix, Page.BACKEND, T)}/"
  )


type OverviewContext* = object of PageContext
  modelLinks*: OrderedTable[ModelMetaData, string]
  sqlUrl*: string

proc sort(entry1, entry2: (ModelMetaData, string)): int =
  if entry1[0].name > entry2[0].name: 
    1 
  else: 
    -1

proc initOverviewContext*(metaDataEntries: seq[ModelMetaData], urlPrefix: static string): OverviewContext =
  var modelLinks = initOrderedTable[ModelMetaData, string]()
  for metaData in metaDataEntries:
    modelLinks[metaData] = fmt"{generateUrlStub(urlPrefix, Page.LIST, metaData.name.toLower())}/"

  modelLinks.sort(sort)
  OverviewContext(
    overviewUrl: fmt"""{generateUrlStub(urlPrefix, Page.OVERVIEW, "")}/""",

    sqlUrl: fmt"""{generateUrlStub(urlPrefix, Page.SQL, "")}/""",
    modelLinks: modelLinks
  )

type SqlContext* = object of PageContext
  sqlUrl*: string
  query*: string
  rows*: Option[seq[Row]]
  columns*: Option[seq[string]]
  queryErrorMsg*: Option[string]

proc initSqlContext*(urlPrefix: static string, query: string, rows: Option[seq[Row]], columnNames: Option[seq[string]], errorMsg: Option[string]): SqlContext =
  let columns: seq[string] = @[]

  SqlContext(
    overviewUrl: fmt"""{generateUrlStub(urlPrefix, Page.OVERVIEW, "")}/""",

    sqlUrl: fmt"""{generateUrlStub(urlPrefix, Page.SQL, "")}/""",
    query: query,
    rows: rows,
    columns: columnNames,
    queryErrorMsg: errorMsg
  )