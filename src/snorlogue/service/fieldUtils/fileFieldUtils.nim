import ./fieldTypes

when defined(postgres):
  import ../postgresService
elif defined(sqlite):
  import ../sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}

func `$`*(x: Filename): string {.borrow.}
proc add*(x: var Filename, s: string) = x.string.add(s)
proc add*(x: var Filename, s: Filename) = x.string.add(s.string)

func to*(dbVal: DbValue, T: typedesc[Filename]): T = dbVal.s.Filename
func dbValue*(val: Filename): DbValue = dbValue(val.string)
func dbType*(T: typedesc[Filename]): string = "TEXT"