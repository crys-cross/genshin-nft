import { ethers, network } from "hardhat"
import { moveBlocks } from "../utils/move-blocks"

const mintSwitch = async () => {
    const wishNft = await ethers.getContract("WishNft")
    const mintSwitch = await wishNft.mintSwitch(true)
    console.log(mintSwitch)
}

mintSwitch()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
