// SPDX-License-Identifier: MIT

/**
 ██████╗███╗   ██╗████████╗███╗   ██╗███╗   ███╗     ██████╗ █████╗ ███╗   ██╗██╗   ██╗ █████╗ ███████╗
██╔════╝████╗  ██║╚══██╔══╝████╗  ██║████╗ ████║    ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗██╔════╝
██║     ██╔██╗ ██║   ██║   ██╔██╗ ██║██╔████╔██║    ██║     ███████║██╔██╗ ██║██║   ██║███████║███████╗
██║     ██║╚██╗██║   ██║   ██║╚██╗██║██║╚██╔╝██║    ██║     ██╔══██║██║╚██╗██║╚██╗ ██╔╝██╔══██║╚════██║
╚██████╗██║ ╚████║   ██║   ██║ ╚████║██║ ╚═╝ ██║    ╚██████╗██║  ██║██║ ╚████║ ╚████╔╝ ██║  ██║███████║
 ╚═════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═══╝╚═╝     ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝  ╚═╝╚══════╝                                                                                                                                                              
*/


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract CNTNMCanvas is Ownable, ERC721A, VRFConsumerBaseV2, ReentrancyGuard {
  VRFCoordinatorV2Interface COORDINATOR;
  string private _baseTokenURI;

  uint64 s_subscriptionId;

  ERC721A cntnm;

  // Ethereum mainnet: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
  address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // Ethereum keyhash: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805
  bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

  uint16 requestConfirmations = 3;

  uint256[] public s_randomWords;
  uint256 public s_requestId;

  // Declare variables to emit events when the fullfillrandomwords callback is called
  uint256 second_req_id; // Second requested id (used to identify the second call to requestRandomWords, supposedly done by createWinnersList function)
  bool winner_ids_set = false; // Variable used to assert that a numerical random number of winners has already been set
  uint32 rand_num_owners; // Random number of nfts/owners selected to get rewards
  uint32 max_winners; // Maximum number of potential winners
  
  constructor() ERC721A("The Continuum Canvas", "CNTNM-CANVAS") VRFConsumerBaseV2(vrfCoordinator) {
    _baseTokenURI = "";
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
  }

  function setSubscriptionId(uint64 subscriptionId) external onlyOwner {
    s_subscriptionId = subscriptionId;
  }

  function setCNTNMreference(address cntnm_address) external onlyOwner {
    // Call CNTNM deployed contract to get the owner addresses of the winners
    cntnm = ERC721A(cntnm_address);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function cntnmMint() external onlyOwner {
    _safeMint(msg.sender, 1); 
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  event winnersList(address[] winners_addresses);
  event numOfWinners(uint256 num_winners);

  function randNumWinners(uint32 min_callbackGasLimit, uint32 _max_winners) external onlyOwner nonReentrant {
    // First, generate only one single random number from 1-max_winners that will tell the number of nft's (owners) that are eligible to receive funds from the given canvas edition
    // Storing each word/random value costs about 20,000 gas + operations in fulfillRandomWords function,
    // so using up to 50,000 - 100,000 is safe.
    requestRandomWords(min_callbackGasLimit, 1);
    max_winners = _max_winners;
  }

  // Generate list of random CNTNM nft owners to withdraw funds to, from the auction of each canvas edition
  // Assumes the randNumWinners function has already been called
  function createWinnersList(uint32 min_callbackGasLimit) external onlyOwner nonReentrant {
    // Generate an array with random numbers of the size 'rand_num_owners'. Each number corresponds to an nft winner (owner)
    require(s_randomWords.length > 0, "Randon Number of winners not set.");
    uint32 callbackGasLimit = min_callbackGasLimit * rand_num_owners;
    winner_ids_set = true;
    requestRandomWords(callbackGasLimit, rand_num_owners);
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint32 callbackGasLimit, uint32 numWords) internal {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    // second_req_id can only be set if there is already a random number of winners in storage
    if (winner_ids_set) {
        second_req_id = s_requestId;
    }
  }

  function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
    s_randomWords = randomWords;
    // Checking against potential failure generating a number with createWinnersList and resetting second_req_id to
    // protect the events' integrity
    if (second_req_id != 0 && s_randomWords.length == 0) {
      second_req_id = 0;
      winner_ids_set = false;
    }
    if (second_req_id == 0) {
      // Transform the result to a number between 1 and max_winners inclusively
      rand_num_owners = (uint32(s_randomWords[0]) % max_winners) + 1;
      emit numOfWinners(rand_num_owners);
    } else {
        address[] memory winners_list = new address[](rand_num_owners);
        // For each number generated pointing to a CNTNM nft index, get its owner address
        for (uint i=0; i < rand_num_owners; i++) {
            uint256 rand_winner_nft_index = (s_randomWords[i] % 999) + 1; 
            address winner = cntnm.ownerOf(rand_winner_nft_index);
            winners_list[i] = winner;
        }
        emit winnersList(winners_list);
        // Reset variables for new call
        second_req_id = 0;
        winner_ids_set = false;
    }
  }
}