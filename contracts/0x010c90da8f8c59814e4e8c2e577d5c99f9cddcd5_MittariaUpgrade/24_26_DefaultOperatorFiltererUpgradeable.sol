// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { OperatorFiltererUpgradeable } from "./OperatorFiltererUpgradeable.sol";

/**
 * @title  DefaultOperatorFiltererUpgradeable
 * @notice Inherits from OperatorFiltererUpgradeable and automatically subscribes to the default OpenSea subscription
 *         when the init function is called.
 */
abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
  /// @dev The upgradeable initialize function that should be called when the contract is being deployed.
  function __DefaultOperatorFilterer_init() internal onlyInitializing {
    OperatorFiltererUpgradeable.__OperatorFilterer_init(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true);
  }
}