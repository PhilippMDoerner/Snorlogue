import norm/model
import prologue
import std/[strutils, json, strformat, os, options, sequtils]
import ./constants
import ./service/formService

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  newException(Defect, "Norlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'")

type RequestType = enum
  POST = "post"
  DELETE = "delete"
  PUT = "put"
  PATCH = "patch"
  GET = "get"


proc createHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string) =
  var newModel = parseFormData(ctx, T)
  create(newModel)
  
  let detailPageUrl = fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{newModel.id}/"
  resp redirect(detailPageUrl)

proc updateHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string) =
  var updateModel = parseFormData(ctx, T)
  update(updateModel)
  
  let detailPageUrl = fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{updateModel.id}/"
  resp redirect(detailPageUrl, body = "")

proc deleteHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string) =
  let idStr: Option[string] = ctx.getFormParamsOption(ID_PARAM)
  if idStr.isNone():
    resp("", code = Http400)
    return

  let id = parseInt(idStr.get()).int64
  delete(T, id)

  let listPageUrl = fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/"
  resp redirect(listPageUrl)


proc createBackendController*[T: Model](model: typedesc[T], urlPrefix: static string): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let requestTypeStr: string = ctx.getFormParams("request-type")
    let requestType: RequestType = parseEnum[RequestType](requestTypeStr)

    case requestType:
    of RequestType.POST: createHandler(ctx, T, urlPrefix)
    of RequestType.PUT: updateHandler(ctx, T, urlPrefix)
    of RequestType.DELETE: deleteHandler(ctx, T, urlPrefix)
    else:
      resp("This endpoint only supports creation, deletion and update of models", code = Http405)
