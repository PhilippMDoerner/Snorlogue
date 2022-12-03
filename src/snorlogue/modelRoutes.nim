import std/[tables, strformat, strutils, logging]
import norm/model
import prologue
import nimja/parser
import ./backend/backendController
import ./frontend/[pageContexts, frontendController, modelAnalysisService]
import ./constants

export constants
export pageContexts
export frontendController

proc addCrudRoutes*[T: Model](
  app: Prologue, 
  modelType: typedesc[T], 
  middlewares: seq[HandlerAsync] = @[], 
  urlPrefix: static string = "admin",
  sortFields: seq[string] = @["id"],
  sortDirection: SortDirection = SortDirection.ASC,
  beforeCreateAction: ActionProc[T] = nil,
  afterCreateAction: ActionProc[T] = nil,
  beforeDeleteAction: ActionProc[T] = nil,
  beforeUpdateAction: ActionProc[T] = nil,
  afterUpdateAction: ActionProc[T] = nil
) =
  ## Adds create, read, update and delete pages with `middlewares` for `modelType`.
  ## These pages have the URL pattern: 
  ## `<urlPrefix>/<modelType>/[create|delete|detail|list]/`. 
  ## The url uses the modelType in all lowercase. 
  ## By specifying `urlPrefix` you can customize the start of these URLs.
  ## 
  ## The list of Model entries on the list page can be sorted according 
  ## to the provided `sortFields`, which is "id" by default.
  ## You can sort them in ascending or descending order.
  ## 
  ## You can also provide event procs to execute before/after you create/update/delete
  ## an entry:
  ## - `beforeCreateAction` - Gets executed before creating a model. Note that the model will not have an id yet.
  ## - `afterCreateAction` - Gets executed after creating a model
  ## - `beforeUpdateAction` - Gets executed just before updating a model. Note that the model provided is the new model that will replace the old one.
  ## - `afterUpdateAction` - Gets executed just after updating a model. Note that the model provided is the new model that has replaced the old one.
  ## - `beforeDeleteAction` - Gets executed just before deleting a model
  debug "We got { middlewares.len()} middlewares"
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
    handler = createBackendController(T, urlPrefix, beforeCreateAction, afterCreateAction, beforeUpdateAction, afterUpdateAction, beforeDeleteAction),
    httpMethod = HttpPost,
    middlewares = middlewares,
  )
  debug(fmt"Added admin route POST   '{backendUrl}'")


proc addAdminRoutes*(
  app: var Prologue, 
  middlewares: seq[HandlerAsync] = @[],
  urlPrefix: static string = "admin"
) =
  ## Adds an overview, a config/about and an "sql" route.
  ## The overview route provides an overview over all registered models
  ## The sql route provides a page to execute raw SQL and look at the results.
  ## This view supports DML SQL only.
  ## The config route provides an overview over some settings, as well as all 
  ## registered routes of your prologue application.
  ## These routes will be available after the pattern 
  ## `urlPrefix/[overview | sql | config]/`
  debug fmt"Add Admin Overview Pages with {REGISTERED_MODELS.len} models"
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

  const displayConfigUrl = fmt"/{urlPrefix}/{$Page.Config}/"
  app.addRoute(
    displayConfigUrl,
    handler = createAboutApplicationFrontendController(urlPrefix),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '{displayConfigUrl}'")
