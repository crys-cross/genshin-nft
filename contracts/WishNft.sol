// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error WishNft__NeedMoreETHSennt();
error WishNft__RangeOutOfBounds();
error WishNft__AlreadyInitialized();
error WishNft__TransferFailed();
error WishNft__MintSwitchedOffbyOwner();

contract WishNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // Types
    // 4star rate up 20%[ rosaria, beidou , sayu] and 10%[ lisa, ningguang, barbara, noelle]
    // 1 event 5star(%)[kusanali] and 5 regular 5stars[KOKOMI, qiqi, yae, hutao, ayayaka]
    // Characters[0]-3stars, Characters[1-7]-4stars, Characters[8-13]-5stars
    enum Characters {
        LUMINE,
        ROSARIA,
        BEIDOU,
        SAYU,
        LISA,
        NINGGUANG,
        BARBARA,
        NOELLE,
        KUSANALI,
        KOKOMI,
        QIQI,
        ZHONGLI,
        HUTAO,
        AYAKA
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;
    // mapping(address => uint256) public s_playersWishCounter;

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_characterUris;
    bool private s_initialized;
    uint256 public wishCounter;
    bool public mintEnabled;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Characters playersCharacter, address characterOwner);

    constructor(
        address vrfCoordinatorV2,
        uint256 mintFee,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        string[14] memory characterUris
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("GENSHIN NFT", "GI") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_mintFee = mintFee;
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        _initializeContract(characterUris);
    }

    function wishBannerNft() public payable returns (uint256 requestId) {
        if (mintEnabled == false) {
            revert WishNft__MintSwitchedOffbyOwner();
        }
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
        address characterOwner = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng1 = randomWords[0] % MAX_CHANCE_VALUE;
        uint256 moddedRng2 = randomWords[0] % MAX_CHANCE_VALUE;
        Characters playersCharacter;
        if (wishCounter == 90) {
            playersCharacter = getHardPityCharacter(moddedRng2);
        } else if (wishCounter % 100 == 10) {
            playersCharacter = get10thRateCharacter(moddedRng1, moddedRng2);
        } else if (wishCounter < 75) {
            playersCharacter = getRegularCharacter(moddedRng1, moddedRng2);
        } else {
            playersCharacter = getSoftPityCharacter(moddedRng1, moddedRng2);
        }
        s_tokenCounter += s_tokenCounter;
        if (uint256(playersCharacter) > 7) {
            wishCounter = 0;
        } else {
            wishCounter += 1;
        }
        _safeMint(characterOwner, newItemId);
        _setTokenURI(newItemId, s_characterUris[uint256(playersCharacter)]);
        emit NftMinted(playersCharacter, characterOwner);
    }

    //1% 5star, 5% 4star, 94% 3star
    function get4StarChanceArray() public pure returns (uint256[7] memory) {
        return [20, 40, 60, 70, 80, 90, MAX_CHANCE_VALUE];
    }

    function get5StarChanceArray() public pure returns (uint256[6] memory) {
        return [50, 60, 70, 80, 90, MAX_CHANCE_VALUE];
    }

    function getHardPityCharacter(uint256 moddedRng2) public pure returns (Characters) {
        uint256 indexNumber;
        uint256[6] memory chanceArrayFiveStars = get5StarChanceArray();
        for (uint256 i = 0; i < chanceArrayFiveStars.length; i++) {
            // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
            if (moddedRng2 <= chanceArrayFiveStars[i]) {
                indexNumber = i + 8;
                return Characters(indexNumber);
            }
        }

        revert WishNft__RangeOutOfBounds();
    }

    function get10thRateCharacter(uint256 moddedRng1, uint256 moddedRng2)
        public
        pure
        returns (Characters)
    {
        uint256 indexNumber;
        uint256[7] memory chanceArrayFourStars = get4StarChanceArray();
        uint256[6] memory chanceArrayFiveStars = get5StarChanceArray();
        if (moddedRng1 % 100 < 99) {
            for (uint256 i = 0; i < chanceArrayFourStars.length; i++) {
                // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 1;
                    return Characters(indexNumber);
                }
            }
        } else {
            for (uint256 i = 0; i < chanceArrayFiveStars.length; i++) {
                // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                if (moddedRng2 <= chanceArrayFiveStars[i]) {
                    indexNumber = i + 8;
                    return Characters(indexNumber);
                }
            }
        }
        revert WishNft__RangeOutOfBounds();
    }

    function getRegularCharacter(uint256 moddedRng1, uint256 moddedRng2)
        public
        pure
        returns (Characters)
    {
        uint256 indexNumber;
        uint256[7] memory chanceArrayFourStars = get4StarChanceArray();
        uint256[6] memory chanceArrayFiveStars = get5StarChanceArray();
        if (moddedRng1 % 100 < 95) {
            indexNumber = 0;
            return Characters(indexNumber);
        } else if (moddedRng1 % 100 < 100) {
            // for (uint256 i = 0; i < chanceArrayFourStars.length; i++) {
            // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
            for (uint256 i = 0; i < chanceArrayFourStars.length; i++) {
                // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 9;
                    return Characters(indexNumber);
                }
            }
        } else if (moddedRng1 % 100 > 99) {
            for (uint256 i = 0; i < chanceArrayFiveStars.length; i++) {
                // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 9;
                    return Characters(indexNumber);
                }
            }
        }
        revert WishNft__RangeOutOfBounds();
    }

    function getSoftPityCharacter(uint256 moddedRng1, uint256 moddedRng2)
        public
        view
        returns (Characters)
    {
        uint256 indexNumber;
        uint256[7] memory chanceArrayFourStars = get4StarChanceArray();
        uint256[6] memory chanceArrayFiveStars = get5StarChanceArray();
        uint256 rateValue = wishCounter - 74;
        if (moddedRng1 % 100 < (95 - (rateValue * 2))) {
            indexNumber = 0;
            return Characters(indexNumber);
        } else if (moddedRng1 % 100 < 100) {
            for (uint256 i = 0; i < chanceArrayFourStars.length; i++) {
                // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 1;
                    return Characters(indexNumber);
                }
            }
        } else if (moddedRng1 % 100 >= (100 - (rateValue * 2))) {
            for (uint256 i = 0; i < chanceArrayFiveStars.length; i++) {
                // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 9;
                    return Characters(indexNumber);
                }
            }
        }
        revert WishNft__RangeOutOfBounds();
    }

    function mintSwitch(bool _mintEnabled) external onlyOwner {
        mintEnabled = _mintEnabled; //it allows us to change true or false
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert WishNft__TransferFailed();
        }
    }

    function _initializeContract(string[14] memory characterUris) private {
        if (s_initialized) {
            revert WishNft__AlreadyInitialized();
        }
        s_characterUris = characterUris;
        s_initialized = true;
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getCharacterUris(uint256 index) public view returns (string memory) {
        return s_characterUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getWishCounter() public view returns (uint256) {
        return wishCounter;
    }
}

//TODO
//track players pulls(mapping or array)(wishCounter mapping)
//guaranteeed 4/5star every 10th pull(2%-4star 98%-3star)
// wishcounter resets if 5star drawn or 90th pull(since gauranteed 5star)
//1%-5star 5%-4star 94%-3star
//randomWords[0] random 3-5star
//randomWords[1] (choose from 4star)(choose from 5star)
