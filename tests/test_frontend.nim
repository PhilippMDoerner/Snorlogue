import std/[unittest, strformat, httpclient, logging, options]
import ./utils/[constants, serverSetup, databaseSetup, responseValidators]
import ./utils/testModels/[creature]

addHandler(newConsoleLogger(levelThreshold = lvlDebug))

startServer()

suite "Testing GET Endpoints":
  setup:
    setupDatabase()
  teardown:
    resetDatabase()

  test """
    Given a server with snorlogue
    When requesting 'overview' frontend Page
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    #When
    const url = fmt"{TEST_SERVER_DOMAIN}/admin/overview/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)

  test """
    Given a server with snorlogue
    When requesting  'sql' frontend Page
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    #When
    const url = fmt"{TEST_SERVER_DOMAIN}/admin/sql/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)

  test """
    Given a server with snorlogue
    When requesting  'config' frontend Page
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    #When
    const url = fmt"{TEST_SERVER_DOMAIN}/admin/config/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)

  test """
    Given a server with snorlogue and a registered Model
    When requesting model's 'list' frontend Page without pageIndex
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    #When
    const url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/list/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)

  test """
    Given a server with snorlogue and a registered Model
    When requesting model's 'list' frontend Page with pageIndex
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    #When
    const url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/list/0/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)

  test """
    Given a server with snorlogue and a registered Model
    When requesting model's 'create' frontend Page
    Then it should return HTTP Code 200
  """:
    const url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/create/"
    var client = newHttpClient()

    let response = client.get(url)

    response.expectHttpCode(200)

  test """
    Given a server with snorlogue and a registered Model and a model in the database
    When requesting model's 'detail' frontend Page for the existing model instance
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    let conn = getServerDbConn()
    var dummyCreature = getDummyCreature()
    conn.createTables(dummyCreature)
    conn.insert(dummyCreature)
    conn.close()

    #When
    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/detail/{dummyCreature.id}/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)

  test """
    Given a server with snorlogue and a registered Model
    When requesting model's 'delete' frontend Page
    Then it should return HTTP Code 200
  """:
    #Given
    var client = newHttpClient()

    let conn = getServerDbConn()
    var dummyCreature = getDummyCreature()
    conn.createTables(dummyCreature)
    conn.insert(dummyCreature)
    conn.close()

    #When
    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/delete/{dummyCreature.id}/"
    let response = client.get(url)

    #Then
    response.expectHttpCode(200)


stopServer()