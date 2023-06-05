// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Authority.sol";


contract BigFoot is ERC20("BigFoot", "BGFT"), Authority {
	uint public constant maxSupply = 50_000_000_000 * 10**18;

	mapping(address => bool) public isBlacklisted;

	constructor(address _supplyHolder) {
		_mint(_supplyHolder, maxSupply);
	}

	// Modifiers
	modifier isAuthorized(address addr) {
		require(!isBlacklisted[addr], "BigFoot: Blacklisted");
		_;
	}

	// Setters
	function setIsBlacklisted(address _new, bool _value) external onlyAuthority {
		isBlacklisted[_new] = _value;
	}

	// Overrides
	function _transfer(
		address from,
		address to,
		uint256 amount
	)
		internal
		override
		isAuthorized(from)
		isAuthorized(to)
	{
		super._transfer(from, to, amount);
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	)
		internal
		override
		isAuthorized(owner)
		isAuthorized(spender)
	{
		super._approve(owner, spender, amount);
	}
}