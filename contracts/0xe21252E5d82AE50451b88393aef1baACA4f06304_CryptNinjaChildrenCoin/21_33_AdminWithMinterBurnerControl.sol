// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AdminAccessControl.sol";

contract AdminWithMinterBurnerControl is AdminAccessControl {
    bytes32 public constant MINTER = 'MINTER';
    bytes32 public constant BURNER = 'BURNER';

    modifier onlyMinter() {
        require(hasRole(MINTER, _msgSender()), 'Caller is not a minter');
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER, _msgSender()), 'Caller is not a burner');
        _;
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        require(role != ADMIN, "not admin only.");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        require(role != ADMIN, "not admin only.");
        _revokeRole(role, account);
    }
}