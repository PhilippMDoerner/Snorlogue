import ./genericRepository

## Implements the `FilePath` datatype to provide some way of dealing with Files

type FilePath* = distinct string ##
## A convenience type for norm models.
## To be used as type for model fields storing any sort of file.
## When a model with such a field is created, its file will automatically be stored in the 
## in the configured `MEDIA_ROOT<constants.html#MEDIA_ROOT_SETTING>`_ directory. Any attempts to fetch that file will also assume
## that it is being stored in the `MEDIA_ROOT` directory.
## 
## This field can use the `subdir<fileFieldUtils.html#subdir.t%2Cstring>`_ pragma to store files in a sub directory within `MEDIA_ROOT` instead.

func `$`*(x: FilePath): string {.borrow.}

proc add*(x: var FilePath, s: string) = 
  ## Appends the `string` `s` to the `FilePath<#FilePath>`_ `x`
  x.string.add(s)

proc add*(x: var FilePath, s: FilePath) = 
  ## Appends the `FilePath<#FilePath>`_ `s` to the `FilePath<#FilePath>`_ `x`
  x.string.add(s.string)

func to*(dbVal: DbValue, T: typedesc[FilePath]): T = 
  ## Helper proc for norm to convert `DbValue` to `FilePath<#FilePath>`_.
  dbVal.s.FilePath

func dbValue*(val: FilePath): DbValue = 
  ## Helper proc for norm to convert `FilePath<#FilePath>`_ to `DbValue`.
  dbValue(val.string)

func dbType*(T: typedesc[FilePath]): string = 
  ## Helper proc for norm to define which column-type to use for storing `FilePath` values.
  "TEXT"

template subdir*(directory: string) {.pragma.} ##
## A custom pragma for use with `FilePath<#FilePath>`_ fields.
## Defines in which subdirectory of your `MEDIA_ROOT<constants.html#MEDIA_ROOT_SETTING>`_ folder
## the files of this field should be stored.
