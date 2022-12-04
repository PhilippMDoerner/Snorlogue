import std/[unittest, strformat, httpclient, logging, options, strutils]
import ./utils/[constants, serverSetup, databaseSetup, responseValidators]
import ./utils/testModels/[creature]

addHandler(newConsoleLogger(levelThreshold = lvlDebug))

startServer()

suite "Testing POST Endpoint":
  setup:
    setupDatabase()

  teardown:
    resetDatabase()



  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When updating a Model via POST request by using "request-type" "put" in FormData
    Then it should update model in the database
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "put",
      "name": newModelName ,
      "description": model.description.get(),
      "family": $(model.family.int) ,
      "birthDate": "2022-01-01T00:00",
      "evilness": $model.evilness,
      "evilness2": $model.evilness2,
      "evilness3": $model.evilness3,
      "count": $model.count,
      "count2": $model.count2,
      "count3": $model.count3,
      "isCool": $model.isCool
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(200)

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == newModelName
    check allCreatures[0].id == model.id

    conn.close()


stopServer()