// THIS CONTRCT HAS BEEN MODIFIED TO PREVENT SINGLE ROLE HOLDERS FROM REVOKING THEMSELVES
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
        uint256 numberOfBearers;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        uint256 numberOfBearers = role.numberOfBearers -= 1; // there is always at least one account added in constructor, so this cannot overflow below zero
        require(atLeastOneBearer(numberOfBearers), "Roles: there must be at least one account assigned to this role");
        
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }
}