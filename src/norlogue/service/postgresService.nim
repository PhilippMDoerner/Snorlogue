import norm/model
import norm/postgres
import std/[strformat]

proc read*[T: Model](id: int64): T =
  var targetEntry: T = new(T)

  const modelTableName: string = T.table()
  const condition: string = fmt"id = $1"

  let queryParams: array[1, DbValue] = [dbValue(id)]

  withDb:
    db.select(targetEntry, condition, queryParams)

  result = targetEntry

proc create*[T: Model](newModel: var T) =
  withDb:
    db.insert(newModel)

proc list*[T: Model](pageIndex: int, pageSize: int): seq[T] =
  var entryList: seq[T] = @[T()]

  let firstPageEntryIndex = pageIndex * pageSize
  let condition = fmt"LIMIT {pageSize} OFFSET {firstPageEntryIndex} ORDER BY id ASC"

  withDb:
    db.select(entryList, condition)

  result = entryList

proc update*[T: Model](updateModel: var T) =
  withDb:
    db.update(updateModel)

proc delete*[T: Model](id: int64) =
  var modelToDelete = T(id: id)
  withDb:
    db.delete(modelToDelete)