// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

contract Whitelistable
{
	mapping(address => bool) public whitelist;

	modifier onlyWhitelisted
	{
		require(whitelist[msg.sender], "access denied");
		_;
	}

	function _setWhitelist(address _account, bool _enabled) internal
	{
		whitelist[_account] = _enabled;
		emit Whitelisted(_account, _enabled);
	}

	event Whitelisted(address indexed _account, bool indexed _enabled);
}