import prologue
import std/[strformat, json, os]
import ../constants
import ../pageContexts
import nimja/parser


proc getPageSize*(ctx: Context): int =
    let pageSizeSetting: JsonNode = ctx.getSettings("pageSize")
    let hasPageSizeSetting = pageSizeSetting != nil
    result = if hasPageSizeSetting: pageSizeSetting.getInt() else: DEFAULT_PAGE_SIZE

proc renderNimjaPage*[T: PageContext](pageName: static string, context: T): string =
  const pagePath = fmt"resources/pages/{pageName}"
  tmplf(PACKAGE_PATH / pagePath, context = context)