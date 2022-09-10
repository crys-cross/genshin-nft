import {
    developmentChains,
    networkConfig,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config"
import verify from "../utils/verify"
import { storeImages, storeTokenUriMetadata } from "../utils/uploadToPinata"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const FUND_AMOUNT = "1000000000000000000000" //10 LINK ethers.parseUnit
const imagesLocation = "./images/star5"
// 3star metadata
// const metadataTemplate = {
//     name: "",
//     image: "",
//     attributes: [
//         {
//             max_hp: 890,
//             atk: 90,
//             def: 90,
//             elemental_mastery: 0,
//             max_stamina: 224,
//         },
//     ],
// }
// 4 star metadata
// const metadataTemplate = {
//     name: "",
//     description: "",
//     image: "",
//     attributes: [
//         {
//             max_hp: 900,
//             atk: 100,
//             def: 90,
//             elemental_mastery: 0,
//             max_stamina: 224,
//         },
//     ],
// }
// 5 star metadata
const metadataTemplate = {
    name: "",
    image: "",
    attributes: [
        {
            max_hp: 910,
            atk: 110,
            def: 90,
            elemental_mastery: 0,
            max_stamina: 224,
        },
    ],
}

let tokenUris: any[] = [
    "ipfs://QmSL1Yuc7KDUEH19WSDNHZ9F9rRBe4ytMcUjEvx26HrUDr",
    "ipfs://QmYH4cbQGG6EyPAyCEkbjDxVRc8cBUTYYAUYGHF8yRBH9F",
    "ipfs://QmPx84b3RaN1mNvS8GvtsTy49q88gJRKrdpmrXAVvVybRt",
    "ipfs://QmeKAmcMhZfPRWp9n2b85BDXHMP2KwxuJ5GjYkWgRsKUnL",
    "ipfs://QmaPgGv7U5RtN8Zo8ZN666KAbTiVhT35A5WHeBSmK3n4Tf",
    "ipfs://Qmd9EAuRzpENHnfN6JGatNVRPDpb2sSba2pgHDveLnRN8z",
    "ipfs://QmZrvCoSSUQcgNH1YkfnXRBkEuJV85DnoRuFEcy9Xqs735",
    "ipfs://QmbE1zNDYop49mCQNJmSwALDeEEyWYrgX2QaFUhBdSU3eh",
    "ipfs://Qmbt3boXCRdczkeKsYy9u11hThnkMtm66vDbpZkWLoSEy4",
    "ipfs://QmYaQnbnW7WfA6tNTKYoke5i74MedfL67onH39SLFsDDTf",
    "ipfs://QmQpDzekoy5vndA3ZkedCjCawMHHq26YV5QDuFbQD8NArU",
    "ipfs://QmYCLATGQX2BrThdMdRXT4qW6dW4BKGVvpBRVaaixGLnrW",
    "ipfs://QmRH2f4et7sJWyjDni5Wm3Anb47tg22E1dGWZNxv2ADggk",
    "ipfs://QmTokSvr7SPnvsdDCXT9nSWAb2jmXr8ySiXAhzPq9x4pSw",
]

const deployWishNft: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { getNamedAccounts, deployments, network, ethers } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId!

    let vrfCoordinatorV2Address, subscriptionId

    //get the IPFS hashes ofour images(Methods below)
    //1. With our IPFS node. https://docs.ipfs.io/
    //2. pinata https://www.pinata.cloud/   pinata-node-sdk
    //3. nft.storage(uses filecoin network) https://nft.storage/
    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris()
    }

    if (developmentChains.includes(network.name)) {
        const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
        const tx = await vrfCoordinatorV2Mock.createSubscription()
        const txReceipt = await tx.wait(1)
        subscriptionId = txReceipt.events[0].args.subId
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, FUND_AMOUNT)
    } else {
        vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
        subscriptionId = networkConfig[chainId].subscriptionId
    }

    // const waitBlockConfirmations = developmentChains.includes(network.name)
    const waitBlockConfirmations = chainId == 31337 ? 1 : VERIFICATION_BLOCK_CONFIRMATIONS

    log("----------------------------")
    // await storeImages(imagesLocation)
    const args = [
        vrfCoordinatorV2Address,
        networkConfig[chainId]["mintFee"],
        subscriptionId,
        networkConfig[chainId]["gasLane"],
        networkConfig[chainId]["callbackGasLimit"],
        tokenUris,
    ]

    const wishNft = await deploy("WishNft", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: waitBlockConfirmations || 1,
    })
    log("--------------------------------")
    if (chainId != 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(wishNft.address, args)
    }
}

