import norm/model
import prologue
import std/[strutils, strformat, options, sequtils, sugar, os, re]
import utils/[controllerUtils, macroUtils]
import pageContexts
import nimja/parser
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
    let dummyModel = T()

    let context = initCreateContext(dummyModel, urlPrefix)
    let html = renderNimjaPage("modelCreate.nimja", context)

    resp htmlResponse(html)

proc createDetailController*[T: Model](modelType: typedesc[T], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    mixin toFormField
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let context = initDetailContext(model, urlPrefix)
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
    let context = initListContext[T](models, urlPrefix, count, pageIndex, pageSize)
    let html = renderNimjaPage("modelList.nimja", context)

    resp htmlResponse(html)

proc createConfirmDeleteController*[T: Model](modelType: typedesc[T], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let context = initDeleteContext(model, urlPrefix)
    let html = renderNimjaPage("modelDelete.nimja", context)

    resp htmlResponse(html)

proc createOverviewController*(registeredModels: seq[ModelMetaData], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let context = initOverviewContext(registeredModels, urlPrefix)   
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
    
    let context = initSqlContext(urlPrefix, query, rows, columns, errorMsg)
    let html = renderNimjaPage("sql.nimja", context)

    resp htmlResponse(html)