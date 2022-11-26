import prologue
import std/[strformat, json, os]
import ../constants
import ../pageContexts
import nimja/parser

proc getPageSize*(ctx: Context): int =
  ## Extracts the configured number of entries per page for pagination
  ## Defaults to 50 if nothing is set.
  let pageSizeSetting: JsonNode = ctx.getSettings("pageSize")
  let hasPageSizeSetting = pageSizeSetting != nil
  result = if hasPageSizeSetting: pageSizeSetting.getInt() else: DEFAULT_PAGE_SIZE

proc renderNimjaPage*[T: PageContext](pageName: static string, context: T): string =
  ## Renders the nimja template whose filename is provided via `pageName` with the provided context.
  const pagePath = fmt"resources/pages/{pageName}"
  tmplf(PACKAGE_PATH / pagePath, context = context)