# Package

version       = "0.1.0"
author        = "Philipp Doerner"
description   = "A Prologue extension. Provides an admin environment"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.8"
requires "norm >= 2.5.0"
requires "prologue >= 0.6.0"
requires "nimja >= 0.8.4"

skipDirs = @["example"]

task run_example, "NOTE TO USER: ADJUST `--define:basePath` FLAG!!! - Compiles and runs the snorlogue example":
  ## You will further have to modify nimja/sharedhelper.nim getScriptDir() to return "nimbleTaskFix"
  ## const basePath {.strdefine.} = getProjectPath()
  ## const nimbleTaskFix = basePath[4..basePath.high].strip(chars={' ', '"'})
  --run
  --deepcopy:on
  --define:normDebug
  --define:ssl
  --styleCheck:usages
  --define:sqlite
  --define:basePath:"<HOME_DIRECTORY>/.nimble/pkgs/snorlogue-0.1.0/snorlogue"
  --outdir:"src/example"
  setCommand "c", "src/example/example.nim"