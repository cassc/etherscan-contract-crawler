// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

import './Roles.sol';

contract TeamRole is Context {
	using Roles for Roles.Role;

	event TeamAdded(address indexed account);
	event TeamRemoved(address indexed account);

	Roles.Role private _teams;

	constructor() public {
		_addTeam(_msgSender());
	}

	modifier isTeam() {
		require(_isTeam(_msgSender()), 'AdminRole: caller does not have the Minter role');
		_;
	}

	function _isTeam(address account) public view returns (bool) {
		return _teams.has(account);
	}

	function addTeam(address account) public virtual isTeam {
		_addTeam(account);
	}

	function renounceTeamMembership() public {
		_removeTeam(_msgSender());
	}

	function _addTeam(address account) internal  {
		_teams.add(account);
		emit TeamAdded(account);
	}

	function _removeTeam(address account) internal {
		_teams.remove(account);
		emit TeamRemoved(account);
	}
}