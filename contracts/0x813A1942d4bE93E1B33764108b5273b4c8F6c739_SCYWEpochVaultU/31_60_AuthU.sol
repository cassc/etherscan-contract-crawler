// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { AuthConfig } from "./Auth.sol";

contract AuthU is AccessControlUpgradeable {
	event OwnershipTransferInitiated(address owner, address pendingOwner);
	event OwnershipTransferred(address oldOwner, address newOwner);

	////////// CONSTANTS //////////

	/// Update vault params, perform time-sensitive operations, set manager
	bytes32 public constant GUARDIAN = keccak256("GUARDIAN");

	/// Hot-wallet bots that route funds between vaults, rebalance and harvest strategies
	bytes32 public constant MANAGER = keccak256("MANAGER");

	/// Add and remove vaults and strategies and other critical operations behind timelock
	/// Default admin role
	/// There should only be one owner, so it is not a role
	address public owner;
	address public pendingOwner;

	modifier onlyOwner() {
		require(msg.sender == owner, "ONLY_OWNER");
		_;
	}

	/// security no undefined constructor
	constructor() {}

	function __Auth_init(AuthConfig memory authConfig) public onlyInitializing {
		/// Set up the roles
		// owner can manage all roles
		owner = authConfig.owner;
		emit OwnershipTransferred(address(0), authConfig.owner);

		// TODO do we want cascading roles like this?
		_grantRole(DEFAULT_ADMIN_ROLE, authConfig.owner);
		_grantRole(GUARDIAN, owner);
		_grantRole(GUARDIAN, authConfig.guardian);
		_grantRole(MANAGER, authConfig.owner);
		_grantRole(MANAGER, authConfig.guardian);
		_grantRole(MANAGER, authConfig.manager);

		/// Allow the guardian role to manage manager
		_setRoleAdmin(MANAGER, GUARDIAN);
	}

	// ----------- Ownership -----------

	/// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
	/// @param _pendingOwner pending owner of contract
	/// Can only be called by the current owner.
	function transferOwnership(address _pendingOwner) external onlyOwner {
		pendingOwner = _pendingOwner;
		emit OwnershipTransferInitiated(owner, pendingOwner);
	}

	/// @dev Accept transfer of ownership of the contract.
	/// Can only be called by the pendingOwner.
	function acceptOwnership() external {
		require(msg.sender == pendingOwner, "ONLY_PENDING_OWNER");
		address oldOwner = owner;
		owner = pendingOwner;

		// revoke the DEFAULT ADMIN ROLE from prev owner
		_revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
		_grantRole(DEFAULT_ADMIN_ROLE, owner);

		emit OwnershipTransferred(oldOwner, owner);
	}

	uint256[50] private __gap;
}