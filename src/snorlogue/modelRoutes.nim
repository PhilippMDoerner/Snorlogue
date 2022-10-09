import std/[tables, strformat, strutils, logging, sequtils]
import norm/model
import prologue
import nimja/parser
import ./backendController
import ./frontendController
import ./constants except `$`
import ./pageContexts
import ./service/modelAnalysisService

export pageContexts

const ID_PATTERN* = fmt r"(?P<{ID_PARAM}>[\d]+)"
const PAGE_PATTERN* =  fmt r"(?P<{PAGE_PARAM}>[\d]+)"

proc addCrudRoutes*[T: Model](
  app: var Prologue, 
  modelType: typedesc[T], 
  middlewares: seq[HandlerAsync] = @[], 
  urlPrefix: static string = "admin",
  sortFields: seq[string] = @["id"],
  sortDirection: SortDirection = SortDirection.ASC,
  beforeCreateEvent: EventProc[T] = nil,
  afterCreateEvent: EventProc[T] = nil,
  beforeDeleteEvent: EventProc[T] = nil,
  beforeUpdateEvent: EventProc[T] = nil,
  afterUpdateEvent: EventProc[T] = nil
) =
  ## Adds create, read, update and delete routes for the provided `modelType`.
  ## These routes will be available after the pattern 
  ## `fmt"{urlPrefix}/{modelName}/[create|delete|detail|list]/"
  ## Model entries shown in the list page can be sorted according 
  ## to the provided field names in ascending or descending order.
  ## You can also provide event procs to execute before/after you create/update/delete
  ## an entry.
  ## `beforeCreateEvent` - Gets executed before creating a model. Note that the model will not have an id yet.
  ## `afterCreateEvent` - Gets executed after creating a model
  ## `beforeUpdateEvent` - Gets executed just before updating a model. Note that the model provided is the new model that will replace the old one.
  ## `afterUpdateEvent` - Gets executed just after updating a model. Note that the model provided is the new model that has replaced the old one.
  ## `beforeCreateEvent` - Gets executed just before deleting a model

  static: validateModel[T](T)
  const modelMetaData = extractMetaData(urlPrefix, T)
  REGISTERED_MODELS.add(modelMetaData)
  
  const modelName = ($T).toLower()

  const detailUrl = fmt"/{urlPrefix}/{modelName}/{$Page.DETAIL}/{ID_PATTERN}/"
  app.addRoute(
    re detailUrl,
    handler = createDetailController[T](T, urlPrefix),
    httpMethod = [HttpGet, HttpPost],
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{detailUrl}'")

  const pageableListUrl = fmt"/{urlPrefix}/{modelName}/{$Page.LIST}/{PAGE_PATTERN}/"
  app.addRoute(
    re pageableListUrl,
    handler = createListController(T, urlPrefix,  sortFields, sortDirection),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{pageableListUrl}'")

  const listUrl = fmt"/{urlPrefix}/{modelName}/{$Page.LIST}/"
  app.addRoute(
    listUrl,
    handler = createListController(T, urlPrefix, sortFields, sortDirection),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{listUrl}'")

  const deleteUrl = fmt"/{urlPrefix}/{modelName}/{$Page.DELETE}/{ID_PATTERN}/"
  app.addRoute(
    re deleteUrl,
    handler = createConfirmDeleteController(T, urlPrefix),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{deleteUrl}'")

  const createUrl = fmt"/{urlPrefix}/{modelName}/{$Page.CREATE}/"
  app.addRoute(
    createUrl,
    handler = createCreateFormController(T, urlPrefix),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{createUrl}'")

  const backendUrl = fmt"/{urlPrefix}/{modelName}/"
  app.addRoute(
    backendUrl,
    handler = createBackendController(T, urlPrefix, beforeCreateEvent, afterCreateEvent, beforeUpdateEvent, afterUpdateEvent, beforeDeleteEvent),
    httpMethod = HttpPost,
    middlewares = middlewares,
  )
  debug(fmt"Added admin route POST   '{backendUrl}'")


proc addAdminRoutes*(
  app: var Prologue, 
  middlewares: seq[HandlerAsync] = @[],
  urlPrefix: static string = "admin"
) =
  ## Adds an overview and an "sql" route.
  ## The overview route provides an overview over all registered models
  ## The sql route provides a page to execute raw SQL and look at the results.
  ## This view supports DML SQL only.
  ## These routes will be available after the pattern 
  ## `fmt"{urlPrefix}/[overview | sql]/"
  const overviewUrl = fmt"/{urlPrefix}/{$Page.OVERVIEW}/"
  app.addRoute(
    overviewUrl,
    handler = createOverviewController(REGISTERED_MODELS, urlPrefix),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{overviewUrl}'")

  const sqlUrl = fmt"/{urlPrefix}/{$Page.SQL}/"
  app.addRoute(
    sqlUrl,
    handler = createSqlController(urlPrefix),
    httpMethod = HttpPost,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{sqlUrl}'")

  const sqlNoQueryUrl = fmt"/{urlPrefix}/{$Page.SQL}/"
  app.addRoute(
    sqlNoQueryUrl,
    handler = createSqlFrontendController(urlPrefix),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{sqlNoQueryUrl}'")