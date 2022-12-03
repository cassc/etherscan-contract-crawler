// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../errors/GMVRFConsumerErrors.sol';

abstract contract GMVRFConsumer is VRFConsumerBaseV2, Ownable {
  // INFO: Chainlink variables
  VRFCoordinatorV2Interface private COORDINATOR;
  address internal vrfCoordinatorAddress;
  bytes32 internal _chainLinkKeyHash;
  uint64 internal _chainLinkSubsId;
  uint256 internal _chainLinkSeedNumber;

  constructor(
    uint64 chainLinkSubsId_,
    address vrfCoordinator,
    bytes32 chainLinkKeyHash_
  ) VRFConsumerBaseV2(vrfCoordinator) {
    _chainLinkKeyHash = chainLinkKeyHash_;
    _chainLinkSubsId = chainLinkSubsId_;
    vrfCoordinatorAddress = vrfCoordinator;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
  }

  modifier onlySeedNumberIsNotSet() {
    if (_chainLinkSeedNumber > 0) {
      revert SeedNumberShouldntBeSet();
    }
    _;
  }

  modifier onlySeedNumberIsSet() {
    if (_chainLinkSeedNumber == 0) {
      revert SeedNumberShouldBeSet();
    }
    _;
  }

  event SeedNumberAssigned();

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner onlySeedNumberIsNotSet {
    // Will revert if subscription is not set and funded.
    COORDINATOR.requestRandomWords(
      _chainLinkKeyHash,
      _chainLinkSubsId,
      3, //confirmations
      100000, //callbackGasLimit,
      1 // request random numbers
    );
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
    _chainLinkSeedNumber = randomWords[0];
    emit SeedNumberAssigned();
  }
}