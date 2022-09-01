// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract ShackersRandomizer is VRFConsumerBaseV2, Ownable {

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

  uint256 public requestCounter;

  struct RandomnessRequest {
    bool pending;
    uint8 count;
    uint120 min;
    uint120 max;
    string purpose;
  }

  // @dev request id to payload
  mapping(uint256 => RandomnessRequest) public requests;

  // @dev request id to results
  mapping(uint256 => uint256[]) public results;

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
    uint8 count,
    uint120 min,
    uint120 max
  ) external onlyOwner returns(uint256 requestId) {
    return performRequestRandom(purpose, count, min, max);
  }

  function requestRandom(
    string calldata purpose,
    uint8 count
  ) external onlyOwner returns(uint256 requestId) {
    return performRequestRandom(purpose, count, 0, 0);
  }

  function performRequestRandom(
    string calldata purpose,
    uint8 count,
    uint120 min,
    uint120 max
  ) internal returns(uint256 currentCounter) {
    uint8 requestCount = count == 0 ? 1 : count;

    // Will revert if subscription is not set and funded.
    uint256 vrfRequestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      REQUEST_CONFIRMATIONS,
      callbackGasLimit,
      uint32(requestCount)
    );

    currentCounter = requestCounter++;
    requests[currentCounter] = RandomnessRequest(true, requestCount, min, max, purpose);
    vrfRequestIdToRequestCounter[vrfRequestId] = currentCounter;
  }

  // from VRFConsumerBaseV2
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    uint256 internalRequestId = vrfRequestIdToRequestCounter[requestId];
    RandomnessRequest storage request = requests[internalRequestId];
    uint120 min = request.min;
    uint120 max = request.max;

    if (min == 0 && max == 0) {
      results[internalRequestId] = randomWords;
    } else {
      for (uint256 i = 0; i < randomWords.length; ) {
        results[internalRequestId].push(randomWords[i] % (max - min + 1) + min);
        unchecked {++i;}
      }
    }

    request.pending = false;
  }
}