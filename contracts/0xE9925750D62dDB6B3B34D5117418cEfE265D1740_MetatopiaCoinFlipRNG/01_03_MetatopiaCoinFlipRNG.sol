// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MetatopiaCoinFlipRNG is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;


  uint64 s_subscriptionId;
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  uint32 callbackGasLimit = 2500000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 2;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  address public BullRunContract;
  uint256 private lastWord;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyBullRunContract() {
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

  function oneOutOfTwo() external onlyBullRunContract() returns (uint256 result) {
    require(s_randomWords[0] != lastWord, "Too Soon, please wait for new number generation");
    result = (s_randomWords[0] % 2);
    lastWord = s_randomWords[0];
    return result;
  }

  function setBullRunContract(address _address) external onlyOwner {
    BullRunContract = _address;
  }

  function setCallbackGas(uint32 _gas) external onlyOwner {
    callbackGasLimit = _gas;
  }

  modifier onlyBullRunContract() {
    require(msg.sender == BullRunContract , "Only BullRun.sol");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}