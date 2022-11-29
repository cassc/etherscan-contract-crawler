// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9;

interface IERC20NonTransferable {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address _owner) external view returns (uint256 balance);
}