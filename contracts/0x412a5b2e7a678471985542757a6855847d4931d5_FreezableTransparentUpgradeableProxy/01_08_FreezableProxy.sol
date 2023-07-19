// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity 0.7.6;

import "TransparentUpgradeableProxy.sol";
import {ProxyAdmin as ProxyAdminBase} from "ProxyAdmin.sol";

contract FreezableTransparentUpgradeableProxy is TransparentUpgradeableProxy {
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

    /// @notice Set the admin to address(0), which will result in freezing the implementation of the token.
    /// This is a non-reversible action.
    function freeze() external ifAdmin {
        bytes32 slot = _ADMIN_SLOT;
        address newAdmin = address(0);
        address currentAdmin = _admin();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
        emit AdminChanged(currentAdmin, newAdmin);
    }
}