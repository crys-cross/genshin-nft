import { storeImages, storeTokenUriMetadata } from "../utils/uploadToPinata"
import "dotenv/config"

const imagesLocation = "./images/star3"
const metadataTemplate = {
    name: "",
    image: "",
    attributes: [
        {
            max_hp: 890,
            atk: 90,
            def: 90,
            elemental_mastery: 0,
            max_stamina: 224,
        },
    ],
}

let tokenUris: any[] = []

const pinataUpload4Stars = async () => {
    //get the IPFS hashes ofour images(Methods below)
    //1. With our IPFS node. https://docs.ipfs.io/
    //2. pinata https://www.pinata.cloud/   pinata-node-sdk
    //3. nft.storage(uses filecoin network) https://nft.storage/
    console.log(test)
    await storeImages(imagesLocation)
    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris()
    }
}

// await storeImages(imagesLocation)

const handleTokenUris = async () => {
    // Check out https://github.com/PatrickAlphaC/nft-mix for a pythonic version of uploading
    // to the raw IPFS-daemon from https://docs.ipfs.io/how-to/command-line-quick-start/
    // You could also look at pinata https://www.pinata.cloud/
    // tokenUris = []
    //store the image in IPFS
    //store the metadata in IPFS
    const { responses: imageUploadResponses, files } = await storeImages(imagesLocation)
    for (const imageUploadResponseIndex in imageUploadResponses) {
        //create metadata
        //upload the metadata
        let tokenUriMetadata = { ...metadataTemplate } //... unpack
        tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".png", "")
        // tokenUriMetadata.description = `An adorable ${tokenUriMetadata.name}`
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`
        console.log(`Uploading ${tokenUriMetadata.name}...`)
        // store the JSON to pinata/IPFS
        const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata)
        tokenUris.push(`ipfs://${metadataUploadResponse!.IpfsHash}`)
    }
    console.log("Token URIs for 3star Uploaded! They are:")
    console.log(tokenUris)
    return tokenUris
}
