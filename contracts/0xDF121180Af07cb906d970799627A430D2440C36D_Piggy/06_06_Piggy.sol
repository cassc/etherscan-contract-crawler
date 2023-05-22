// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//         Oink             Oink oink 
//           \                  \
//
//           (\___/)            (\___/)
//           / _"_ \________    / _"_ \________
//          ( (o o) )       \9 ( (o o) )       \9
//           \__^__/         \  \__O__/         \
//          _.::::::::::::::::::._\  __         /
//          \"""""""""""""""\""""/ (_ (___)_(___)
//           \_______________\__/   )_/)_/)_/)_/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Piggy is ERC20("PIGGY", "PIGGY"), Ownable {
	mapping(address => bool) public isCooldownExempt;
	mapping(address => uint) public cooldowns;
	uint public MEV_COOLDOWN = 1;

	constructor() {
		_mint(msg.sender, 1_000_000_000 ether);
		isCooldownExempt[msg.sender] = true;
	}

	function setIsCooldownExempt(address[] calldata addrs, bool value) external onlyOwner {
		for (uint i; i < addrs.length; ++i) isCooldownExempt[addrs[i]] = value;
	}

	function setMEV_COOLDOWN(uint value) external onlyOwner {
		assert(value <= 10); // ~2min
		MEV_COOLDOWN = value;
	}

	function _beforeTokenTransfer(address from, address to,	uint256) internal override {
		if (!isCooldownExempt[from]) require(cooldowns[from] + MEV_COOLDOWN <= block.number, "MEV protection");
		if (!isCooldownExempt[to]) cooldowns[to] = block.number;
	}
}