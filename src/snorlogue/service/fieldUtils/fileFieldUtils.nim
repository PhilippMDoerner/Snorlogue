import ./fieldTypes

when defined(postgres):
  import ../postgresService
elif defined(sqlite):
  import ../sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}

func `$`*(x: FilePath): string {.borrow.}

proc add*(x: var FilePath, s: string) = 
  ## Appends the `string` `s` to the `FilePath<fieldTypes.html#FilePath>`_ `x`
  x.string.add(s)

proc add*(x: var FilePath, s: FilePath) = 
  ## Appends the `FilePath<fieldTypes.html#FilePath>`_ `s` to the `FilePath<fieldTypes.html#FilePath>`_ `x`
  x.string.add(s.string)

func to*(dbVal: DbValue, T: typedesc[FilePath]): T = 
  ## Helper proc for norm to convert `DbValue` to `FilePath<fieldTypes.html#FilePath>`_.
  dbVal.s.FilePath

func dbValue*(val: FilePath): DbValue = 
  ## Helper proc for norm to convert `FilePath<fieldTypes.html#FilePath>`_ to `DbValue`.
  dbValue(val.string)

func dbType*(T: typedesc[FilePath]): string = 
  ## Helper proc for norm to define which column-type to use for storing `FilePath` values.
  "TEXT"

template subdir*(directory: string) {.pragma.} ##
## A custom pragma for use with `FilePath<fieldTypes.html#FilePath>`_ fields.
## Defines in which subdirectory of your `MEDIA_ROOT<../../constants.html#MEDIA_ROOT_SETTING>`_ folder
## the files of this field should be stored.
