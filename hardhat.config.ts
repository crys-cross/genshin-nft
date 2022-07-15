import "@typechain/hardhat"
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "hardhat-deploy"
import "solidity-coverage"
import "hardhat-gas-reporter"
import "hardhat-contract-sizer"
import "dotenv/config"
import { HardhatUserConfig } from "hardhat/config"

const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

const config: HardhatUserConfig = {
    // solidity: "0.8.8",
    solidity: {
        compilers: [{ version: "0.8.8" }, { version: "0.8.4" }, { version: "0.6.6" }],
    },
    defaultNetwork: "hardhat",
    networks: {
        rinkeby: {
            url: RINKEBY_RPC_URL || "",
            accounts: [PRIVATE_KEY],
            chainId: 4,
        },
    },
    gasReporter: {
        enabled: true,
        outputFile: "gas-report.txt",
        noColors: true,
        currency: "USD",
        coinmarketcap: COINMARKETCAP_API_KEY,
        token: "ETH",
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
        user: {
            default: 1,
        },
    },
}
export default config
