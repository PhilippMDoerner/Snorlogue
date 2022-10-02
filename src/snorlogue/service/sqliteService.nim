import norm/model
import norm/sqlite
import std/[strformat, options, strutils, sequtils]

export sqlite

proc read*[T: Model](id: int64): T =
  var targetEntry: T = new(T)

  const modelTableName: string = T.table()
  const condition: string = fmt"id = ?"

  let queryParams: array[1, DbValue] = [dbValue(id)]

  withDb:
    db.select(targetEntry, condition, queryParams)

  result = targetEntry

proc create*[T: Model](newModel: var T) {.gcsafe.}=
  withDb:
    db.insert(newModel)

proc list*[T: Model](pageIndex: int, pageSize: int): seq[T] =
  var entryList: seq[T] = @[T()]

  let firstPageEntryIndex = pageIndex * pageSize
  let condition = fmt"id > 0 ORDER BY id ASC LIMIT {pageSize} OFFSET {firstPageEntryIndex}"

  withDb:
    db.select(entryList, condition)

  result = entryList

proc update*[T: Model](updateModel: var T) {.gcsafe.}=
  withDb:
    db.update(updateModel)

proc delete*[T: Model](modelType: typedesc[T], id: int64) {.gcsafe.} =
  var modelToDelete = T(id: id)
  withDb:
    db.delete(modelToDelete)

proc count*[T: Model](modelType: typedesc[T]): int64 =
  withDb:
    result = db.count(T)

type QueryResult = (seq[Row], seq[string])

proc executeQuery*(query: string): Option[QueryResult] =
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