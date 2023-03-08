// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IWhitelist.sol";

abstract contract Whitelist is IWhitelist {

	bytes4 public constant METHOD_HASROLE = 0x95a8c58d; // function hasRole(address member, uint8 role)
	
	WhitelistStruct public whitelist;
	mapping (address => bool) _whitelist;
	
	function whitelisted(address member) public view returns(bool) {
		// if will not useWhitelist then will always return true
		if (!whitelist.useWhitelist) {
			return true;
		}

		// using internal whitelist if whitelist.contractAddress == address(0)
		if (whitelist.useWhitelist && whitelist.contractAddress == address(0)) {
			return _whitelist[member];
		}

		// else try to get external info
		bool success;
		bytes memory data;
		if (whitelist.role == 0) {
			(success, data) = whitelist.contractAddress.staticcall(abi.encodeWithSelector(whitelist.method, member));
		} else {
			(success, data) = whitelist.contractAddress.staticcall(abi.encodeWithSelector(METHOD_HASROLE, member, whitelist.role));
		}
		if (!success) {
			return false;
		}
		return abi.decode(data, (bool));
	}

	function whitelistInit(WhitelistStruct memory _whitelistStruct) internal {
		whitelist.contractAddress = _whitelistStruct.contractAddress;
        whitelist.method = _whitelistStruct.method;
        whitelist.role = _whitelistStruct.role;
        whitelist.useWhitelist = _whitelistStruct.useWhitelist;
	}

	function _whitelistAdd(address account) internal {
		_whitelist[account] = true;
	}

	function _whitelistRemove(address account) internal {
		delete _whitelist[account];
	}
}