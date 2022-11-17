// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMintableToken {
	function mint(address recipient_, uint256 amount_) external returns (bool);
}