// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';

contract Config is Ownable {
	uint256 public defaultSlippage = 5000; // 0.5%

	uint256 public LTV = 0.65e4; // 6500 => 65%

	constructor() {}

	function setDefaultSlippage(uint256 s) public onlyOwner {
		defaultSlippage = s;
	}

	function setLTV(uint256 l) public onlyOwner {
		LTV = l;
	}
}