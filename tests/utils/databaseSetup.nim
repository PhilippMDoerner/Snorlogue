import std/[os, strformat]
import ./constants

when defined(postgres):
  import norm/postgres
  export postgres

  const TESTED_DB_TYPE* = "postgres"

  proc resetDatabase*() =
    let dbConn = open(POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD, "template1")
    dbConn.exec(sql fmt"DROP DATABASE IF EXISTS {POSTGRES_NAME}")
    dbConn.exec(sql fmt"CREATE DATABASE {POSTGRES_NAME}")
    close dbConn

    delEnv(DB_HOST_ENV)
    delEnv(DB_USER_ENV)
    delEnv(DB_PASSWORD_ENV)
    delEnv(DB_NAME_ENV)

  proc setupDatabase*() =
    resetDatabase()
    putEnv(DB_HOST_ENV, POSTGRES_HOST)
    putEnv(DB_USER_ENV, POSTGRES_USER)
    putEnv(DB_PASSWORD_ENV, POSTGRES_PASSWORD)
    putEnv(DB_NAME_ENV, POSTGRES_NAME)

elif defined(sqlite):
  import norm/sqlite
  export sqlite

  const TESTED_DB_TYPE* = "sqlite"

  proc setupDatabase*() =
    removeFile SQLITE_HOST
    putEnv(DB_HOST_ENV, SQLITE_HOST)

  proc resetDatabase*() =
    removeFile SQLITE_HOST
    delEnv(DB_HOST_ENV)

else :
  {.error: "Snorlogue tests require you to specify which database type to test via specifying either '-d:sqlite' or '-d:postgres'".}

proc getServerDbConn*(): DbConn =
  getDb()