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
          let wishNftOwner: WishNft
          let vrfCoordinatorV2Mock: VRFCoordinatorV2Mock
          let mintFee: BigNumber
          let accounts: SignerWithAddress[]
          let deployer: SignerWithAddress
          let player: SignerWithAddress

          beforeEach(async () => {
              accounts = await ethers.getSigners()
              deployer = accounts[0]
              player = accounts[1]
              await deployments.fixture(["mocks", "wish"])
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
              wishNftContract = await ethers.getContract("WishNft")
              wishNftOwner = wishNftContract.connect(deployer)
              wishNftPlayer = wishNftContract.connect(player)
              mintFee = await wishNftPlayer.getMintFee()
              await wishNftOwner.mintSwitch(true)
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
                  await wishNftOwner.mintSwitch(false)
                  await expect(
                      wishNftPlayer.wishBannerNft({ value: mintFee.toString() })
                  ).to.be.revertedWithCustomError(wishNftOwner, "WishNft__MintSwitchedOffbyOwner")
              })
              it("fails if not enought ETH sent", async () => {
                  await expect(wishNftPlayer.wishBannerNft()).to.be.revertedWithCustomError(
                      wishNftPlayer,
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
              it("triggers", async () => {
                  await new Promise<void>(async (resolve, reject) => {
                      wishNftPlayer.once("NftMinted", async () => {
                          try {
                              //   const triggerA = await wishNftPlayer.triggerA()
                              //   const trigger1 = await wishNftPlayer.trigger1()
                              //   const trigger2 = await wishNftPlayer.trigger2()
                              //   const trigger3 = await wishNftPlayer.trigger3()
                              //   const trigger4 = await wishNftPlayer.trigger4()
                              const star3 = await wishNftPlayer.getThreeStarCounter()
                              const star4 = await wishNftPlayer.getFourStarCounter()
                              const star5 = await wishNftPlayer.getFiveStarCounter()
                              const wishCounter = await wishNftPlayer.getWishCounter()
                              const tokenCounter = await wishNftPlayer.getTokenCounter()
                              //   console.log(`triggerA is: ${triggerA}`)
                              //   console.log(`trigger1 is: ${trigger1}`)
                              //   console.log(`trigger2 is: ${trigger2}`)
                              //   console.log(`trigger3 is: ${trigger3}`)
                              //   console.log(`trigger4 is: ${trigger4}`)
                              console.log(`star3 is: ${star3}`)
                              console.log(`star4 is: ${star4}`)
                              console.log(`star5 is: ${star5}`)
                              console.log(`wishCounter is: ${wishCounter}`)
                              console.log(`tokenCounter is: ${tokenCounter}`)

                              assert.equal(tokenCounter.toString(), "11")
                              resolve()
                          } catch (e) {
                              console.log(e)
                              reject(e)
                          }
                      })
                      try {
                          for (let i = 0; i < 11; i++) {
                              const requestNftResponse = await wishNftPlayer.wishBannerNft({
                                  value: mintFee.toString(),
                              })
                              const requestNftReceipt = await requestNftResponse.wait(1)
                              await vrfCoordinatorV2Mock.fulfillRandomWords(
                                  requestNftReceipt.events![1].args!.requestId,
                                  wishNftPlayer.address
                              )
                          }
                      } catch (e) {
                          console.log(e)
                          reject(e)
                      }
                  })
              })

              describe("withdraw", async () => {
                  it("only owner can withdraw", async () => {
                      await wishNftOwner.withdraw()
                      const balance = await ethers.provider.getBalance(wishNftContract.address)
                      assert.equal(balance.toString(), "0")
                  })
              })
          })
      })
