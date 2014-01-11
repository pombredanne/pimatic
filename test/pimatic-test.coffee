assert = require "cassert"

describe "pimatic", ->

  config =   
    settings:
      locale: "en"
      authentication:
        username: "test"
        password: "test"
        enabled: true
        disabled: true
      logLevel: "error"
      httpServer:
        enabled: true
        port: 8080
      httpsServer:
        enabled: false
      plugins: []
      devices: []
      rules: []

  fs = require 'fs'
  os = require 'os'
  configFile = "#{os.tmpdir()}/pimatic-test-config.json"

  before ->
    fs.writeFileSync configFile, JSON.stringify(config)
    process.env.PIMATIC_CONFIG = configFile

  after ->
    fs.unlinkSync configFile

  framework = null
  deviceConfig = null

  describe 'startup', ->

    it "should startup", ->
      framework = (require '../startup').framework

    it "httpServer should run", (done)->
      http = require 'http'
      http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
        done()
      ).on "error", (e) ->
        throw e

    it "httpServer should ask for password", (done)->
      http = require 'http'
      http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
        assert res.statusCode is 401 # is Unauthorized
        done()
      ).on "error", (e) ->
        throw e

  describe '#addDeviceToConfig()', ->

    deviceConfig = 
      id: 'test-actuator'
      class: 'TestActuatorClass'

    it 'should add the actuator to the config', ->

      framework.addDeviceToConfig deviceConfig
      assert framework.config.devices.length is 1
      assert framework.config.devices[0].id is deviceConfig.id

    it 'should throw an error if the actuator exists', ->
      try
        framework.addDeviceToConfig deviceConfig
        assert false
      catch e
        assert e.message is "an device with the id #{deviceConfig.id} is already in the config"

  describe '#isDeviceInConfig()', ->

    it 'should find actuator in config', ->
      assert framework.isDeviceInConfig deviceConfig.id

    it 'should not find antother actuator in config', ->
      assert not framework.isDeviceInConfig 'a-not-present-id'


  describe '#updateDeviceConfig()', ->

    deviceConfigNew = 
      id: 'test-actuator'
      class: 'TestActuatorClass'
      test: 'bla'


    it 'should update actuator in config', ->
      framework.updateDeviceConfig deviceConfigNew
      assert framework.config.devices[0].test is 'bla'

