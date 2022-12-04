import std/[tables, typetraits, logging]
import prologue

type InvalidFormException* = object of ValueError

proc errorMappingMiddleware*(errorStatusCodeMap: Table[string, int]): HandlerAsync =
  result = proc(ctx: Context){.async.} =

    try:
      debug "DABUDABUDABU"
      await switch(ctx)
      debug "dadada"
    except:
      debug "RUDUDUDU"
      let exceptionName: string = $getCurrentException().type.name
      let errorCode = errorStatusCodeMap.getOrDefault(exceptionName, 500)
      respDefault(errorCode.HttpCode)

const defaultMap* = {
   $InvalidFormException: 400
}.toTable()
