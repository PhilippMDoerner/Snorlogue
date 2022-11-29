import nimib, nimibook
import norm/[sqlite, model]
import std/[os, strutils]

nbInit(theme = useNimibook)


nbText: """
# Custom Datatypes

By default, Snorlogue can deal with the following Nim types in Model fields:
  - ``bool``
  - ``int/int8/16/32/64``
  - ``Natural``
  - ``uint/uint8/16/32/64``
  - ``string``
  - ``FilePath``
  - ``DateTime``
  - ``fk*`` (type int64 annotated with norm's `fk` pragma)
  - ``enum``

Its main task in dealing with these types is:
  1) Map fields of certain types to certain pre-defined HTML input templates via `toFormField` procs
  2) Parse strings from incoming form data into the given type via `toModelValue` procs

Available HTML templates are represented by the `FormField` type and include:
  - Checkbox (default for `bool`)
  - Text input (default for `string`)
  - Number input (default for `int/float/Natural`)
  - Datetime input (default for `DateTime`)
  - File input (Default for `FilePath`)
  - Select with number values (Default for `fk` and `enum`)
  - Select with string values

If you want Snorlogue to be able to deal with fields with your own custom datatypes, all you need to do is define `toFormField` and `toModelValue` procs for them.

Say for example we wanted to have a model field that can only contain a specific range of numbers, that is represented by a select field with int values.
We can do this by defining our own `toFormField` proc that generates the options such a select field should have and feeds it into a pre-defined `toFormField` construction proc for a select formfield with int values:
"""

nbCode:
  import prologue
  import snorlogue
  import norm/[sqlite, model]
  import std/[options, sequtils]
  # Type Definitions
  type Level = 0..9

  type Creature* = ref object of Model
      name*: string
      level*: Level
  
  # Defines which FormField a value of the Level type maps to
  func toFormField*(value: Option[Level], fieldName: string, isRequired: bool): FormField =
    let optionValues = toSeq(Level.low..Level.high)
    let options: seq[IntOption] = optionValues.map(val => IntOption(value: val, name: "Level {val}"))
    let value = value.map(val => val.int64)
    result = toFormField(value, fieldName, isRequired, options)

  # Converts the received string value from the HTML form into a Level type
  func toModelValue*(formValue: string, T: typedesc[Level]): T = parseInt(formValue).Level

  func `$`*(model: Creature): string = model.name

  # Example Usage
  putEnv("DB_HOST", ":memory:")
  withDb:
    var human = Creature(name: "Karl", level: 5)
    db.createTables(human)

  # Setup the server
  var app: Prologue = newApp()
  app.addCrudRoutes(Creature)
  app.addAdminRoutes()
  # app.run()


nbSave
