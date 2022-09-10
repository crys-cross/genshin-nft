import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"
import { assert, expect } from "chai"
import { getNamedAccounts, deployments, ethers, network } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { WishNft, VRFCoordinatorV2Mock } from "../../typechain-types"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("WishNft Unit Test", () => {
          let wishNftPlayer: WishNft
          let wishNftContract: WishNft
          let wishNftDeployer: WishNft
          let vrfCoordinatorV2Mock: VRFCoordinatorV2Mock
          let mintFee: BigNumber
          let accounts: SignerWithAddress[]
          let deployer: SignerWithAddress
          let player: SignerWithAddress

          beforeEach(async () => {
              accounts = await ethers.getSigners() //could also be done with getNamedAccounts
              deployer = accounts[0]
              player = accounts[1]
              await deployments.fixture(["mocks", "wish"])
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
              wishNftContract = await ethers.getContract("LotteryTrio")
              wishNftDeployer = wishNftContract.connect(deployer)
              wishNftPlayer = wishNftContract.connect(player)
              mintFee = await wishNftPlayer.getMintFee()
              await wishNftDeployer.mintSwitch(true)
          })
          describe("constructor", async () => {
              it("sets starting values correctly", async () => {
                  const characterUriZero = await wishNftPlayer.getCharacterUris(0)
                  const isInitialized = await wishNftPlayer.getInitialized()
                  assert(characterUriZero.includes("ipfs://"))
                  assert.equal(isInitialized, true)
              })
          })
          describe("wishBannerNft", async () => {
              it("fails if mintSwitch is disabled", async () => {
                  await wishNftDeployer.mintSwitch(false)
                  await expect(
                      wishNftPlayer.wishBannerNft({ value: mintFee.toString() })
                  ).to.be.revertedWith("WishNft__MintSwitchedOffbyOwner")
              })
              it("fails if not enought ETH sent", async () => {
                  await expect(wishNftPlayer.wishBannerNft()).to.be.revertedWith(
                      "WishNft__NeedMoreETHSennt"
                  )
              })
          })
          describe("fulfillRandomWords", async () => {
              it("mints NFT after random number is returned", async () => {
                  await new Promise<void>(async (resolve, reject) => {
                      wishNftPlayer.once("NftMinted", async () => {
                          try {
                              const tokenUri = await wishNftPlayer.tokenURI(0)
                              const tokenCounter = await wishNftPlayer.getTokenCounter()
                              assert.equal(tokenUri.toString().includes("ipfs://"), true)
                              assert.equal(tokenCounter.toString(), "1")
                              resolve()
                          } catch (e) {
                              console.log(e)
                              reject(e)
                          }
                      })
                      try {
                          const requestNftResponse = await wishNftPlayer.wishBannerNft({
                              value: mintFee.toString(),
                          })
                          const requestNftReceipt = await requestNftResponse.wait(1)
                          await vrfCoordinatorV2Mock.fulfillRandomWords(
                              requestNftReceipt.events![1].args!.requestId,
                              wishNftPlayer.address
                          )
                      } catch (e) {
                          console.log(e)
                          reject(e)
                      }
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
      })
