//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ExtendedAccessControl is AccessControl {
    function _grantRole(bytes32 role, address[] memory accounts) internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                accounts[i] != address(0),
                "ExtendedAccessControl: Address zero"
            );

            _grantRole(role, accounts[i]);
        }
    }

    /// @dev Overriding to disallow revoking the DEFAULT_ADMIN_ROLE role
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            role != DEFAULT_ADMIN_ROLE,
            "ExtendedAccessControl: incapable of renouncing default admin"
        );

        AccessControl.renounceRole(role, account);
    }
}