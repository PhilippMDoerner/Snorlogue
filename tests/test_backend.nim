import std/[unittest, os, strformat, httpclient, logging]
import norm/model
import ./utils/[constants, serverSetup]

addHandler(newConsoleLogger(levelThreshold = lvlDebug))

when defined(postgres):
  import norm/postgres

  const DB_TYPE = DatabaseType.dtPostgres

  proc resetDatabase() =
    let dbConn = open(dbHost, dbUser, dbPassword, "template1")
    dbConn.exec(sql "DROP DATABASE IF EXISTS $#" % dbDatabase)
    dbConn.exec(sql "CREATE DATABASE $#" % dbDatabase)
    close dbConn

    delEnv(DB_HOST_ENV)
    delEnv(DB_USER_ENV)
    delEnv(DB_PASSWORD_ENV)
    delEnv(DB_NAME_ENV)

  proc setupDatabase() =
    resetDatabase()
    putEnv(DB_HOST_ENV, POSTGRES_HOST)
    putEnv(DB_USER_ENV, POSTGRES_USER)
    putEnv(DB_PASSWORD_ENV, POSTGRES_PASSWORD)
    putEnv(DB_NAME_ENV, POSTGRES_NAME)

elif defined(sqlite):
  import norm/sqlite

  const DB_TYPE = DatabaseType.dtSqlite

  proc setupDatabase() =
    putEnv(DB_HOST_ENV, SQLITE_HOST)

  proc resetDatabase() =
    removeFile SQLITE_HOST
    delEnv(DB_HOST_ENV)

else :
  {.error: "Snorlogue tests require you to specify which database type to test via specifying either '-d:sqlite' or '-d:postgres'".}


let serverBinaryPath = compileServer(DB_TYPE)
startServer(serverBinaryPath)

suite "":
  setup:
    setupDatabase()
  teardown:
    resetDatabase()

  test "Ping '' Page":
    const url = "http://localhost:8080/admin/overview/"
    var client = newHttpClient()
    let response = client.get(url)
    check response.code == 200.HttpCode

stopServer()