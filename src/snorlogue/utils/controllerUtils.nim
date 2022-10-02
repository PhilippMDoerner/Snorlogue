import prologue
import std/[strformat, json]
import ../constants
import ../pageContexts
import nimja/parser


proc getPageSize*(ctx: Context): int =
    let pageSizeSetting: JsonNode = ctx.getSettings("pageSize")
    let hasPageSizeSetting = pageSizeSetting != nil
    result = if hasPageSizeSetting: pageSizeSetting.getInt() else: DEFAULT_PAGE_SIZE


proc renderNimjaPage*[T: PageContext](pageName: string, context: T): string =
  tmplf(getScriptDir() / fmt"resources/pages/{pageName}", context = context)