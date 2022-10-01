import norm/model
import prologue
import std/[strutils, json]
import utils/formUtils
import pageContexts
import nimja/parser
import constants

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  newException(Defect, "Norlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'")

const ID_PARAM* = "id"
const PAGE_PARAM* = "page"
const DEFAULT_PAGE_SIZE = 50

proc createCreateFormController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let dummyModel = T()

    let context = initCreateContext(dummyModel)
    let html = tmplf(getScriptDir() / "resources/pages/modelCreate.nimja", context = context)

    resp htmlResponse(html)

proc createDetailController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let context = initDetailContext()
    let html = tmplf(getScriptDir() / "resources/pages/modelDetail.nimja", context = context)

    resp htmlResponse(html)
  
proc createListController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let pageIndex = parseInt(ctx.getPathParams(PAGE_PARAM)).int64
    let pageSize = ctx.getPageSize()

    let models: seq[T] = list[T](pageIndex, pageSize)
    let context = initListContext[T](models)
    let html = tmplf(getScriptDir() / "resources/pages/modelList.nimja", context = context)

    resp htmlResponse(html)

proc createConfirmDeleteController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    let context = initDeleteContext(model)
    let html = tmplf(getScriptDir() / "resources/pages/modelDelete.nimja", context = context)

    resp htmlResponse(html)

proc getPageSize(ctx: Context): int =
    let pageSizeSetting: JsonNode = ctx.getSettings("pageSize")
    let hasPageSizeSetting = pageSizeSetting.kind == JNull
    result = if hasPageSizeSetting: pageSizeSetting.getInt() else: DEFAULT_PAGE_SIZE
