// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./TransparentUpgradeableProxy.sol";

/// @title A proxy contract for did
contract EternalStorageProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