const handleTokenUris = async () => {
    // Check out https://github.com/PatrickAlphaC/nft-mix for a pythonic version of uploading
    // to the raw IPFS-daemon from https://docs.ipfs.io/how-to/command-line-quick-start/
    // You could also look at pinata https://www.pinata.cloud/
    tokenUris = []
    //store the image in IPFS
    //store the metadata in IPFS
    const { responses: imageUploadResponses, files } = await storeImages(imagesLocation)
    for (const imageUploadResponseIndex in imageUploadResponses) {
        //create metadata
        //upload the metadata
        let tokenUriMetadata = { ...metadataTemplate } //... unpack
        tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".png", "")
        // tokenUriMetadata.description = `An adorable ${tokenUriMetadata.name} pup!`
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`
        console.log(`Uploading ${tokenUriMetadata.name}...`)
        // store the JSON to pinata/IPFS
        const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata)
        tokenUris.push(`ipfs://${metadataUploadResponse!.IpfsHash}`)
    }
    console.log("Token URIs Uploaded! They are:")
    console.log(tokenUris)
    return tokenUris
}
export default deployWishNft
deployWishNft.tags = ["all", "wish", "main"]

// Lumine
// 'ipfs://QmSL1Yuc7KDUEH19WSDNHZ9F9rRBe4ytMcUjEvx26HrUDr'

//  Rosaria
// 'ipfs://Qma6xfVbp1PTAn3xdAnE2aKe4fUMLsm9SA5LEwSAQkQUz6',
// Beidou
// 'ipfs://QmPx84b3RaN1mNvS8GvtsTy49q88gJRKrdpmrXAVvVybRt',
//  Sayu
// 'ipfs://QmeKAmcMhZfPRWp9n2b85BDXHMP2KwxuJ5GjYkWgRsKUnL'
//  Lisa
// 'ipfs://QmaPgGv7U5RtN8Zo8ZN666KAbTiVhT35A5WHeBSmK3n4Tf',
//  Ningguang
// 'ipfs://Qmd9EAuRzpENHnfN6JGatNVRPDpb2sSba2pgHDveLnRN8z',
// Barbara...
// 'ipfs://QmZrvCoSSUQcgNH1YkfnXRBkEuJV85DnoRuFEcy9Xqs735',
//  Noelle
// 'ipfs://QmbE1zNDYop49mCQNJmSwALDeEEyWYrgX2QaFUhBdSU3eh',

//  Kusanali
// 'ipfs://QmUVLbL9y3HSeb2BQijzUWbUmDbFKPNcZQKxZVnG6xoP5J',
//  Kokomi
// 'ipfs://QmYaQnbnW7WfA6tNTKYoke5i74MedfL67onH39SLFsDDTf',
//  Qiqi
// 'ipfs://QmQpDzekoy5vndA3ZkedCjCawMHHq26YV5QDuFbQD8NArU',
//  Zhongli
// 'ipfs://QmYCLATGQX2BrThdMdRXT4qW6dW4BKGVvpBRVaaixGLnrW'
//  Hutao
// 'ipfs://QmRH2f4et7sJWyjDni5Wm3Anb47tg22E1dGWZNxv2ADggk',
// Ayaka
// 'ipfs://QmTokSvr7SPnvsdDCXT9nSWAb2jmXr8ySiXAhzPq9x4pSw',
