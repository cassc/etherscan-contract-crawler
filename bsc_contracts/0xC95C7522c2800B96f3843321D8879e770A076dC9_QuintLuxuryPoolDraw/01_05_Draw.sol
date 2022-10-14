// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {QuintLuxuryPoolInterface} from "./QuintLuxuryPoolInterface.sol";

contract QuintLuxuryPoolDraw is VRFConsumerBaseV2 {
  QuintLuxuryPoolInterface public immutable LUXURY_POOL_B;

  VRFCoordinatorV2Interface public immutable coordinator;
  LinkTokenInterface public immutable linkToken;

  string public ticketsListIpfsLink;

  struct VRF {
    uint64 subscriptionId;
    uint256 requestId;
    uint16 requestConfirmations;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint256 randomWord;
    uint32 wordCount;
  }

  VRF public vrf;

  constructor(
    address _luxuryPoolB,
    address _vrfCoordinator,
    uint64 _vrfSubscriptionId,
    bytes32 _vrfKeyHash,
    address _linkToken,
    string memory _ticketsListIpfsLink
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    require(_luxuryPoolB != address(0), "Draw: Nullish address");
    require(_linkToken != address(0), "Draw: Nullish address");

    // VRF integration setup
    coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    linkToken = LinkTokenInterface(_linkToken);
    // VRF consumer configuration
    vrf.subscriptionId = _vrfSubscriptionId;
    vrf.requestConfirmations = 3;
    vrf.keyHash = _vrfKeyHash;
    vrf.callbackGasLimit = 100000;
    vrf.wordCount = 1;

    LUXURY_POOL_B = QuintLuxuryPoolInterface(_luxuryPoolB);
    ticketsListIpfsLink = _ticketsListIpfsLink;
  }

  function winnerTicket() external view returns (uint256) {
    require(block.timestamp >= LUXURY_POOL_B.poolEndTime(), "Draw: Only After Pool Ends");
    require(vrf.randomWord != 0, "Draw: randomness not ready ");

    return ((vrf.randomWord % LUXURY_POOL_B.totalTickets()) + 1);
  }

  function requestRandomWords() external {
    require(vrf.randomWord == 0, "Draw: randomness replay ");
    require(block.timestamp >= LUXURY_POOL_B.poolEndTime(), "Draw: Only After Pool Ends");

    //reverts if subscription is not set and funded.
    vrf.requestId = coordinator.requestRandomWords(
      vrf.keyHash,
      vrf.subscriptionId,
      vrf.requestConfirmations,
      vrf.callbackGasLimit,
      vrf.wordCount
    );
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
    vrf.randomWord = randomWords[0];
  }
}