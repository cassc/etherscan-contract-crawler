// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Permission is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
 
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Forbidden");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }
}