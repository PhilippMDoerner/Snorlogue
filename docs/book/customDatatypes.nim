import nimib, nimibook

import tutorial/tables
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
  - ``Filename``
  - ``DateTime``
  - ``fk*`` (type int64 annotated with norm's `fk` pragma)

Its main task in dealing with these types is:
  1) Map fields of certain types to certain pre-defined HTML input templates via `toFormField` procs
  2) Parse strings from incoming form data into the given type via `toModelValue` procs

Available HTML templates are represented by the `FormField` type and include:
  - Checkbox (default for `bool`)
  - Text input (default for `string`)
  - Number input (default for `int/float/Natural`)
  - Datetime input (default for `DateTime`)
  - File input (Default for `Filename`)
  - Select with number values (Default for `fk`)
  - Select with string values

If you want Snorlogue to be able to deal with fields with your own custom datatypes, all you need to do is define `toFormField` and `toModelValue` procs for them.

Say for example we wanted to have an enum field on a model, that is represented by a select field with int values in our Model:
"""

nbCode:
  # Required Code
  type CreatureFamily = enum
    BEAST
    ANGEL
    DEMON
    HUMANOID 

  type Creature* = ref object of Model
      name*: string
      family*: CreatureFamily

  # Example Usage
  putEnv("DB_HOST", ":memory:")
  withDb:
    var human = Creature(name: "Karl", family: CreatureFamily.HUMANOID)
    db.createTables(human)


# TODO: Finish the example above for how to specify select stuff

nbSave
