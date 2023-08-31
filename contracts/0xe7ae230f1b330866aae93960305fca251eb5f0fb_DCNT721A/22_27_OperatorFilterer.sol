// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *     registrant's entries in the OperatorFilterRegistry.
 * @dev  This smart contract is meant to be inherited by token contracts so they can use the following:
 *     - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *     - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
  error OperatorNotAllowed(address operator);

  IOperatorFilterRegistry public constant operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  modifier onlyAllowedOperator(address from) virtual {
    // Allow spending tokens from addresses with balance
    // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    // from an EOA.
    if (from != msg.sender) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) virtual {
    _checkFilterOperator(operator);
    _;
  }

  function _checkFilterOperator(address operator) internal view virtual {
    // Check registry code length to facilitate testing in environments without a deployed registry.
    if (address(operatorFilterRegistry).code.length > 0) {
      if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
        revert OperatorNotAllowed(operator);
      }
    }
  }
}