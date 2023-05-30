// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessibleCommon.sol";

contract AccessiblePlusCommon is AccessibleCommon {
    modifier onlyMinter() {
        require(
            isMinter(msg.sender),
            "AccessiblePlusCommon: Caller is not a minter"
        );
        _;
    }
    modifier onlyBurner() {
        require(
            isBurner(msg.sender),
            "AccessiblePlusCommon: Caller is not a burner"
        );
        _;
    }

    function isMinter(address account) public view virtual returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isBurner(address account) public view virtual returns (bool) {
        return hasRole(BURNER_ROLE, account);
    }

    function addMinter(address account) public virtual onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    function addBurner(address account) public virtual onlyOwner {
        grantRole(BURNER_ROLE, account);
    }

    function removeMinter(address account) public virtual onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }

    function removeBurner(address account) public virtual onlyOwner {
        revokeRole(BURNER_ROLE, account);
    }
}