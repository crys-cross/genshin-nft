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

/**
 *  @title BLOCKCHAIN GENSHIN NFT
 *  @author crys
 *  @notice This is demo smartcontract game using very similar wish mechanics to the Genshin Game
 *  @dev This uses Chainlink VRF for randomizaton and some math
 *  to simulate as close as possible rates to the genshin game.
 *  Characters[0]-3stars, Characters[1-7]-4stars, Characters[8-13]-5stars
 *  4-star rate up 20%[ collei, beidou , sayu] and 10%[ lisa, ningguang, barbara, noelle]
 *  5-star rate up(50%)[nahida] and 5 regular(10% each) 5-stars[kokomi, qiqi, yae, hutao, ayaka]
 **/
contract WishNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // Types
    enum Characters {
        LUMINE,
        COLLEI,
        BEIDOU,
        SAYU,
        LISA,
        NINGGUANG,
        BARBARA,
        NOELLE,
        NAHIDA,
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
    // mapping(address => uint256) public s_playerss_wishCounter;

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_characterUris;
    bool private s_initialized;
    uint256 public s_wishCounter;
    uint256 public s_threeStarCounter;
    uint256 public s_fiveStarCounter;
    uint256 public s_fourStarCounter;
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

    //if s_wishCounter = 90 {run function 5star()}
    //if s_wishCounter % 10 {run function check 4star(98)5star(2)}
    //if s_wishCounter > 75 && % 10 != 10 {uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
    // run function check 5star(1%), 4star(5%), 3star(94%) }
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address characterOwner = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        uint256 moddedRng1 = randomWords[0] % MAX_CHANCE_VALUE;
        uint256 moddedRng2 = randomWords[1] % MAX_CHANCE_VALUE;
        Characters playersCharacter;
        if (s_wishCounter == 90) {
            s_fiveStarCounter += 1;
            playersCharacter = getHardPityCharacter(moddedRng2);
        } else if (s_wishCounter % 100 == 10) {
            playersCharacter = get10thRateCharacter(moddedRng1, moddedRng2);
        } else if (s_wishCounter < 75) {
            playersCharacter = getRegularCharacter(moddedRng1, moddedRng2);
        } else {
            playersCharacter = getSoftPityCharacter(moddedRng1, moddedRng2);
        }
        s_tokenCounter += 1;
        if (uint256(playersCharacter) == 0) {
            s_threeStarCounter += 1;
            s_wishCounter += 1;
        } else if (uint256(playersCharacter) < 8) {
            s_fourStarCounter += 1;
            s_wishCounter += 1;
        } else {
            s_fiveStarCounter += 1;
            s_wishCounter = 0;
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
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 1;
                    return Characters(indexNumber);
                }
            }
        } else {
            for (uint256 i = 0; i < chanceArrayFiveStars.length; i++) {
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
        uint256 rateValue = s_wishCounter - 74;
        if (moddedRng1 % 100 < (95 - (rateValue * 2))) {
            indexNumber = 0;
            return Characters(indexNumber);
        } else if (moddedRng1 % 100 < 100) {
            for (uint256 i = 0; i < chanceArrayFourStars.length; i++) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 1;
                    return Characters(indexNumber);
                }
            }
        } else if (moddedRng1 % 100 >= (100 - (rateValue * 2))) {
            for (uint256 i = 0; i < chanceArrayFiveStars.length; i++) {
                if (moddedRng2 <= chanceArrayFourStars[i]) {
                    indexNumber = i + 9;
                    return Characters(indexNumber);
                }
            }
        }
        revert WishNft__RangeOutOfBounds();
    }

    /*enable/disable mint here*/
    function mintSwitch(bool _mintEnabled) external onlyOwner {
        mintEnabled = _mintEnabled; //it allows us to change true or false
    }

    function _initializeContract(string[14] memory characterUris) private {
        if (s_initialized) {
            revert WishNft__AlreadyInitialized();
        }
        s_characterUris = characterUris;
        s_initialized = true;
    }

    /*withdraw function for admin*/
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert WishNft__TransferFailed();
        }
    }

    /*for experimental burn nft*/
    function stellaF(uint256 tokenId) public {
        _burn(tokenId);
    }

    /*View/Pure Functions*/
    function getIsMintSwitchEnabled() public view returns (bool) {
        return mintEnabled;
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
        return s_wishCounter;
    }

    function getThreeStarCounter() public view returns (uint256) {
        return s_threeStarCounter;
    }

    function getFiveStarCounter() public view returns (uint256) {
        return s_fiveStarCounter;
    }

    function getFourStarCounter() public view returns (uint256) {
        return s_fourStarCounter;
    }
}
