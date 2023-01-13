// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Sweepable is Ownable {
	using SafeERC20 for IERC20;

	event SweepToken(address indexed token, uint256 amount);
	event SweepNative(uint256 amount);

	constructor() {}

	// Sweep an ERC20 token to the owner
	function sweepToken(IERC20 token) external onlyOwner {
		uint256 amount = token.balanceOf(address(this));
		token.safeTransfer(owner(), amount);
		emit SweepToken(address(token), amount);
	}

	function sweepToken(IERC20 token, uint256 amount) external onlyOwner {
		token.safeTransfer(owner(), amount);
		emit SweepToken(address(token), amount);
	}

	// sweep native token to the owner
	function sweepNative() external onlyOwner {
		uint256 amount = address(this).balance;
		(bool success, ) = owner().call{ value: amount }("");
		require(success, "Transfer failed.");
		emit SweepNative(amount);
	}

	function sweepNative(uint256 amount) external onlyOwner {
		(bool success, ) = owner().call{ value: amount }("");
		require(success, "Transfer failed.");
		emit SweepNative(amount);
	}
}