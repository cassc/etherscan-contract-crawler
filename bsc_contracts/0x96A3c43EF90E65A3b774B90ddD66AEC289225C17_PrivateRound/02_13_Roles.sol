// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";


contract Roles is AccessControl
{
	bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
	bytes32 public constant ROLE_ADMINISTRATOR = keccak256("ROLE_ADMINISTRATOR");


	constructor(address defaultOwner_, address defaultAdmin_)
	{
		if (defaultOwner_ != address(0)) _grantRole(ROLE_OWNER, defaultOwner_);
		else _grantRole(ROLE_OWNER, msg.sender);

		if (defaultAdmin_ != address(0)) _grantRole(ROLE_ADMINISTRATOR, defaultAdmin_);

		_setRoleAdmin(ROLE_ADMINISTRATOR, ROLE_OWNER);

		// If need to transfer ownership in future
		_setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
	}


	modifier onlyOwner()
	{
		require(hasRole(ROLE_OWNER, msg.sender), "Roles: unpermitted action");
		_;
	}

	// Owner is also permitted to admin's actions
	modifier onlyAdmin()
	{
		require(hasRole(ROLE_ADMINISTRATOR, msg.sender) || hasRole(ROLE_OWNER, msg.sender),
			"Roles: unpermitted action");
		_;
	}

	function setOwner(address account, bool isOwner) external onlyOwner
	{
		require(account != address(0), "Roles: invalid account");

		if (isOwner) _grantRole(ROLE_OWNER, account);
		else _revokeRole(ROLE_OWNER, account);
	}

	function setAdministrator(address account, bool isAdmin) external onlyOwner
	{
		require(account != address(0), "Roles: invalid account");
		
		if (isAdmin) _grantRole(ROLE_ADMINISTRATOR, account);
		else _revokeRole(ROLE_ADMINISTRATOR, account);
	}


	// To protect from such case when contract leave without any owner
	function _revokeRole(bytes32 role, address account) internal virtual override
	{
		// Owner cannot self renounce ownership
		require(role != ROLE_OWNER || account != msg.sender,
			'Roles: self renounce from ownership');

		super._revokeRole(role, account);
	}
}