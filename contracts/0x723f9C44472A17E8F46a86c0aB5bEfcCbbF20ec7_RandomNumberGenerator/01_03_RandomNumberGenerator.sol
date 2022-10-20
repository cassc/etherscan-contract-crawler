// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title The RandomNumberGenerator contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract RandomNumberGenerator is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface immutable COORDINATOR;

  // Your subscription ID.
  uint64 immutable _subscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 immutable _keyHash;

  // Callback gas limit must not go over 2.5M as required by VRF
  uint32 constant CALLBACK_GAS_LIMIT = 2_500_000;

  // The default is 3, but you can set this higher.
  uint16 constant REQUEST_CONFIRMATIONS = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 constant NUM_WORDS = 1;

  // Address of the contract owner
  address private _owner;

  // Params for the request that will be written to the logs
  struct Params {
    address partnerContract;
    uint32 totalEntries;
    uint32 totalSelections;
    string title;
  }

  // Array to track randomization requests
  mapping(uint256 => Params) public requests;

  event ReturnedRandomWord(
    uint256 randomWord,
    uint256 requestId,
    Params params
  );

  /**
   * @notice Constructor inherits VRFConsumerBaseV2
   *
   * @param subscriptionId - the subscription ID that this contract uses for funding requests
   * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
   * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
   */
  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    bytes32 keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    _keyHash = keyHash;
    _owner = msg.sender;
    _subscriptionId = subscriptionId;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Caller is not the owner");
    _;
  }

  /**
   * @notice Makes a random request
   * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
   *
   * @param partnerContract the address of the partner contract
   * @param totalEntries the total number of entries to randomize
   * @param totalSelections the number of selections to return
   * @param title the title used to write the logs
   */
  function requestRandomWords(
    address partnerContract,
    uint32 totalEntries,
    uint32 totalSelections,
    string calldata title
  ) external onlyOwner {
    // Will revert if subscription is not set and funded.
    uint256 requestId = COORDINATOR.requestRandomWords(
      _keyHash,
      _subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    requests[requestId] = Params(
      partnerContract,
      totalEntries,
      totalSelections,
      title
    );
  }

  /**
   * @notice Callback function used by VRF Coordinator
   *
   * @param requestId - the requestId from the VRF Coordinator
   * @param randomWords - array of random results from VRF Coordinator
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    emit ReturnedRandomWord(randomWords[0], requestId, requests[requestId]);
  }

  /**
   * @notice Gets the subscription ID set up by VRF
   */
  function getSubscriptionId() public view returns (uint64) {
    return _subscriptionId;
  }
}