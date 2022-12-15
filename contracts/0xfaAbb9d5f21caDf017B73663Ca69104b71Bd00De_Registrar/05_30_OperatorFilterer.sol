// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
  error OperatorNotAllowed(address operator);

  // OPERATOR_FILTER_REGISTRY should have deployed contract address,
  // so we can reduce checking their code length to facilitate testing
  // in environments without a deployed registry.
  // We've already removed checking in `_initializeFilter`,
  // `_onlyAllowedOperator` and `_onlyAllowedOperator` functions.
  //   i.e. address(OPERATOR_FILTER_REGISTRY).code.length > 0
  // OperatorFilterRegistry was already deployed with same address on the
  // different networks:
  //   https://github.com/ProjectOpenSea/operator-filter-registry#deployments
  IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  function _initializeFilter(
    address subscriptionOrRegistrantToCopy,
    bool subscribe
  ) internal {
    // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
    // will not revert, but the contract will need to be registered with the registry once it is deployed in
    // order for the modifier to filter addresses.
    if (subscribe) {
      OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
        address(this),
        subscriptionOrRegistrantToCopy
      );
    } else {
      if (subscriptionOrRegistrantToCopy != address(0)) {
        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(
          address(this),
          subscriptionOrRegistrantToCopy
        );
      } else {
        OPERATOR_FILTER_REGISTRY.register(address(this));
      }
    }
  }

  function _onlyAllowedOperator(address from) internal virtual {
    // Allow spending tokens from addresses with balance
    // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    // from an EOA.
    if (from == msg.sender) {
      return;
    }
    if (
      !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), msg.sender)
    ) {
      revert OperatorNotAllowed(msg.sender);
    }
  }

  function _onlyAllowedOperatorApproval(address operator) internal virtual {
    if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
      revert OperatorNotAllowed(operator);
    }
  }
}