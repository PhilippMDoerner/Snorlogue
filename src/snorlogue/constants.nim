import std/[os, strformat]

const ID_PARAM* = "id"
const PAGE_PARAM* = "page"
const DEFAULT_PAGE_SIZE* = 50
const MEDIA_ROOT_SETTING* = "media-root"
const PACKAGE_PATH* = currentSourcePath().parentDir().parentDir()
let DEFAULT_MEDIA_ROOT* = fmt"{getCurrentDir()}/media"

type SortDirection* = enum
  ASC, DESC


