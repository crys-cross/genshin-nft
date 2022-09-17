import { ethers, network } from "hardhat"
import { moveBlocks } from "../utils/move-blocks"

const PRICE = ethers.utils.parseEther("0.1")
const sleepAmount = 1000

const mint = async () => {
    const wishNft = await ethers.getContract("WishNft")
    const mintFee = await wishNft.getMintFee()
    await wishNft.mintSwitch(true)
    console.log("Minting...")
    const mintTx = await wishNft.wishBannerNft({ value: mintFee })
    const mintTxReceipt = await mintTx.wait(1)
    const event = mintTxReceipt.events[1]
    const value = event.args[0]
    const minted = value.toString()
    // console.log(
    //     `Minted tokenId ${mintTxReceipt.events[1].arg.playersCharacter} from contract: ${wishNft.address}`
    // )
    console.log(`Minted tokenId ${minted} from contract: ${wishNft.address}`)

    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 at once!
        await moveBlocks(2, sleepAmount)
    }

    const triggerA = await wishNft.getTriggerA()
    const trigger1 = await wishNft.getTrigger1()
    const trigger2 = await wishNft.getTrigger2()
    const trigger3 = await wishNft.getTrigger3()
    const trigger4 = await wishNft.getTrigger4()
    const wishCounter = await wishNft.getWishCounter()
    const counter = await wishNft.getTokenCounter()
    console.log(`triggerA is: ${triggerA}`)
    console.log(`trigger1 is: ${trigger1}`)
    console.log(`trigger2 is: ${trigger2}`)
    console.log(`trigger3 is: ${trigger3}`)
    console.log(`trigger4 is: ${trigger4}`)
    console.log(`wishCounter is: ${wishCounter}`)
    console.log(`counter is: ${counter}`)
}

mint()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
