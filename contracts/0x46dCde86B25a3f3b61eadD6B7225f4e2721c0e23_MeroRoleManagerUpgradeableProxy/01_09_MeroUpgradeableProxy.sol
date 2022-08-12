// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "TransparentUpgradeableProxy.sol";

contract MeroUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}

contract MeroRoleManagerUpgradeableProxy is MeroUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable MeroUpgradeableProxy(_logic, admin_, _data) {}

    function _beforeFallback() internal virtual override {}
}