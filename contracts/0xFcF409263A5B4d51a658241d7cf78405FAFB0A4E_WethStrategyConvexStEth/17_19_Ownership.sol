// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Ownership {
	address public owner;
	address public nominatedOwner;

	address public admin;

	mapping(address => bool) public authorized;

	event OwnerChanged(address indexed previousOwner, address indexed newOwner);
	event AuthAdded(address indexed newAuth);
	event AuthRemoved(address indexed oldAuth);

	error Unauthorized();
	error AlreadyRole();
	error NotRole();

	/// @param _authorized maximum of 256 addresses in constructor
	constructor(
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized
	) {
		owner = msg.sender;
		nominatedOwner = _nominatedOwner;
		admin = _admin;
		for (uint8 i = 0; i < _authorized.length; ++i) {
			authorized[_authorized[i]] = true;
			emit AuthAdded(_authorized[i]);
		}
	}

	// Public Functions

	function acceptOwnership() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		emit OwnerChanged(owner, msg.sender);
		owner = msg.sender;
		nominatedOwner = address(0);
	}

	// Restricted Functions: onlyOwner

	/// @dev nominating zero address revokes a pending nomination
	function nominateOwnership(address _newOwner) external onlyOwner {
		nominatedOwner = _newOwner;
	}

	function setAdmin(address _newAdmin) external onlyOwner {
		if (admin == _newAdmin) revert AlreadyRole();
		admin = _newAdmin;
	}

	// Restricted Functions: onlyAdmins

	function addAuthorized(address _authorized) external onlyAdmins {
		if (authorized[_authorized]) revert AlreadyRole();
		authorized[_authorized] = true;
		emit AuthAdded(_authorized);
	}

	function removeAuthorized(address _authorized) external onlyAdmins {
		if (!authorized[_authorized]) revert NotRole();
		authorized[_authorized] = false;
		emit AuthRemoved(_authorized);
	}

	// Modifiers

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}

	modifier onlyAdmins() {
		if (msg.sender != owner && msg.sender != admin) revert Unauthorized();
		_;
	}

	modifier onlyAuthorized() {
		if (msg.sender != owner && msg.sender != admin && !authorized[msg.sender]) revert Unauthorized();
		_;
	}
}