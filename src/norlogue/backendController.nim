import norm/model
import prologue
import std/[strutils, json, strformat]
import constants

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  newException(Defect, "Norlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'")


proc createCreateController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    var newModel = T()
    create(newModel)
    
    let detailPageUrl = fmt"{generateUrlStub(Page.DETAIL, T)}/{newModel.id}/"
    resp redirect(detailPageUrl)

proc createUpdateController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64

    var updateModel = T(id: id)
    update(updateModel)
    
    let detailPageUrl = fmt"{generateUrlStub(Page.DETAIL, T)}/{updateModel.id}/"
    resp redirect(detailPageUrl)

proc createDeleteController*[T: Model](model: typedesc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let id = parseInt(ctx.getPathParams(ID_PARAM)).int64
    delete(T, id)

    let listPageUrl = fmt"{generateUrlStub(Page.LIST, T)}/"
    resp redirect(listPageUrl)
