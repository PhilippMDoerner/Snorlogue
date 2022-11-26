import norm/model
import prologue
import std/[strutils, json, strformat, options, sequtils]
import ./constants
import ./service/formService

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}

type RequestType = enum
  POST = "post"
  DELETE = "delete"
  PUT = "put"
  PATCH = "patch"
  GET = "get"


proc createHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeCreateAction: ActionProc[T], afterCreateAction: ActionProc[T]) {.gcsafe.} =
  {.cast(gcsafe).}:
    var newModel = parseFormData(ctx, T)
    create(newModel, beforeCreateAction, afterCreateAction)
  
  let detailPageUrl = fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{newModel.id}/"
  resp redirect(detailPageUrl)

proc updateHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeUpdateAction: ActionProc[T], afterUpdateAction: ActionProc[T]) {.gcsafe.} =
  {.cast(gcsafe).}:
    var updateModel = parseFormData(ctx, T)
    update(updateModel, beforeUpdateAction, afterUpdateAction)
  
  let detailPageUrl = fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{updateModel.id}/"
  resp redirect(detailPageUrl, body = "")

proc deleteHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeDeleteAction: ActionProc[T]) {.gcsafe.}=
  let idStr: Option[string] = ctx.getFormParamsOption(ID_PARAM)
  if idStr.isNone():
    resp("", code = Http400)
    return

  let id = parseInt(idStr.get()).int64
  {.cast(gcsafe).}:
    delete(T, id, beforeDeleteAction)

  let listPageUrl = fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/"
  resp redirect(listPageUrl)


proc createBackendController*[T: Model](
  model: typedesc[T], 
  urlPrefix: static string, 
  beforeCreateAction: ActionProc[T], 
  afterCreateAction: ActionProc[T], 
  beforeUpdateAction: ActionProc[T], 
  afterUpdateAction: ActionProc[T], 
  beforeDeleteAction: ActionProc[T]
): HandlerAsync =
  ## Generates a prologue controller proc for POST, PUT and DELETE HTTP requests. 
  ## The controller enables creating, deleting and updating entries of type `model`.
  ## After such an action, the controller forwards you to one of the GET controllers. 
  ## Requires the `urlPrefix` to figure out the URL to forward to.
  ## 
  ## Executes the provided ActionProcs before or after a creating/deleting/updating an entry:
  ## - `beforeCreateAction` - Gets executed before creating a model. Note that the model will not have an id yet.
  ## - `afterCreateAction` - Gets executed after creating a model
  ## - `beforeUpdateAction` - Gets executed just before updating a model. Note that the model provided is the new model that will replace the old one.
  ## - `afterUpdateAction` - Gets executed just after updating a model. Note that the model provided is the new model that has replaced the old one.
  ## - `beforeDeleteAction` - Gets executed just before deleting a model
  ## 
  ## Provides an HTTP405 response if this controller gets called for any request with a type is not POST, PUT or DELETE.

  result = proc (ctx: Context) {.async, gcsafe.} =
    let requestTypeStr: string = ctx.getFormParams("request-type")
    let requestType: RequestType = parseEnum[RequestType](requestTypeStr)

    case requestType:
    of RequestType.POST: createHandler(ctx, T, urlPrefix, beforeCreateAction, afterCreateAction)
    of RequestType.PUT: updateHandler(ctx, T, urlPrefix, beforeUpdateAction, afterUpdateAction)
    of RequestType.DELETE: deleteHandler(ctx, T, urlPrefix, beforeDeleteAction)
    else:
      resp("This endpoint only supports POST, PUT and DELETE methods", code = Http405)
