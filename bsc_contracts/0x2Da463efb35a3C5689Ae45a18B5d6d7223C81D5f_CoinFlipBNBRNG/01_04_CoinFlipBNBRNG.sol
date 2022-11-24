// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/ICoinFlip.sol";

// @ dev: A smart contract using chainlink VRF v2 to generate random number to decide a coin flip
// @ dev: *** YOU MUST ADD THIS DEPLOYED CONTRACT ADDRESS TO THE APPROVED CONSUMER LIST! ***

contract CoinFlipBNBRNG is VRFConsumerBaseV2 {
  
  VRFCoordinatorV2Interface COORDINATOR;
  address vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE; // for bsc 
  bytes32 keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04; // for bsc 
  uint64 s_subscriptionId; //  on BSC 
  uint32 callbackGasLimit = 2500000; // each result ~ 20,000 gas
  uint32 numWords =  1; 
  uint16 requestConfirmations = 3; 
  
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint256 private lastWord; 
  address s_owner;
  address public coinFlipBNBContractAddress;
  ICoinFlip private CoinFlipBNB;

  mapping(uint256 => uint256) public sessionRequested;
  bool public autoSettle = true;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    uint256[] memory initialWords = new uint256[](1);
    s_randomWords = initialWords;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint256 session) external onlyCoinFlipBNBContract {
    lastWord = s_randomWords[0];
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    sessionRequested[s_requestId] = session;
  }
  
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;

    if(autoSettle) { flipAndClose(sessionRequested[requestId], randomWords[0]); }
  }

  function flipCoin() external view onlyCoinFlipBNBContract returns (uint256 result) {
    require(s_randomWords[0] != lastWord, "please wait for new number");
    result = (s_randomWords[0] % 2);
    return result;
  }

  function flipAndClose(uint256 session, uint256 seed) internal {
    uint256 result = (seed % 2);
    CoinFlipBNB.autoFlip(session, uint8(result));
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner , "not owner");
    _;
  }

  modifier onlyCoinFlipBNBContract() {
    require(msg.sender == coinFlipBNBContractAddress || msg.sender == s_owner, "Only CoinFlipBNB");
    _;
  }

  function setCoinFlipBNBContract(address _address) public onlyOwner {
    coinFlipBNBContractAddress = _address;
    CoinFlipBNB = ICoinFlip(_address);
  }

  function setCallbackGas(uint32 _gas) external onlyOwner {
    callbackGasLimit = _gas;
  }

  function setAutoSettle(bool _flag) external onlyOwner {
    autoSettle = _flag;
  }
}