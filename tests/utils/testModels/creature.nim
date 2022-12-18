import norm/model
import std/[options, times, sugar, strformat]
import snorlogue

when defined(postgres):
  import norm/postgres

elif defined(sqlite):
  import norm/sqlite

else:
  {.error: "Snorlogue tests require you to specify which database type to test via specifying either '-d:sqlite' or '-d:postgres'".}


type CreatureFamily* = enum
  HUMANOID
  CELESTIAL
  DEMONIC

type Creature* = ref object of Model
  name*: string
  description*: Option[string]
  family*: CreatureFamily
  birthDate*: DateTime
  evilness*: float
  evilness2*: float32
  evilness3*: float64
  count*: int
  count2*: int32
  count3*: int64
  isCool*: bool

func dbType*(T: typedesc[CreatureFamily]): string = "INTEGER"
func dbValue*(val: CreatureFamily): DbValue = dbValue(val.int)
proc to*(dbVal: DbValue, T: typedesc[CreatureFamily]): CreatureFamily = dbVal.i.CreatureFamily
proc `$`*(model: Creature): string = model.name

func toFormField*(value: Option[CreatureFamily], fieldName: string): FormField =
  var options: seq[IntOption] = @[]
  for enumValue in CreatureFamily:
    options.add(IntOption(name: $enumValue, value: enumValue.int))

  let formFieldValue: Option[int64] = value.map(val => val.int64)

  result.name = fieldName
  result.kind = FormFieldKind.INTSELECT
  result.intSeqVal = formFieldValue
  result.intOptions = options

proc afterCreateAction*(connection: DbConn, model: Creature): void =
  echo fmt"Just created Creature '{model.name}'!"

proc getDummyCreature*(): Creature =
  result = Creature(
    name: "TestCreature",
    description: some "TestDescription",
    family: CreatureFamily.HUMANOID,
    birthDate: now(),
    evilness: 0.0,
    evilness2: 0.1,
    evilness3: 0.2,
    count: 0,
    count2: 2,
    count3: 5,
    isCool: true
  )
