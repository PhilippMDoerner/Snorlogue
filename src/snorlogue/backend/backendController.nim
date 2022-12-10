import norm/model
import prologue
import std/[strutils, json, strformat, options, sequtils]
import ../constants
import ../genericRepository
import ../urlUtils
import ./formParseService

## Provides any and all controller procs for any HTTP request that is not of type GET.

type RequestType = enum
  POST = "post"
  DELETE = "delete"
  PUT = "put"
  PATCH = "patch"
  GET = "get"

proc createHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeCreateAction: ActionProc[T], afterCreateAction: ActionProc[T]) {.gcsafe.} =
  {.cast(gcsafe).}:
    var newModel = parseFormData(ctx, T, skipIdField = true)
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
    raise newException(AssertionError, "Missing 'id' field for deleting Model '{$model}'")

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
  ## Generates a prologue controller proc for `POST` HTTP requests to create/update/delete entries of type `model`. 
  ## The POST request is interpreted as a POST, PUT or DELETE request depending on the form parameter "request-type".
  ## This is a workaround over inherent HTTP form limitations, which allow only sending POST/GET requests.
  ## 
  ## After a create/update/delete, the controller forwards you to the appropriate `GET` controller. 
  ## Requires the `urlPrefix` to figure out the URL to forward to.
  ## 
  ## Executes the provided ActionProcs before or after a creating/deleting/updating an entry:
  ## - `beforeCreateAction` - Gets executed before creating a model. Note that the model will not have an id yet.
  ## - `afterCreateAction` - Gets executed after creating a model
  ## - `beforeUpdateAction` - Gets executed just before updating a model. Note that the model provided is the new model that will replace the old one.
  ## - `afterUpdateAction` - Gets executed just after updating a model. Note that the model provided is the new model that has replaced the old one.
  ## - `beforeDeleteAction` - Gets executed just before deleting a model
  ## 
  ## Responds with HTTP405 if this controller gets called with any unexpected HTTP request method..

  result = proc (ctx: Context) {.async, gcsafe.} =
    let requestTypeStr: string = ctx.getFormParams("request-type")
    let requestType: RequestType = parseEnum[RequestType](requestTypeStr)

    case requestType:
    of RequestType.POST: createHandler(ctx, T, urlPrefix, beforeCreateAction, afterCreateAction)
    of RequestType.PUT: updateHandler(ctx, T, urlPrefix, beforeUpdateAction, afterUpdateAction)
    of RequestType.DELETE: deleteHandler(ctx, T, urlPrefix, beforeDeleteAction)
    else:
      resp("This endpoint only supports POST, PUT and DELETE methods", code = Http405)
