Helper = require 'hubot-test-helper'
chai = require 'chai'
sinon = require 'sinon'

expect = chai.expect

cronJobs = []

class CronJob
  constructor: (pattern, fun)->
    cronJobs.push(fun)

cronMock =
  CronJob: CronJob

Module = require('module')
originalRequire = Module.prototype.require

Module.prototype.require = () ->
  if arguments[0] == 'cron'
    return cronMock

  return originalRequire.apply(this, arguments)


helper = new Helper('../scripts/standup.coffee')
sinon.stub(Math, 'random').returns(0.0)

describe 'standup', ->
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()
    if @clock
      @clock.restore()
    cronJobs = []

  it 'is alive', ->

    @room.user.say('alice', '@hubot list standups').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot list standups']
        ['hubot', 'Well this is awkward. You haven\'t got any standups set :-/']
      ]

  it 'allows user to create a standup', ->

    @room.user.say('alice', '@hubot create standup 12:00').then =>
      @room.user.say('alice', '@hubot list standups').then =>
        @room.user.say('alice', '@hubot list all standups').then =>
          expect(@room.messages).to.eql [
            ['alice', '@hubot create standup 12:00']
            ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 UTC']
            ['alice', '@hubot list standups']
            ['hubot', 'Here\'s your standups:\nTime: 12:00 UTC']
            ['alice', '@hubot list all standups']
            ['hubot', 'Here\'s the standups for every room:\nRoom: room1, time: 12:00 UTC']
          ]

  it 'allows user to create a standup in local timezone', ->

    @room.user.say('alice', '@hubot create standup 12:00 Europe/Warsaw').then =>
      @room.user.say('alice', '@hubot list standups').then =>
        expect(@room.messages).to.eql [
          ['alice', '@hubot create standup 12:00 Europe/Warsaw']
          ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 Europe/Warsaw']
          ['alice', '@hubot list standups']
          ['hubot', 'Here\'s your standups:\nTime: 12:00 Europe/Warsaw']
        ]

  it 'handles invalid time', ->

    @room.user.say('alice', '@hubot create standup 12:60').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup 12:60']
        ['hubot', 'Sorry, but I couldn\'t find a time to create the standup at.']
      ]

  it 'allows user to delete all standups in room', ->

    @room.user.say('alice', '@hubot create standup 12:00').then =>
      @room.user.say('alice', '@hubot delete all standups').then =>
        @room.user.say('alice', '@hubot list standups').then =>
          expect(@room.messages).to.eql [
            ['alice', '@hubot create standup 12:00']
            ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 UTC']
            ['alice', '@hubot delete all standups']
            ['hubot', 'Deleted 1 standup for room1']
            ['alice', '@hubot list standups']
            ['hubot', 'Well this is awkward. You haven\'t got any standups set :-/']
          ]

  it 'allows user to delete specific standup', ->
    @room.user.say('alice', '@hubot create standup 12:00').then =>
      @room.user.say('alice', '@hubot create standup 13:00').then =>
        @room.user.say('alice', '@hubot delete standup 12:00').then =>
          @room.user.say('alice', '@hubot list standups').then =>
            expect(@room.messages).to.eql [
              ['alice', '@hubot create standup 12:00']
              ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 UTC']
              ['alice', '@hubot create standup 13:00']
              ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 13:00 UTC']
              ['alice', '@hubot delete standup 12:00']
              ['hubot', 'Deleted your 12:00 standup.']
              ['alice', '@hubot list standups']
              ['hubot', 'Here\'s your standups:\nTime: 13:00 UTC']
            ]

  it 'can show its help', ->

    @room.user.say('alice', '@hubot help standup').then =>
      expect(@room.messages[1][1]).to.match /I can remind you/

  it 'reminds about the standups', ->

    @room.user.say('alice', '@hubot create standup 12:00 at place').then =>
      # 2016-12-19 12:00 UTC
      @clock = sinon.useFakeTimers(1482148800000)
      (job() for job in cronJobs)
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup 12:00 at place']
        ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 UTC, location: at place']
        ['hubot', ' Standup time! at place']
      ]

  it 'reminds about the standups in given timezone', ->

    @room.user.say('alice', '@hubot create standup 12:00 Europe/Warsaw').then =>
      # 2016-06-19 10:00 UTC
      @clock = sinon.useFakeTimers(1466330400000)
      (job() for job in cronJobs)
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup 12:00 Europe/Warsaw']
        ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 Europe/Warsaw']
        ['hubot', ' Standup time! ']
      ]

  it 'reminds about the standups in given timezone with DST', ->

    @room.user.say('alice', '@hubot create standup 12:00 Europe/Warsaw').then =>
      # 2016-12-19 11:00 UTC
      @clock = sinon.useFakeTimers(1482145200000)
      (job() for job in cronJobs)
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup 12:00 Europe/Warsaw']
        ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 12:00 Europe/Warsaw']
        ['hubot', ' Standup time! ']
      ]

  it 'reminds about the standups in given timezone over day boundary', ->

    @room.user.say('alice', '@hubot create standup 01:00 Europe/Warsaw').then =>
      # 2016-06-18 23:00 UTC
      @clock = sinon.useFakeTimers(1466290800000)
      (job() for job in cronJobs)
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup 01:00 Europe/Warsaw']
        ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 01:00 Europe/Warsaw']
        ['hubot', ' Standup time! ']
      ]

  it 'reminds about the standups in given timezone on given day over day boundary', ->

    @room.user.say('alice', '@hubot create standup Monday@01:00 Europe/Warsaw').then =>
      # 2016-06-19 23:00 UTC
      @clock = sinon.useFakeTimers(1466377200000)
      (job() for job in cronJobs)
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup Monday@01:00 Europe/Warsaw']
        ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every Monday at 01:00 Europe/Warsaw']
        ['hubot', ' Standup time! ']
      ]

  it 'reminds about the standups in Nepal', ->

    @room.user.say('alice', '@hubot create standup 02:00 Asia/Kathmandu').then =>
      # 2016-12-19 20:15 UTC
      @clock = sinon.useFakeTimers(1482178500000)
      (job() for job in cronJobs)
      expect(@room.messages).to.eql [
        ['alice', '@hubot create standup 02:00 Asia/Kathmandu']
        ['hubot', 'Ok, from now on I\'ll remind this room to do a standup every weekday at 02:00 Asia/Kathmandu']
        ['hubot', ' Standup time! ']
      ]
