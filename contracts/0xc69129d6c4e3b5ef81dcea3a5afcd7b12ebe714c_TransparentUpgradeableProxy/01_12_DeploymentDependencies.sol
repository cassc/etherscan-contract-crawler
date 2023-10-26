// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {TransparentUpgradeableProxy as BaseTransparentUpgradeableProxy} from "TransparentUpgradeableProxy.sol";
import {ProxyAdmin as BaseProxyAdmin} from "ProxyAdmin.sol";

contract TransparentUpgradeableProxy is BaseTransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable BaseTransparentUpgradeableProxy(_logic, admin_, _data) {}
}

/// @dev different name to easily be able to retrieve by name
/// in deployment scripts
contract GovernanceManagerProxy is BaseTransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable BaseTransparentUpgradeableProxy(_logic, admin_, _data) {}
}

contract ProxyAdmin is BaseProxyAdmin {}