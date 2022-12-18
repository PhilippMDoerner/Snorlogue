import norm/[model]
import norm/postgres as norm_postgres
from ndb/postgres import instantRows
import std/[strformat, options, strutils, sequtils, sugar, tables]
import std/macros except getCustomPragmaVal
import ../constants

export postgres

## A repository implementing database interaction procs for postgres
## Do NOT use this module directly ! Use `genericRepository` instead !
## Any repository module must provide the procs `read`, `create`, `list`, `update`, `delete`, `count`, `executeQuery` and `listAll`.


proc read*[T: Model](id: int64): T =
  ## Reads a model with the given id from the database
  var targetEntry: T = new(T)

  const modelTableName: string = T.table()
  const condition: string = fmt"id = $1"

  let queryParams: array[1, DbValue] = [dbValue(id)]

  withDb:
    db.select(targetEntry, condition, queryParams)

  result = targetEntry

proc create*[T: Model](
  newModel: var T,
  beforeCreateAction: ActionProc[T],
  afterCreateAction: ActionProc[T]
) {.gcsafe.} =
  ## Inserts the `newModel` into the database.
  ## Executes the provided `ActionProc` before/after adding the model if they were provided.
  {.cast(gcsafe).}:
    withDb:
      if beforeCreateAction != nil:
        beforeCreateAction(db, newModel)

      db.insert(newModel)

      if afterCreateAction != nil:
        afterCreateAction(db, newModel)

proc list*[T: Model](
  pageIndex: int,
  pageSize: int,
  sortFields: seq[string],
  sortDirection: SortDirection
): seq[T] =
  ## Reads a paginated list of models from the database.
  ## The number of models in a page is `pageSize`.
  ## The list of models is sorted according to the provided `sortFields` in the order of `sortDirection`.
  var entryList: seq[T] = @[T()]

  let firstPageEntryIndex = pageIndex * pageSize
  let orderColumns = sortFields.join(", ")
  let condition = fmt"""
    id > 0 
    ORDER BY {orderColumns} {$sortDirection} 
    LIMIT {pageSize} 
    OFFSET {firstPageEntryIndex}
  """

  withDb:
    db.select(entryList, condition)

  result = entryList

proc update*[T: Model](
  updateModel: var T,
  beforeUpdateAction: ActionProc[T],
  afterUpdateAction: ActionProc[T]
) {.gcsafe.} =
  ## Persists the `updateModel` into the database, overwriting any previous entry with the same id.
  ## Executes the provided `ActionProc` before/after updating the model if they were provided.
  {.cast(gcsafe).}:
    withDb:
      if beforeUpdateAction != nil:
        beforeUpdateAction(db, updateModel)

      db.update(updateModel)

      if afterUpdateAction != nil:
        afterUpdateAction(db, updateModel)

proc delete*[T: Model](
  modelType: typedesc[T],
  id: int64,
  beforeDeleteAction: ActionProc[T]
) {.gcsafe.} =
  ## Deletes the model of type `modelType` in the database with the given `id`.
  ## Executes the provided `ActionProc` before deleting the model if it was provided.
  {.cast(gcsafe).}:
    var modelToDelete = T(id: id)
    withDb:
      if beforeDeleteAction != nil:
        beforeDeleteAction(db, modelToDelete)

      db.delete(modelToDelete)

proc count*[T: Model](modelType: typedesc[T]): int64 =
  ## Counts the total number of entries in the database for the given `modelType`.
  withDb:
    result = db.count(T)


proc getColumnNames(db: DbConn, query: SqlQuery): seq[string] =
  ## TODO: Get this to work. It currently doesn't because somehow snorlogue does not have access to `instantRows` defined by ndb/postgres
  ## I don't have an explanation as to why that is, as the iterator IS DEFINED at https://github.com/xzfc/ndb.nim/blob/f9c85711ffc2ba350fb3c64e5ce38ada47380742/ndb/postgres.nim#L604 as are others
  ## But nim keeps claiming the symbol doesn't exist
  var columns: DbColumns
  for _ in instantRows(db, columns, query):
    discard

  result = columns.mapIt(it.name)


type QueryResult* = (seq[Row], seq[string])

proc executeQuery*(query: string): Option[QueryResult] =
  ## Executes the given SQL query on the database.
  ## Note that you may only use DML SQL statements.
  ## Returns a QueryResult if the given query is a SELECT query.
  let isForbiddenQuery = query.toUpper().split(" ").any(word => word in ["ALTER", "CREATE", "DROP", "TRUNCATE"])
  if isForbiddenQuery:
    raise newException(DbError, "Data-Definition-Language (DDL) (SQL statements containing e.g. 'ALTER', 'CREATE', 'DROP' or 'TRUNCATE') are not allowed to prevent breaking your application. Please only use Data-Manipulation-Language (DML).")

  let isSelectQuery = query.toUpper().startsWith("SELECT")

  {.cast(gcsafe).}:
    withDb:
      if isSelectQuery:
        let columnNames = db.getColumnNames(sql query)
        let rows: seq[Row] = db.getAllRows(sql query)

        result = some((rows, columnNames))

      else:
        db.exec(sql query)
        result = none(QueryResult)

proc listAll*[T: Model](modelType: typedesc[T]): seq[T] =
  ## Reads an unpaginated, unsorted list of models of type `modelType` from the database.
  result = @[T()]
  withDb:
    db.selectAll(result)
