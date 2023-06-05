// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


contract Authority {
	
	address[] public authorities;
	mapping(address => bool) public isAuthority;

	constructor() {
		authorities.push(msg.sender);
		isAuthority[msg.sender] = true;
	}

	modifier onlySuperAuthority() {
		require(authorities[0] == msg.sender, "Authority: Only Super Authority");
		_;
	}
	
	modifier onlyAuthority() {
		require(isAuthority[msg.sender], "Authority: Only Authority");
		_;
	}

	function addAuthority(address _new, bool _change) external onlySuperAuthority {
		require(!isAuthority[_new], "Authoritys: Already authority");
		isAuthority[_new] = true;
		if (_change) {
			authorities.push(authorities[0]);
			authorities[0] = _new;
		} else {
			authorities.push(_new);
		}
	}

	function removeAuthority(address _new) external onlySuperAuthority {
		require(isAuthority[_new], "Authority: Not authority");
		require(_new != authorities[0], "Authority: Cannot remove super authority");
		for (uint i = 1; i < authorities.length; i++) {
			if (authorities[i] == _new) {
				authorities[i] = authorities[authorities.length - 1];
				authorities.pop();
				break;
			}
		}
		isAuthority[_new] = false;
	}

	function getAuthoritiesSize() external view returns(uint) {
		return authorities.length;
	}
}