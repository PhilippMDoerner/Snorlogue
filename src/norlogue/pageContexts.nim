import norm/model
import std/[strformat]
import utils/formUtils

type Page* = enum
  CREATE = "create"
  DELETE = "delete"
  DETAIL = "detail"
  LIST = "list"
  OVERVIEW = "overview"

type PageContext = object of RootObj
  overviewUrl*: string

type ModelListContext*[T] = object of PageContext
  modelName*: string
  models*: seq[T]
  deleteUrlStub*: string
  createUrl*: string
  detailUrlStub*: string

type ModelDetailContext*[T] = object of PageContext
  modelName*: string
  model*: T
  fields*: seq[ModelField]
  deleteUrl*: string
  updateUrl*: string
  listUrl*: string

type ModelDeleteContext*[T] = object of PageContext
  deleteUrl*: string
  detailUrl*: string
  model*: T

type ModelCreateContext*[T] = object of PageContext
  modelName*: string
  listUrl*: string
  createUrl*: string
  fields*: seq[ModelField]


proc generateUrlStub*[T: Model](action: Page, model: typedesc[T]): string =
  result = case action:
  of Page.OVERVIEW:
    "/overview"
  else:
    fmt"{$action}/{($model).toLower()}"  

proc extractFields*[T: Model](model: T): seq[ModelField] =
  result = @[]
  for name, value in model[].fieldPairs:
    result.add(convertToModelField(value, name))


proc initListContext*[T](models: seq[T]): ModelListContext[T] =
  result = ModelListContext[T](
    modelName: $T,
    models: models,
    createUrl: fmt"../{generateUrlStub(Page.CREATE, T)}",
    deleteUrLStub: fmt"../{generateUrlStub(Page.DELETE, T)}",
    detailUrlStub: fmt"../../{generateUrlStub(Page.DETAIL, T)}",
    overviewUrl: fmt"{generateUrlStub(Page.OVERVIEW, T)}"
  )

proc initDetailContext*[T: Model](model: T): ModelDetailContext[T] =
  let fields: seq[ModelField] = extractFields(model)

  ModelDetailContext[T](
    modelName: $T,
    model: model,
    fields: fields,
    deleteUrl: fmt"{generateUrlStub(Page.DELETE, T)}/{model.id}",
    updateUrl: fmt"{($T).toLower()}/{model.id}",
    overviewUrl: generateUrlStub(Page.OVERVIEW, T),
    listUrl: fmt"../../{generateUrlStub(Page.LIST, T)}"
  )

proc initDeleteContext*[T: Model](model: T): ModelDeleteContext[T] =
  ModelDeleteContext[T](
    model: model,
    deleteUrl: fmt"./",
    detailUrl: fmt"../{generateUrlStub(Page.DETAIL, T)}/{model.id}",
    overviewUrl: generateUrlStub(Page.OVERVIEW, T),
  )

proc initCreateContext*[T: Model](model: T): ModelCreateContext[T] =
  let fields: seq[ModelField] = extractFields(model)

  ModelCreateContext[T](
    modelName: $T,
    fields: fields,
    listUrl: fmt"../../{generateUrlStub(Page.LIST, T)}",
    createUrl: fmt"{generateUrlStub(Page.CREATE, T)}",
    overviewUrl: generateUrlStub(Page.OVERVIEW, T)
  )