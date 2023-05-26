// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";


contract Administration is AccessControl {

    address private _owner;
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR");

    /// @dev Add `root` to the admin role as a member.
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
        _setRoleAdmin(MODERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }}