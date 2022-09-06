// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract PvSubscriptionManager {
  VRFCoordinatorV2Interface immutable COORDINATOR;
  LinkTokenInterface immutable LINKTOKEN;

  uint64 public s_subscriptionId;
  address s_owner;

  constructor(
    address _vrfCoordinator,
    address _linkToken
  ) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(_linkToken);

    s_owner = msg.sender;
    
    s_subscriptionId = COORDINATOR.createSubscription();
  }

  function topUpSubscription(uint256 amount) external onlyOwner {
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function createNewSubscription() external onlyOwner {
    s_subscriptionId = COORDINATOR.createSubscription();
  }

  function cancelSubscription(address receivingWallet) external onlyOwner {
    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  function withdraw(uint256 amount, address to) external onlyOwner {
    LINKTOKEN.transfer(to, amount);
  }

  function getSubscription() external view returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
  ) {
      return COORDINATOR.getSubscription(s_subscriptionId);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}