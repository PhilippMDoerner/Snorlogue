import norm/model
import prologue
import std/[strutils, options, sequtils, critbits, sugar, strformat, tables]
import ./utils/[controllerUtils]
import ./pageContexts
import ./constants
import ./service/[formService, modelAnalysisService]


when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}


proc createCreateFormController*[T: Model](modelType: typedesc[T], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let dummyModel = new(T)
    let settings = ctx.gScope.settings
    let context = initCreateContext(dummyModel, urlPrefix, settings)
    let html = renderNimjaPage("modelCreate.nimja", context)

    resp htmlResponse(html)

proc createDetailController*[T: Model](modelType: typedesc[T], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    mixin toFormField
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let settings = ctx.gScope.settings
    let context = initDetailContext(model, urlPrefix, settings)
    let html = renderNimjaPage("modelDetail.nimja", context)

    resp htmlResponse(html)
  
proc createListController*[T: Model](
  modelType: typedesc[T], 
  urlPrefix: static string, 
  sortFields: seq[string],
  sortDirection: SortDirection
): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let pageIndex = ctx.getPathParamsOption(PAGE_PARAM).map(pIndex => parseInt(pIndex)).get(0)
    let pageSize = ctx.getPageSize()

    let models: seq[T] = list[T](pageIndex, pageSize, sortFields, sortDirection)
    let count: int64 = count(T)
    let settings = ctx.gScope.settings
    let context = initListContext[T](models, urlPrefix, settings, count, pageIndex, pageSize)
    let html = renderNimjaPage("modelList.nimja", context)

    resp htmlResponse(html)

proc createConfirmDeleteController*[T: Model](modelType: typedesc[T], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let settings = ctx.gScope.settings
    let context = initDeleteContext(model, urlPrefix, settings)
    let html = renderNimjaPage("modelDelete.nimja", context)

    resp htmlResponse(html)

proc createOverviewController*(registeredModels: seq[ModelMetaData], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let settings = ctx.gScope.settings
    let context = initOverviewContext(registeredModels, urlPrefix, settings)
    let html = renderNimjaPage("overview.nimja", context) 

    resp htmlResponse(html)

proc createSqlController*(urlPrefix: static string): HandlerAsync =
  result = proc(ctx: Context) {.async, gcsafe.} =
    let queryParam = ctx.getFormParamsOption("sql")
    if queryParam.isNone():
      resp("Missing SQL query", code = Http400)
      return

    let query = queryParam.get().strip()
    
    var queryResult: Option[(seq[Row], seq[string])]
    var errorMsg: Option[string] = none(string)
    try:
      queryResult = executeQuery(query)
    except DbError:
      queryResult = none(QueryResult)
      errorMsg = some(getCurrentExceptionMsg())

    let rows = queryResult.map(res => res[0])
    let columns = queryResult.map(res => res[1])
    let settings = ctx.gScope.settings
    let context = initSqlContext(urlPrefix, settings, query, rows, columns, errorMsg)
    let html = renderNimjaPage("sql.nimja", context)

    resp htmlResponse(html)

  

proc createSqlFrontendController*(urlPrefix: static string): HandlerAsync =
  result = proc(ctx: Context) {.async, gcsafe.} =
    let settings = ctx.gScope.settings
    let context = initSqlContext(urlPrefix, settings, "", none(seq[Row]), none(seq[string]), none(string))
    let html = renderNimjaPage("sql.nimja", context)

    resp htmlResponse(html)


func stringifyRoutingTree(node: PatternNode, prefix: string): seq[string] =
  if node.isLeaf:
    let routeString = fmt"{prefix}{node.value.strip()}"
    result.add(routeString)
  else:
    for child in node.children:
      result = result.concat stringifyRoutingTree(child, fmt"{prefix}{node.value}")


func stringifyRoutingTree*(router: Router): Table[string, seq[string]] =
  ## Generates string representation of all routes
  for httpMethod, tree in pairs(router.data):
    let httpMethodString = httpMethod.toUpper().align(6)
    result[httpMethod] = stringifyRoutingTree(tree, fmt"{httpMethodString} ")


proc createAboutApplicationFrontendController*(urlPrefix: static string): HandlerAsync =
  result = proc(ctx: Context) {.async, gcsafe.} =
    let routes = ctx.gScope.router.stringifyRoutingTree()
    let settings = ctx.gScope.settings

    let context = initAboutApplicationContext(urlPrefix, settings, routes)

    let html = renderNimjaPage("aboutApplication.nimja", context)

    resp htmlResponse(html)
