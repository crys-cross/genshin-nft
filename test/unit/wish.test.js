const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers, network } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Raffle Unit Test", () => {
          let raffle, VRFCoordinatorV2Mock, raffleEntranceFee, deployer, interval
          const chainId = network.config.chainId
          beforeEach(async () => {
              //a
          })
          describe("constructor", async () => {
              it("description", async () => {
                  //a
              })
          })
          describe("fulfillRandomWords", async () => {
              it("description", async () => {
                  //a
              })
          })
          describe("getHardPityCharacter", async () => {
              it("description", async () => {
                  //a
              })
          })
          describe("get10thRateCharacter", async () => {
              it("description", async () => {
                  //a
              })
          })
          describe("getRegularCharacter", async () => {
              it("description", async () => {
                  //a
              })
          })
          describe("getSoftPityCharacter", async () => {
              it("description", async () => {
                  //a
              })
          })
          describe("_initializeContract", async () => {
              it("description", async () => {
                  //a
              })
          })
      })
