// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessControlCustom is AccessControl {
    error ErrGrantRoleToZeroAddress();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function transferAdmin(address newAdmin)
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newAdmin == address(0)) {
            revert ErrGrantRoleToZeroAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
}