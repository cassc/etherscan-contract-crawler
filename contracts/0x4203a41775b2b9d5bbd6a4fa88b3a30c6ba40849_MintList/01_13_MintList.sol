// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MintList is AccessControlEnumerable, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

	function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}

    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MANAGER_ROLE, manager);
    }

    function subscribeByManager(address minter) public whenNotPaused onlyRole(MANAGER_ROLE) {
        _setupRole(MINTER_ROLE, minter);
    }

    function subscribe() public whenNotPaused {
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function getCountMinters() public view returns (uint256) {
        return getRoleMemberCount(MINTER_ROLE);
    }

    function isMinter(address minter) public view returns (bool) {
        return hasRole(MINTER_ROLE, minter);
    }

    function isManager(address manager) public view returns (bool) {
        return hasRole(MANAGER_ROLE, manager);
    }
}