import norm/[sqlite, model]
import std/[strformat, options, strutils, sequtils, sugar, tables]
import std/macros except getCustomPragmaVal
import ../constants

export sqlite

proc read*[T: Model](id: int64): T =
  var targetEntry: T = new(T)

  const modelTableName: string = T.table()
  const condition: string = fmt"id = ?"

  let queryParams: array[1, DbValue] = [dbValue(id)]

  withDb:
    db.select(targetEntry, condition, queryParams)

  result = targetEntry

proc create*[T: Model](newModel: var T, beforeCreateAction: ActionProc[T], afterCreateAction: ActionProc[T]) {.gcsafe.}=
  withDb:
    if beforeCreateAction != nil:
      beforeCreateAction(db, newModel)

    db.insert(newModel)

    if afterCreateAction != nil:
      afterCreateAction(db, newModel)

proc list*[T: Model](pageIndex: int, pageSize: int, sortFields: seq[string], sortDirection: SortDirection): seq[T] =
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

proc update*[T: Model](updateModel: var T, beforeUpdateAction: ActionProc[T], afterUpdateAction: ActionProc[T]) {.gcsafe.}=
  withDb:
    if beforeUpdateAction != nil:
      beforeUpdateAction(db, updateModel)

    db.update(updateModel)

    if afterUpdateAction != nil:
      afterUpdateAction(db, updateModel)

proc delete*[T: Model](modelType: typedesc[T], id: int64, beforeDeleteAction: ActionProc[T]) {.gcsafe.} =
  var modelToDelete = T(id: id)
  withDb:
    if beforeDeleteAction != nil:
      beforeDeleteAction(db, modelToDelete)

    db.delete(modelToDelete)

proc count*[T: Model](modelType: typedesc[T]): int64 =
  withDb:
    result = db.count(T)

type QueryResult* = (seq[Row], seq[string])

proc executeQuery*(query: string): Option[QueryResult] =
  let isForbiddenQuery = query.toUpper().split(" ").any(word => word in ["ALTER", "CREATE", "DROP", "TRUNCATE"])
  if isForbiddenQuery:
    raise newException(DbError, "DDL statements (those containing 'ALTER', 'CREATE', 'DROP' or 'TRUNCATE' are not allowed to prevent breaking your application. Please only use DML.") 

  let isSelectQuery = query.toUpper().startsWith("SELECT")

  withDb: 
    if isSelectQuery:
      var columns: DbColumns
      for _ in db.instantRows(columns, sql query):
        discard

      let columnNames = columns.mapIt(it.name)
      let rows: seq[Row] = db.getAllRows(sql query)

      result = some((rows, columnNames))

    else:
      db.exec(sql query)
      result = none(QueryResult)

proc listAll*[T: Model](modelType: typedesc[T]): seq[T] =
  result = @[T()]
  withDb:
    db.selectAll(result)