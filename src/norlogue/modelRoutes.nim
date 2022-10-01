import std/[tables, strformat]
import norm/model
import prologue
import modelController

# proc addAdminRoutes*[T: Model](app: Prologue, route: string, models: TableRef[string, typedesc[T]], middlewares: seq[HandlerAsync] = @[] ) =
#   ## Adds create, read, update and delete routes for every provided model.
#   ## Also adds an overview-route over all models, which will show them split into sections as per the provided model table.
#   ## All routes will have the middlewares provided in the `middlewares` param attached to them.
#   app.addModelOverviewRoute(route, models, middlewares)
#
#   for sectionHeading, sectionModels in models.mpairs:
#       for model in sectionModels:
#         app.addCrudRoutes(route, model, middlewares)
const ID_PATTERN = fmt r"(?P<{ID_PARAM}>[\d]+)"
const PAGE_PATTERN =  fmt r"(?P<{PAGE_PARAM}>[\d]+)"

var REGISTERED_MODELS: seq[string] = @[]

proc validateModel[T: Model](model: typedesc[T]) =
  ## Ensure the following: 1) Model is not read only, 2) Model has no other model fields, they should be only FK fields
  discard

proc addCrudRoutes*[T: Model](app: Prologue, baseRoute: string, model: typedesc[T], middlewares: seq[HandlerAsync]) =
  REGISTERED_MODELS.add($T)

  app.addRoute(
    re fmt"{baseRoute}/",
    handler = createCreateController[T](),
    httpMethod = HttpPost,
    middlewares = middlewares,
  )

  app.addRoute(
    re fmt"{baseRoute}/{ID_PATTERN}/",
    handler = createReadController[T](),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"{baseRoute}/?{PAGE_PATTERN}",
    handler = createListController[T](),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"{baseRoute}/{ID_PATTERN}/",
    handler = createDeleteController[T](),
    httpMethod = HttpDelete,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"{baseRoute}/{ID_PATTERN}/",
    handler = createUpdateController[T](),
    httpMethod = HttpPut,
    middlewares = middlewares
  )