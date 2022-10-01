import norm/model
import prologue
import std/[strutils, json]
import utils/formUtils

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  newException(Defect, "Norlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'")

const ID_PARAM* = "id"
const PAGE_PARAM* = "page"
const DEFAULT_PAGE_SIZE = 50

proc createCreateController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    discard

proc createReadController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    let model = read[T](id)
    discard

proc createListController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let pageIndex = parseInt(ctx.getPathParams(PAGE_PARAM)).int64
    let pageSize = ctx.getPageSize()

    let models: seq[T] = list[T](pageIndex, pageSize)
    discard

proc createUpdateController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    discard

proc createDeleteController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    delete(id)
    discard

proc getPageSize(ctx: Context): int =
    let pageSizeSetting: JsonNode = ctx.getSettings("pageSize")
    let hasPageSizeSetting = pageSizeSetting.kind == JNull
    result = if hasPageSizeSetting: pageSizeSetting.getInt() else: DEFAULT_PAGE_SIZE
