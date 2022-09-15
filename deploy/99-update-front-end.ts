import "dotenv/config"
import fs from "fs"
import { ethers, network } from "hardhat"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const frontEndContractsFile = "../genshinnft-frontend/constants/networkAddresses.json"
const frontEndAbiFile = "../genshinnft-frontend/constants/genshinNftAbi.json"

const updateUI: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Updating Front End")
        const wishNft = await ethers.getContract("WishNft")
        const chainId = network.config.chainId!.toString()
        const currentAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
        if (chainId in currentAddresses) {
            if (!currentAddresses[chainId]["WishNft"].includes(wishNft.address)) {
                currentAddresses[chainId]["WishNft"].push(wishNft.address)
            }
        } else {
            currentAddresses[chainId] = { WishNft: [wishNft.address] }
        }
        fs.writeFileSync(frontEndContractsFile, JSON.stringify(currentAddresses))
        console.log("Addresses written!")
        fs.writeFileSync(
            frontEndAbiFile,
            wishNft.interface.format(ethers.utils.FormatTypes.json).toString()
        )
        console.log("ABI written!")
        console.log("Front end written!")
    }
}
// const updateContractAddresses = async () => {
//     const wishNft = await ethers.getContract("WishNft")
//     const chainId = network.config.chainId!.toString()
//     const currentAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
//     if (chainId in currentAddresses) {
//         if (!currentAddresses[chainId]["WishNft"].includes(wishNft.address)) {
//             currentAddresses[chainId]["WishNft"].push(wishNft.address)
//         }
//     } else {
//         currentAddresses[chainId] = { WishNft: [wishNft.address] }
//     }
//     fs.writeFileSync(frontEndContractsFile, JSON.stringify(currentAddresses))
//     console.log("Addresses written!")
// }
// const updateAbi = async () => {
//     const wishNft = await ethers.getContract("WishNft")
//     fs.writeFileSync(
//         frontEndAbiFile,
//         wishNft.interface.format(ethers.utils.FormatTypes.json).toString()
//     )
//     console.log("ABI written!")
// }

export default updateUI
updateUI.tags = ["all", "frontend"]
