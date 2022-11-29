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

# Doc Dependency
requires "nimibook >= 0.2.1"

skipDirs = @["example"]

task run_example, "NOTE TO USER: Remember to copy the resources folder into your project from which you are compiling! - Compiles and runs the snorlogue example":
  --run
  --deepcopy:on
  --define:normDebug
  --define:ssl
  --styleCheck:usages
  --define:sqlite
  --outdir:"src/example"
  setCommand "c", "src/example/example.nim"

task docs, "Write the package docs":
  exec "nim doc --verbosity:0 --define:sqlite --project --index:on " &
    "--git.url:git@github.com:PhilippMDoerner/Snorlogue.git" &
    "--git.commit:master " &
    "-o:docs/apidocs " &
    "src/snorlogue.nim"

task cl, "Compiles the lib":
  --deepcopy:on
  --define:normDebug
  --define:ssl
  --styleCheck:usages
  --define:sqlite
  --path:"/home/philipp/dev/snorlogue"
  --define:basePath:"/home/philipp/dev/snorlogue"
  setCommand "c", "src/snorlogue.nim"

task nimidocs, "Compiles the nimibook docs":
  rmDir "docs/bookCompiled"
  exec "cp -r ./src/snorlogue/resources ./docs/book"
  exec "nim c -d:release -d:sqlite nbook.nim"
  exec "./nbook -d:sqlite update"
  exec "./nbook -d:sqlite build"

task apis, "docs only for api":
  exec "nim doc --verbosity:0 --warnings:off --project --index:on -d:sqlite " &
    "--git.url:https://github.com/PhilippMDoerner/Snorlogue " &
    "--git.commit:main " &
    "-o:docs/plugin " &
    "src/snorlogue.nim"

  exec "nim buildIndex -o:docs/plugin/index.html docs/plugin"