import ./fieldTypes

when defined(postgres):
  import ../postgresService
elif defined(sqlite):
  import ../sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}

func `$`*(x: FilePath): string {.borrow.}
proc add*(x: var FilePath, s: string) = x.string.add(s)
proc add*(x: var FilePath, s: FilePath) = x.string.add(s.string)

func to*(dbVal: DbValue, T: typedesc[FilePath]): T = dbVal.s.FilePath
func dbValue*(val: FilePath): DbValue = dbValue(val.string)
func dbType*(T: typedesc[FilePath]): string = "TEXT"

# subdir pragma
template subdir*(directory: string) {.pragma.}