// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error WishNft__NeedMoreETHSennt();

contract Wish is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // Types
    // 4star rate up 20%[ rosaria, beidou , sayu] and 10%[ lisa, amber, barbara, noelle]
    //Replace Characters
    enum FourStars {
        ROSARIA,
        BEIDOU,
        SAYU,
        LISA,
        AMBER,
        BARBARA,
        NOELLE
    }
    // 1 event 5star(%)[kusanali] and 5 regular 5stars[lumine, qiqi, yae, mona, ayayaka]
    //Replace Characters
    enum FiveStars {
        KUSANALI,
        LUMINE,
        QIQI,
        YAE,
        MONA,
        AYAYAKA
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 3;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;
    mapping(uint256 => address) public s_playersWishCounter;

    // NFT Variables
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 internal immutable i_mintFee;
    string[] internal s_5starUris;
    string[] internal s_4starUris;
    string[] internal s_3starUris;
    uint256 public wishCounter;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval,
        string[6] memory fiveStarUris,
        string[7] memory fourStarUris,
        string[] memory threeStarUris
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("GENSHIN NFT", "GI") {
        // i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function wishBannerNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert WishNft__NeedMoreETHSennt();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    //if wishCounter = 90 {run function 5star()}
    //if wishCounter % 10 {run function check 4star(98)5star(2)}
    //if wishCounter > 75 && % 10 != 10 {uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
    // run function check 5star(1%), 4star(5%), 3star(94%) }

    // randomWords[0]- check
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address myPlayerAddress = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Character playersCharacter = getCharacterFromModdedRng(moddedRng);
        _safeMint(myPlayerAddress, newItemId);
        _setTokenURI(newItemId, s_playersTokenUris[uint256(playersCharacter)]);
        emit NftMinted(playersCharacter, myPlayerAddress);
    }

    //1% 5star, 5% 4star, 94% 3star
    function getRegular4Star() public pure returns (uint256[7] memory) {
        return [20, 40, 60, 70, 80, 90, MAX_CHANCE_VALUE];
    }

    function getRegular5Star() public pure returns (uint256[6] memory) {
        return [50, 60, 70, 80, 90, MAX_CHANCE_VALUE];
    }

    //wishCounter -75 = increase rate
    function getSoftPityChance() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    // guaranteed 5 star and reset wishCounter
    function getHardPityChance() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    //function to check 4(5), 5(1) or 3(94) star(for regular)
    function getCheckRegular(uint256 moddedRng) public pure returns (uint256) {
        if (moddedRng > 2) {
            get5StarRng(moddedRng);
        } else if (moddedRng > 6) {
            get4StarRng(moddedRng);
        } else {
            return 3;
        }
    }

    //function to check 4(98) or 5(2) star(for 10 pulls)
    function getCheck10(uint256 moddedRng) public pure returns (uint256) {
        if (moddedRng > 3) {
            get5StarRng(moddedRng);
        } else {
            return 3;
        }
    }

    // 1 event 5star(%)[kusanali] and 5 regular 5stars[lumine, qiqi, yae, mona, ayayaka]
    function get5StarRng(uint256 moddedRng) public pure returns (FourStars) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getRegular4Star();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return FourStars(i);
            }
            // cumulativeSum = cumulativeSum + chanceArray[i];
            cumulativeSum = chanceArray[i];
        }
        revert RangeOutOfBounds();
    }

    // 4star rate up 20%[ rosaria, beidou , sayu] and 10%[ lisa, amber, barbara, noelle]
    function get4StarRng(uint256 moddedRng) public pure returns (FiveStars) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getRegular5Star();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return FiveStars(i);
            }
            // cumulativeSum = cumulativeSum + chanceArray[i];
            cumulativeSum = chanceArray[i];
        }
        revert RangeOutOfBounds();
    }
}

//TODO
//track players pulls(mapping or array)(wishCounter mapping)
//guaranteeed 4/5star every 10th pull(2%-4star 98%-3star)
// wishcounter resets if 5star drawn or 90th pull(since gauranteed 5star)
//1%-5star 5%-4star 94%-3star
//randomWords[0] random 3-5star
//randomWords[1] (choose from 4star)(choose from 5star)
