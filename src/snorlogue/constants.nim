import std/[os, strformat]
import norm/model

when defined(postgres):
  import norm/postgres
elif defined(sqlite):
  import norm/sqlite
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}


const ID_PARAM* = "id"
const PAGE_PARAM* = "page"
const DEFAULT_PAGE_SIZE* = 50
const MEDIA_ROOT_SETTING* = "media-root"
const PACKAGE_PATH* = currentSourcePath().parentDir()
let DEFAULT_MEDIA_ROOT* = fmt"{getCurrentDir()}/media"

type SortDirection* = enum
  ASC, DESC

type EventProc*[T: Model] = proc(connection: DbConn, model: T): void

