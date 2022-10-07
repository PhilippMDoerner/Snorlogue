import std/[tables, strformat, strutils, logging]
import norm/model
import prologue
import ./backendController
import ./frontendController
import ./constants except `$`
import pageContexts
import nimja/parser
import ./service/modelAnalysisService

export pageContexts

const ID_PATTERN* = fmt r"(?P<{ID_PARAM}>[\d]+)"
const PAGE_PATTERN* =  fmt r"(?P<{PAGE_PARAM}>[\d]+)"

var REGISTERED_MODELS*: seq[ModelMetaData] = @[]

proc addCrudRoutes*[T: Model](
  app: var Prologue, 
  modelType: typedesc[T], 
  middlewares: seq[HandlerAsync] = @[], 
  urlPrefix: static string = "admin",
  sortFields: seq[string] = @["id"],
  sortDirection: SortDirection = SortDirection.ASC
) =
  ## Adds create, read, update and delete routes for the provided `modelType`.
  ## These routes will be available after the pattern 
  ## `fmt"{urlPrefix}/{modelName}/[create|delete|detail|list]/"
  ## Model entries shown in the list page can be sorted according 
  ## to the provided field names in ascending or descending order.

  validateModel[T](modelType)
  const modelMetaData = extractMetaData(T)
  REGISTERED_MODELS.add(modelMetaData)
  
  let baseRoute = ($T).toLower()

  app.addRoute(
    re fmt"/{urlPrefix}/{baseRoute}/{$Page.DETAIL}/{ID_PATTERN}/",
    handler = createDetailController[T](T),
    httpMethod = [HttpGet, HttpPost],
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{baseRoute}/{$Page.DETAIL}/{ID_PATTERN}/'")

  app.addRoute(
    re fmt"/{urlPrefix}/{baseRoute}/{$Page.LIST}/{PAGE_PATTERN}/",
    handler = createListController(T, sortFields, sortDirection),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{baseRoute}/{$Page.LIST}/{PAGE_PATTERN}/'")

  app.addRoute(
    fmt"/{urlPrefix}/{baseRoute}/{$Page.LIST}/",
    handler = createListController(T, sortFields, sortDirection),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{baseRoute}/{$Page.LIST}/'")

  app.addRoute(
    re fmt"/{urlPrefix}/{baseRoute}/{$Page.DELETE}/{ID_PATTERN}/",
    handler = createConfirmDeleteController(T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{baseRoute}/{$Page.DELETE}/{ID_PATTERN}/'")

  app.addRoute(
    fmt"/{urlPrefix}/{baseRoute}/{$Page.CREATE}/",
    handler = createCreateFormController(T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{baseRoute}/{$Page.CREATE}/'")

  app.addRoute(
    fmt"/{urlPrefix}/{baseRoute}/",
    handler = createBackendController(T),
    httpMethod = HttpPost,
    middlewares = middlewares,
  )
  debug(fmt"Added admin route POST   '/{urlPrefix}/{baseRoute}/'")


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
  app.addRoute(
    fmt"/{urlPrefix}/{$Page.OVERVIEW}/",
    handler = createOverviewController(REGISTERED_MODELS),
    httpMethod = HttpGet,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{$Page.OVERVIEW}/'")

  app.addRoute(
    fmt"/{urlPrefix}/{$Page.SQL}/",
    handler = sqlController,
    httpMethod = HttpPost,
    middlewares = middlewares
  )
  debug(fmt"Added admin route GET    '/{urlPrefix}/{$Page.SQL}/'")
