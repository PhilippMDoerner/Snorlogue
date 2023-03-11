import std/[httpclient, strformat, os, osproc, logging]
import ./constants
import ./databaseSetup

var serverProcess: Process
var binaryPath: string

proc copyResourcesDir() =
  copyDir(RESOURCES_DIR, fmt"{TEST_SERVER_DIR}/resources")

proc compileServer(dbType: string): string =
  copyResourcesDir()
  let serverFilePath = fmt"tests/utils/servers/application_test_server_{dbType}.nim"

  if not fileExists(serverFilePath):
    raise newException(IOError, fmt"Could not run testsuite. The file with the test-server code '{serverFilePath}' does not exist")

  let testServerCompileCommand = fmt"nim c --define:{dbType} --mm:orc --deepcopy:on --threads:on --warnings:off --hints:off --verbosity=0 {ADDITIONAL_COMPILER_PARAMS} {serverFilePath}"
  let compilationResult: int = execCmd(testServerCompileCommand)

  let compilationFailed: bool = compilationResult != 0
  if compilationFailed:
    raise newException(IOError, fmt"Could not run testsuite. Failed to compile test-server '{serverFilePath}'")

  const fileEnding = ".nim"
  let endIndex = serverFilePath.high - fileEnding.len
  binaryPath = serverFilePath[0..endIndex]
  return binaryPath

proc waitForServerToFinishBooting() =
  var client = newHttpClient()
  const url = "http://localhost:8080/admin/overview/"

  var hasServerStarted = false
  while not hasServerStarted:
    sleep(100) #100ms
    hasServerStarted = client.get(url).code == 200.HttpCode
    debug fmt"Server is online: {hasServerStarted}"

proc startServer*() =
  setupDatabase()

  binaryPath = compileServer(TESTED_DB_TYPE)
  serverProcess = startProcess(expandFilename(binaryPath))
  debug fmt"Server process is starting with PID '{serverProcess.processID}'"
  waitForServerToFinishBooting()



proc deleteFile(absoluteFilePath: string) =
  if fileExists(absoluteFilePath):
    removeFile(absoluteFilePath)

proc deleteDir(absoluteDirPath: string) =
  if dirExists(absoluteDirPath):
    removeDir(absoluteDirPath)

proc stopServer*() =
  debug fmt"Server process with PID '{serverProcess.processID}' was terminated"
  serverProcess.terminate()

  deleteFile(binaryPath)
  deleteDir(fmt"{TEST_SERVER_DIR}/resources")
