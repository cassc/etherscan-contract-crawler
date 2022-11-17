// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import './IMintableToken.sol';

interface IShare is IMintableToken {
	function mintLimitOf(address minter_) external view returns (uint256);

	function mintedAmountOf(address minter_) external view returns (uint256);

	function canMint(address mint_, uint256 amount)
		external
		view
		returns (bool);
}