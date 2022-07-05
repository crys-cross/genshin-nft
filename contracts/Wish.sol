// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wish is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // NFT Variables
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 internal immutable i_mintFee;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);

    // constructor(
    //     address vrfCoordinatorV2,
    //     uint256 entranceFee,
    //     bytes32 gasLane,
    //     uint64 subscriptionId,
    //     uint32 callbackGasLimit,
    //     uint256 interval
    // ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    //     i_entranceFee = entranceFee;
    //     i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    //     i_gasLane = gasLane;
    //     i_subscriptionId = subscriptionId;
    //     i_callbackGasLimit = callbackGasLimit;
    // }
}

//TODO
//track players pulls(mapping or array)
//set percent chance of minting 5star nft per number of pulls
//set function to reset chances when 5star is minted or 90th mint(since 5star guarantee in 90th pull)
//set vrf and functions per percentage