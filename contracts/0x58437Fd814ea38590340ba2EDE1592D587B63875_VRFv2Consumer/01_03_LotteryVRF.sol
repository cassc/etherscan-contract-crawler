// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface private COORDINATOR;

  // Your subscription ID.
  uint64 private s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address public vrfCoordinator;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 public keyHash;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 private callbackGasLimit;

  uint16 private requestConfirmations;

  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 private numWords;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address public s_owner;

  constructor(
    uint64 subscriptionId,
    address _vrfCoordinator,
    bytes32 _keyHash,
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _keyHash;
    callbackGasLimit =_callbackGasLimit;
    requestConfirmations = _requestConfirmations;
    numWords = _numWords;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  function updateKeyHash(bytes32 newKeyHash) external onlyOwner {
    keyHash = newKeyHash;
  }
  function updateSubscriptionId(uint64 newId) external onlyOwner {
    s_subscriptionId = newId;
  }
  function updateRequestConfirmations(uint16 newConfirmations) external onlyOwner {
    requestConfirmations = newConfirmations;
  }
  function updateCallbackGasLimit(uint32 newGasLimit) external onlyOwner {
    callbackGasLimit = newGasLimit;
  }
  function updateNumWords(uint32 newNumWords) external onlyOwner {
    numWords = newNumWords;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    s_owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner, "Only the contract owner may perform this action");
    _;
  }
}