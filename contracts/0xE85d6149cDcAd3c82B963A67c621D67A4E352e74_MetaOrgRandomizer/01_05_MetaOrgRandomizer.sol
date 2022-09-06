// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MetaOrgRandomizer is VRFConsumerBaseV2, Ownable {

  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  VRFCoordinatorV2Interface COORDINATOR;

  // see https://vrf.chain.link/
  uint64 public subscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 public keyHash;

  // based on the network, size of the request and processing of the callback request in the fulfillRandomWords()
  uint32 public callbackGasLimit = 100000;

  // default is 3 as per chainlink docs
  uint16 constant REQUEST_CONFIRMATIONS = 3;

  uint32 constant NUM_WORDS = 1;

  uint256 public requestCounter;

  struct RandomnessRequest {
    bool pending;
    uint120 min;
    uint120 max;
    uint256 result;
    string purpose;
  }

  // @dev request id to payload
  mapping(uint256 => RandomnessRequest) public requests;

  // @dev vrf request id to request counter
  mapping(uint256 => uint256) vrfRequestIdToRequestCounter;

  constructor(
    uint64 _subscriptionId,
    address _vrfCoordinator,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    subscriptionId = _subscriptionId;
    keyHash = _keyHash;
  }

  function setKeyHash(bytes32 hash) external onlyOwner {
    keyHash = hash;
  }

  function setCallbackGasLimit(uint32 limit) external onlyOwner {
    callbackGasLimit = limit;
  }

  function setSubscriptionId(uint64 id) external onlyOwner {
    subscriptionId = id;
  }

  function requestRandomInRange(
    string calldata purpose,
    uint120 min,
    uint120 max
  ) external onlyOwner returns(uint256 requestId) {
    return performRequestRandom(purpose, min, max);
  }

  function requestRandom(
    string calldata purpose
  ) external onlyOwner returns(uint256 requestId) {
    return performRequestRandom(purpose, 0, 0);
  }

  function performRequestRandom(
    string calldata purpose,
    uint120 min,
    uint120 max
  ) internal returns(uint256) {
    // Will revert if subscription is not set and funded.
    uint256 vrfRequestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      REQUEST_CONFIRMATIONS,
      callbackGasLimit,
      NUM_WORDS
    );

    uint256 currentCounter = requestCounter++;
    requests[currentCounter] = RandomnessRequest(true, min, max, 0, purpose);
    vrfRequestIdToRequestCounter[vrfRequestId] = currentCounter;
    return currentCounter;
  }

  // from VRFConsumerBaseV2
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    RandomnessRequest storage request = requests[vrfRequestIdToRequestCounter[requestId]];
    uint120 min = request.min;
    uint120 max = request.max;

    if (min == 0 && max == 0) {
      request.result = randomWords[0];
    } else {
      request.result = randomWords[0] % (max - min + 1) + min;
    }

    request.pending = false;
  }
}