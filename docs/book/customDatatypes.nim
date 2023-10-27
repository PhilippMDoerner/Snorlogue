import nimib, nimibook
import norm/[sqlite, model]
import std/[os, strutils]

nbInit(theme = useNimibook)


nbText: """
# Default Supported Datatypes
Out of the box, Snorlogue has support for the majority of "normal" data-types in nim.
For every datatype, the following 2 steps need to be defined:
  1) How to map norm model-fields to FormField instances via `toFormField` procs.
  2) How to map form-field values (which are always strings) to norm model-field types via `toModelValue` procs

FormFields define the type of HTML form-fields that are available in Snorlogue to represent a nim-type of a model-field in an HTML form.
These are the fields Snorlogue provides:

FormFieldKind | HTML field | nim-types | FormField-fields
---------|-------|-------|-------------
STRING | [Text input](https://www.w3schools.com/jsref/dom_obj_text.asp) | string | kind, name, strVal
INT | [Number input](https://www.w3schools.com/jsref/dom_obj_number.asp) | int, int32, int64, uint, uint32, uint64, Natural | kind, name, iVal
FLOAT | [Number input](https://www.w3schools.com/jsref/dom_obj_number.asp) | float, float32, float64 | kind, name, fVal
BOOL | [Checkbox input](https://www.w3schools.com/jsref/dom_obj_checkbox.asp) | bool | kind, name, bVal
DATE | [Datetime-local input](https://www.w3schools.com/jsref/dom_obj_datetime-local.asp) | DateTime | kind, name, dtVal
FILE | [File input](https://www.w3schools.com/jsref/dom_obj_fileupload.asp) | FilePath | kind, name, fileVal
INTSELECT | [Select](https://www.w3schools.com/tags/tag_select.asp) | foreignKey* | kind, name, intSeqVal, intOptions
STRSELECT | [Select](https://www.w3schools.com/tags/tag_select.asp) | -** | kind, name, strSeqVal, strOptions
  *type int64 annotated with norm's `fk` pragma. The Model in the pragma must also be registered to Snorlogue <br>
  **exists for users that want select fields with string values 


# Custom Datatypes


To extend that list with your own datatypes, just define `toFormField` and `toModelValue` procs for them!
This takes care of only the frontend though, you will still need to define `dbType`, `dbValue` and `to` [procs for norm](https://norm.nim.town/customDatatypes.html).

For example if we had a distinct string type of `UID` and wanted to support this in snorlogue:
"""

nbCode:
  import prologue
  import snorlogue
  import norm/[sqlite, model]
  import std/[options, sequtils, algorithm, strformat, sugar]

  # Type Definitions
  type Level = 0..9
  type UID = distinct string
  type CreatureType = enum
    A, B, C

  type Creature* = ref object of Model
    uid*: UID
    name*: string
    level*: Level
    kind*: CreatureType

  func `$`*(model: Creature): string = model.name

  # Converts a `string` value to `UID`
  func toModelValue*(formValue: string, T: typedesc[UID]): T = formValue.UID

  # Maps `UID` to the `String` `FormField` and any value such a field might have is to be converted to `string` as well.
  func toFormField*(value: Option[UID], fieldName: string): FormField =
    let compatibilityValue: Option[string] = value.map(val => val.string)
    result = FormField(
      kind: FormFieldKind.STRING,
      name: fieldName,
      strVal: compatibilityValue
    )

  ## Procs for norm DB interaction
  # UID
  func dbType*(T: typedesc[UID]): string = "TEXT"
  func dbValue*(val: UID): DbValue = dbValue(val.string)
  proc to*(dbVal: DbValue, T: typedesc[UID]): T = dbVal.s.UID
  # CreatureType
  func dbType*(T: typedesc[CreatureType]): string = "TEXT"
  func dbValue*(val: CreatureType): DbValue = dbValue($val)
  proc to*(dbVal: DbValue, T: typedesc[CreatureType]): T = parseEnum[CreatureType](dbVal.s)
  # Level
  func dbType*(T: typedesc[Level]): string = "INT"
  func dbValue*(val: Level): DbValue = dbValue(val.int)
  proc to*(dbVal: DbValue, T: typedesc[Level]): T = dbVal.i.Level


  ## Procs for Snorlogue Form interaction
  # Maps `CreatureType` to the `IntSelect` `FormField` and any value such a field might have is to be converted to an int on the form.
  func toFormField*(value: Option[CreatureType], fieldName: string): FormField =
    var options: seq[IntOption] = @[]
    for enumValue in CreatureType:
      options.add(IntOption(name: $enumValue, value: enumValue.int))

    let formFieldValue: Option[int64] = value.map(val => val.int64)
    
    FormField(
      name: fieldName, 
      kind: FormFieldKind.INTSELECT, 
      intSeqVal: formFieldValue,
      intOptions: options
    )

  # Maps `Level` to the `IntSelect` `FormField` and any value such a field might have is to be converted to an int on the form.
  func toFormField*(value: Option[Level], fieldName: string): FormField =
    var options: seq[IntOption] = @[]
    const rangeName = $Level
    for rangeVal in Level.low..Level.high:
      let optionLabel = fmt"{rangeName} {rangeVal}"
      let optionValue = rangeVal.int
      options.add(IntOption(name: optionLabel, value: optionValue))

    let formFieldValue: Option[int64] = value.map(val => val.int64)

    options.sort((opt1, opt2: IntOption) => cmp(opt1.name, opt2.name))
    
    FormField(
      name: fieldName,
      kind: FormFieldKind.INTSELECT,
      intSeqVal: formFieldValue,
      intOptions: options
    )

  # Example Usage
  putEnv("DB_HOST", ":memory:")
  withDb:
    var human = Creature(name: "Karl", level: 5, uid: "12345abcde".UID)
    db.createTables(human)

  # Setup the server
  var app: Prologue = newApp()
  app.addCrudRoutes(Creature)
  app.addAdminRoutes()
  # app.run()

nbText: """
Note that no `toModelValue` had to be defined for `CreatureType` or `Level`.
Enums and range are somwhat special in that they do have default `toModelValue` procs defined for them, but can not have a default `toFormField` proc.
It is heavily discouraged to try and supply a generic `toFormField` for either of those types, as the nim compiler appears to not act consistently when those procs are defined, leading to various runtime bugs.
"""

nbSave
