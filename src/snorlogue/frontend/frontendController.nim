import norm/model
import prologue
import std/[strutils, options, sequtils, critbits, sugar, strformat, tables]
import ./controllerUtils
import ./pageContexts
import ../constants
import ./formCreateService
import ./modelAnalysisService
import ./nimjaTemplateNames
import ../genericRepository

export formCreateService # To enable the call-site to parse forms
export strutils # To enable strutils procs in templates

## Provides any and all controller procs for any HTTP request of type GET.

proc createCreateFormController*[T: Model](
  modelType: typedesc[T],
  urlPrefix: static string
): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides a `CREATE` page for creating an entry of `modelType`.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  result = proc (ctx: Context) {.async, gcsafe.} =
    let dummyModel = new(T)
    let settings = ctx.gScope.settings
    let context = initCreateContext(dummyModel, urlPrefix, settings)
    let html = renderNimjaPage(MODEL_CREATE_PAGE, context)

    resp htmlResponse(html)

proc createDetailController*[T: Model](
  modelType: typedesc[T],
  urlPrefix: static string
): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides a `DETAIL` page, displaying and updating a specific entry of `modelType`.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  result = proc (ctx: Context) {.async, gcsafe.} =
    mixin toFormField
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let settings = ctx.gScope.settings
    let context = initDetailContext(model, urlPrefix, settings)
    let html = renderNimjaPage(MODEL_DETAIL_PAGE, context)

    resp htmlResponse(html)

proc createListController*[T: Model](
  modelType: typedesc[T],
  urlPrefix: static string,
  sortFields: seq[string],
  sortDirection: SortDirection
): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides a `LIST` page for displaying a list of all entries of `modelType`.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  ## Sorts the list of entries according to the provided fields in the provided direction.
  result = proc (ctx: Context) {.async, gcsafe.} =
    let pageIndex = ctx.getPathParamsOption(PAGE_PARAM).map(pIndex => parseInt(pIndex)).get(0)
    let pageSize = ctx.getPageSize()

    let models: seq[T] = list[T](pageIndex, pageSize, sortFields, sortDirection)
    let count: int64 = count(T)
    let settings = ctx.gScope.settings
    let context = initListContext[T](models, urlPrefix, settings, count, pageIndex, pageSize)
    let html = renderNimjaPage(MODEL_LIST_PAGE, context)

    resp htmlResponse(html)

proc createConfirmDeleteController*[T: Model](
  modelType: typedesc[T],
  urlPrefix: static string
): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides a `DELETE` page for deleting an entry of `modelType`.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let settings = ctx.gScope.settings
    let context = initDeleteContext(model, urlPrefix, settings)
    let html = renderNimjaPage(MODEL_DELETE_PAGE, context)

    resp htmlResponse(html)

proc createOverviewController*(
  registeredModels: seq[ModelMetaData],
  urlPrefix: static string
): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides the `OVERVIEW` page for displaying an overview over all models in `registeredModels`.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  result = proc (ctx: Context) {.async, gcsafe.} =
    let settings = ctx.gScope.settings
    let context = initOverviewContext(registeredModels, urlPrefix, settings)
    let html = renderNimjaPage(OVERVIEW_PAGE, context)

    resp htmlResponse(html)

proc createSqlController*(urlPrefix: static string): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides the SQL page for direct SQL access to the
  ## database including the result of a provided query.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
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
    let html = renderNimjaPage(SQL_PAGE, context)

    resp htmlResponse(html)



proc createSqlFrontendController*(urlPrefix: static string): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides the SQL for direct SQL access to the database.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  result = proc(ctx: Context) {.async, gcsafe.} =
    let settings = ctx.gScope.settings
    let context = initSqlContext(urlPrefix, settings, "", none(seq[Row]), none(seq[string]), none(string))
    let html = renderNimjaPage(SQL_PAGE, context)

    resp htmlResponse(html)


func stringifyRoutingTree(node: PatternNode, prefix: string): seq[string] =
  ## Generates string representation of all routes for a given httpMethod
  if node.isLeaf:
    let routeString = fmt"{prefix}{node.value.strip()}"
    result.add(routeString)
  else:
    for child in node.children:
      result = result.concat stringifyRoutingTree(child, fmt"{prefix}{node.value}")


func stringifyRoutingTree*(router: Router): Table[string, seq[string]] =
  ## Generates string representation of all routes of all http methods
  for httpMethod, tree in pairs(router.data):
    let httpMethodString = httpMethod.toUpper().align(6)
    result[httpMethod] = stringifyRoutingTree(tree, fmt"{httpMethodString} ")


proc createAboutApplicationFrontendController*(urlPrefix: static string): HandlerAsync =
  ## Generates a prologue controller proc for GET HTTP requests.
  ## The controller provides the CONFIG page for general application information such as settings and urls.
  ## Requires the `urlPrefix` used for all admin-endpoints for generating links to other pages.
  result = proc(ctx: Context) {.async, gcsafe.} =
    let routes = ctx.gScope.router.stringifyRoutingTree()
    let settings = ctx.gScope.settings

    let context = initAboutApplicationContext(urlPrefix, settings, routes)

    let html = renderNimjaPage(ABOUT_PAGE, context)

    resp htmlResponse(html)
