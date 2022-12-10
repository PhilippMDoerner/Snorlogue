import prologue
import norm/model
import std/[strformat, sequtils, tables, math, options, sugar]
import ./modelAnalysisService
import ./formCreateService
import ../urlUtils
import ../genericRepository

export urlUtils

## Provides `PageContext` objects necessary and procs to construct them.
## Each nimja template has its own type of `PageContext`, as such a context provides the data that gets rendered into the nimja template to create a snorlogue page.

var REGISTERED_MODELS*: seq[ModelMetaData] = @[]
  
proc hasFileField*(fields: seq[FormField]): bool =
  fields.any(field => field.kind == FormFieldKind.FILE)


type PageContext* = object of RootObj
  ## Base amount of data needed in a context for any snorlogue page. 
  ## Defines all fields required by the root template of all pages.
  currentPage*: Page
  currentUrl*: string
  overviewUrl*: string
  sqlUrl*: string
  aboutApplicationUrl*: string
  projectName*: string
  modelTypes*: seq[ModelMetaData]

type ModelListContext*[T] = object of PageContext
  ## Context for the LIST page
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

proc initListContext*[T](models: seq[T], urlPrefix: static string, settings: Settings, totalModelCount: int64, pageIndex: int, pageSize: int): ModelListContext[T] =
  ## Generates the context for a `LIST` page
  let maxPageIndex: int = floor(totalModelCount.int / pageSize).int
  let isLastPage = pageIndex == maxPageIndex
  let isFirstPage = pageIndex == 0

  {.cast(gcsafe).}:
    result = ModelListContext[T](
      overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",
      sqlUrl: fmt"{generateUrlStub(urlPrefix, Page.SQL, T)}/",
      currentPage: Page.LIST,
      currentUrl: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      modelTypes: REGISTERED_MODELS,

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
  ## Context for the `DETAIL` page
  modelName*: string
  model*: T
  fields*: seq[FormField]
  hasFileField*: bool
  fkOptions*: Table[string, IntOption]
  deleteUrl*: string
  updateUrl*: string
  listUrl*: string

proc initDetailContext*[T: Model](model: T, urlPrefix: static string, settings: Settings): ModelDetailContext[T] =
  ## Generates the context for a `DETAIL` page
  let fields: seq[FormField] = extractFields[T](model)

  {.cast(gcsafe).}:
    ModelDetailContext[T](
      overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",
      sqlUrl: fmt"{generateUrlStub(urlPrefix, Page.SQL, T)}/",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      currentPage: Page.DETAIL,
      currentUrl: fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/",
      modelTypes: REGISTERED_MODELS,

      modelName: $T,
      model: model,
      fields: fields,
      hasFileField: hasFileField(fields),
      deleteUrl: fmt"{generateUrlStub(urlPrefix, Page.DELETE, T)}/{model.id}/",
      updateUrl: fmt"{generateUrlStub(urlPrefix, Page.BACKEND, T)}/",
      listUrl: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/"
    )


type ModelDeleteContext*[T] = object of PageContext
  ## Context for the `DELETE` page
  deleteUrl*: string
  detailUrl*: string
  model*: T
  modelName*: string

proc initDeleteContext*[T: Model](model: T, urlPrefix: static string, settings: Settings): ModelDeleteContext[T] =
  ## Generates the context for a `DELETE` page
  {.cast(gcsafe).}:
    ModelDeleteContext[T](
      overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",
      sqlUrl: fmt"{generateUrlStub(urlPrefix, Page.SQL, T)}/",
      currentUrl: fmt"{generateUrlStub(urlPrefix, Page.DELETE, T)}/",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      currentPage: Page.DELETE,
      modelTypes: REGISTERED_MODELS,

      model: model,
      deleteUrl: fmt"{generateUrlStub(urlPrefix, Page.BACKEND, T)}/",
      detailUrl: fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{model.id}/",
      modelName: $T
    )


type ModelCreateContext*[T] = object of PageContext
  ## Context for the `CREATE` page
  modelName*: string
  listUrl*: string
  createUrl*: string
  fields*: seq[FormField]
  hasFileField*: bool

proc initCreateContext*[T: Model](model: T, urlPrefix: static string, settings: Settings): ModelCreateContext[T] =
  ## Generates the context for a `CREATE` page
  let fields: seq[FormField] = extractFields(model)
  {.cast(gcsafe).}:
    ModelCreateContext[T](
      overviewUrl: fmt"{generateUrlStub(urlPrefix, Page.OVERVIEW, T)}/",
      sqlUrl: fmt"{generateUrlStub(urlPrefix, Page.SQL, T)}/",
      currentUrl: fmt"{generateUrlStub(urlPrefix, Page.CREATE, T)}/",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      currentPage: Page.CREATE,
      modelTypes: REGISTERED_MODELS,

      modelName: $T,
      fields: fields,
      hasFileField: hasFileField(fields),
      listUrl: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/",
      createUrl: fmt"{generateUrlStub(urlPrefix, Page.BACKEND, T)}/"
    )


type OverviewContext* = object of PageContext
  ## Context for the `OVERVIEW` page
  modelLinks*: OrderedTable[ModelMetaData, string]

proc sort(entry1, entry2: (ModelMetaData, string)): int =
  if entry1[0].name > entry2[0].name: 
    1 
  else: 
    -1

proc initOverviewContext*(metaDataEntries: seq[ModelMetaData], urlPrefix: static string, settings: Settings): OverviewContext =
  ## Generates the context for a `OVERVIEW` page
  var modelLinks = initOrderedTable[ModelMetaData, string]()
  for metaData in metaDataEntries:
    modelLinks[metaData] = fmt"{generateUrlStub(urlPrefix, Page.LIST, metaData.name.toLower())}/"

  modelLinks.sort(sort)

  {.cast(gcsafe).}:
    OverviewContext(
      overviewUrl: fmt"""{generateUrlStub(urlPrefix, Page.OVERVIEW, "")}/""",
      sqlUrl: fmt"""{generateUrlStub(urlPrefix, Page.SQL, "")}/""",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      currentPage: Page.OVERVIEW,
      currentUrl: fmt"""{generateUrlStub(urlPrefix, Page.OVERVIEW, "")}/""",
      modelTypes: REGISTERED_MODELS,

      modelLinks: modelLinks
    )

type SqlContext* = object of PageContext
  ## Context for the `SQL` page
  query*: string
  rows*: Option[seq[Row]]
  columns*: Option[seq[string]]
  queryErrorMsg*: Option[string]

proc initSqlContext*(urlPrefix: static string, settings: Settings, query: string, rows: Option[seq[Row]], columnNames: Option[seq[string]], errorMsg: Option[string]): SqlContext =
  ## Generates the context for the `SQL` page
  let columns: seq[string] = @[]

  {.cast(gcsafe).}:
    SqlContext(
      overviewUrl: fmt"""{generateUrlStub(urlPrefix, Page.OVERVIEW, "")}/""",
      sqlUrl: fmt"""{generateUrlStub(urlPrefix, Page.SQL, "")}/""",
      currentUrl: fmt"""{generateUrlStub(urlPrefix, Page.SQL, "")}/""",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      currentPage: Page.SQL,
      modelTypes: REGISTERED_MODELS,

      query: query,
      rows: rows,
      columns: columnNames,
      queryErrorMsg: errorMsg
    )

type ConfigurationContext* = object of PageContext
  ## Context for the `CONFIG` page
  port*: int
  debug*: bool
  address*: string
  routes*: Table[string, seq[string]]

proc initAboutApplicationContext*(urlPrefix: static string, settings: Settings, routes: Table[string, seq[string]]): ConfigurationContext =
  ## Generates the context for the `CONFIG` page
  {.cast(gcsafe).}:
    ConfigurationContext(
      overviewUrl: fmt"""{generateUrlStub(urlPrefix, Page.OVERVIEW, "")}/""",
      sqlUrl: fmt"""{generateUrlStub(urlPrefix, Page.SQL, "")}/""",
      currentUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      aboutApplicationUrl: fmt"""{generateUrlStub(urlPrefix, Page.CONFIG, "")}/""",
      projectName: settings.getOrDefault("appName").getStr(""),
      currentPage: Page.CONFIG,
      modelTypes: REGISTERED_MODELS,

      port: settings.port.int,
      debug: settings.debug,
      address: settings.address,
      routes: routes
    )