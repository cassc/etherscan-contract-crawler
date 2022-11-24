// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

import './Roles.sol';

contract AdminRole is Context {
	using Roles for Roles.Role;

	event AdminAdded(address indexed account);
	event AdminRemoved(address indexed account);

	Roles.Role private _admins;

	constructor() public {
		_addAdmin(_msgSender());
	}

	modifier onlyAdmin() {
		require(isAdmin(_msgSender()), 'AdminRole: caller does not have the Minter role');
		_;
	}

	function isAdmin(address account) public view returns (bool) {
		return _admins.has(account);
	}

	function addAdmin(address account) public virtual onlyAdmin {
		_addAdmin(account);
	}

	function renounceAdmin() public {
		_removeAdmin(_msgSender());
	}

	function _addAdmin(address account) internal  {
		_admins.add(account);
		emit AdminAdded(account);
	}

	function _removeAdmin(address account) internal {
		_admins.remove(account);
		emit AdminRemoved(account);
	}
}