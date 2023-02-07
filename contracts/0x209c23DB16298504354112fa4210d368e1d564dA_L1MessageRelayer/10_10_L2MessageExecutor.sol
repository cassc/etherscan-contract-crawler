// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {AddressAliasHelper} from "./AddressAliasHelper.sol";

/**
 * @dev This contract executes messages received from layer1 governance on arbitrum.
 * This meant to be an upgradeable contract and it should only be used with TransparentUpgradeableProxy.
 */
contract L2MessageExecutor is ReentrancyGuard {
  /// @notice Address of the L1MessageRelayer contract on mainnet.
  address public l1MessageRelayer;

  /// @dev flag to make sure that the initialize function is only called once
  bool private isInitialized = false;

  constructor() {
		// Disable initialization for external users.
		// Only proxies should be able to initialize this contract.
    isInitialized = true;
  }

  function initialize(address _l1MessageRelayer) external {
    require(!isInitialized, "Contract is already initialized!");
    isInitialized = true;
    require(
      _l1MessageRelayer != address(0),
      "_l1MessageRelayer can't be the zero address"
    );
    l1MessageRelayer = _l1MessageRelayer;
  }

  /**
   * @notice executes message received from L1.
   * @param payLoad message received from L1 that needs to be executed.
   **/
  function executeMessage(bytes calldata payLoad) external nonReentrant {
    // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
    require(
      msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1MessageRelayer),
      "L2MessageExecutor::executeMessage: Unauthorized message sender"
    );

    (address target, bytes memory callData) = abi.decode(
      payLoad,
      (address, bytes)
    );
    require(target != address(0), "target can't be the zero address");
    (bool success, ) = target.call(callData);
    require(
      success,
      "L2MessageExecutor::executeMessage: Message execution reverted."
    );
  }
}