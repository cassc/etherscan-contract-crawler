// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract AdminAccessControl is AccessControl, Ownable {
    bytes32 public constant ADMIN = "ADMIN";

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), 'Caller is not a admin');
        _;
    }

    function grantAdmin(address account)
        public
        onlyOwner
    {
        _grantRole(ADMIN, account);
    }

    function revokeAdmin(address account)
        public
        onlyOwner
    {
        _revokeRole(ADMIN, account);
    }
}