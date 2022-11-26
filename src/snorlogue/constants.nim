import std/[os, strformat]
import norm/model

when defined(postgres):
  import norm/postgres
elif defined(sqlite):
  import norm/sqlite
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}

const UTC_TIME_FORMAT* = "yyyy-MM-dd'T'HH:mm:ss'.'ffffff'Z'"

const DATETIME_LOCAL_FORMAT* = "yyyy-MM-dd'T'HH:mm" ## 
## The expected DateTime Format of any string value representing a DateTime field of a model

const DEFAULT_PAGE_SIZE* = 50 ## 
## Default size for pagination

const MEDIA_ROOT_SETTING* = "media-root" ## 
## The name of the prologue setting that is used to configure the root media directory.
## All files from fields of type `FilePath` are to be stored in that directory.
## Sub-directories within the root directory can be specified with the 
## `subdir<service/fieldUtils/fileFieldUtils.html#subdir.t%2Cstring>`_ pragma.
##
## If no such setting is provided `DEFAULT_MEDIA_ROOT<#DEFAULT_MEDIA_ROOT>`_ is used.
 
const PACKAGE_PATH* = currentSourcePath().parentDir() ## 
## The filepath to root project folder being compiled.

let DEFAULT_MEDIA_ROOT* = fmt"{getCurrentDir()}/media" ## 
## Default MEDIA_ROOT directory

const ID_PARAM* = "id" ## 
## Name of the url parameter for the value of a unique identifier for a model

const PAGE_PARAM* = "page" ## 
## Name of the url parameter for a pagination index

const ID_PATTERN* = fmt r"(?P<{ID_PARAM}>[\d]+)" ## 
## Regular expression for use in routes, representing the ID url parameter

const PAGE_PATTERN* =  fmt r"(?P<{PAGE_PARAM}>[\d]+)" ## 
## Regular expression for use in routes, representing the PAGE url parameter 

type SortDirection* = enum
  ## Defines the possible ways to sort a list
  ASC, DESC

type ActionProc*[T: Model] = proc(connection: DbConn, model: T): void ## 
## Type a proc must have in order to be performed as an action 
## before or after a model is created, updated or deleted.
