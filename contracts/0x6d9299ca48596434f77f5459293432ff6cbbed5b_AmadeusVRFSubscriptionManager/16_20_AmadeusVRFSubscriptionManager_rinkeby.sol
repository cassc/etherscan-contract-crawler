// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract AmadeusVRFSubscriptionManagerRinkeby {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  // Storage parameters
  uint64 public s_subscriptionId;
  address s_owner;

  constructor(address manager) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    s_owner = manager;
    //Create a new subscription when you deploy the contract.
    createNewSubscription();
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private {
    s_subscriptionId = COORDINATOR.createSubscription();
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  function topUpSubscription(uint256 amount) external onlyOwner {
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    // Add a consumer contract to the subscription.
    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    // Remove a consumer contract from the subscription.
    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) external onlyOwner {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    LINKTOKEN.transfer(to, amount);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}