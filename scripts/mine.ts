import { moveBlocks } from "../utils/move-blocks"
const BLOCKS = 2
const SLEEP_AMOUNT = 1000

const mine = async () => {
    await moveBlocks(BLOCKS, SLEEP_AMOUNT)
}

mine()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
