// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "TransparentUpgradeableProxy.sol";
import {ProxyAdmin as ProxyAdminBase} from "ProxyAdmin.sol";

contract FreezableTransparentUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

    /// @notice Set the admin to address(0), which will result in freezing
    /// the implementation of the token
    /// This is a non-reversible action
    function freeze() external ifAdmin {
        emit AdminChanged(_getAdmin(), address(0));
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = address(0);
    }
}

/// @notice Only used to make ProxyAdmin available in project contracts
contract ProxyAdmin is ProxyAdminBase {

}