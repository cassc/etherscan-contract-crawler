// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { InitializableAdminUpgradeabilityProxy } from "@BootNodeDev/powertrade-stake-contracts/contracts/lib/InitializableAdminUpgradeabilityProxy.sol";

/**
 * @title InitializableTransparentUpgradeableProxy
 * @dev This contract implements a proxy that is upgradeable by an admin.
 * Extends Aave implementation, that provides an initializer for initializing the implementation, admin, and init data.
 */
contract InitializableTransparentUpgradeableProxy is InitializableAdminUpgradeabilityProxy {
  // solhint-disable-previous-line no-empty-blocks
}