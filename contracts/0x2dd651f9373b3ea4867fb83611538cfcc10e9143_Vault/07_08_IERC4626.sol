// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';

/// @notice https://eips.ethereum.org/EIPS/eip-4626
interface IERC4626 {
	event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

	event Withdraw(
		address indexed caller,
		address indexed receiver,
		address indexed owner,
		uint256 assets,
		uint256 shares
	);

	function asset() external view returns (ERC20);

	function totalAssets() external view returns (uint256 assets);

	function convertToShares(uint256 assets) external view returns (uint256 shares);

	function convertToAssets(uint256 shares) external view returns (uint256 assets);

	function maxDeposit(address receiver) external view returns (uint256 assets);

	function previewDeposit(uint256 assets) external view returns (uint256 shares);

	function deposit(uint256 assets, address receiver) external returns (uint256 shares);

	function maxMint(address receiver) external view returns (uint256 shares);

	function previewMint(uint256 shares) external view returns (uint256 assets);

	function mint(uint256 shares, address receiver) external returns (uint256 assets);

	function maxWithdraw(address owner) external view returns (uint256 assets);

	function previewWithdraw(uint256 assets) external view returns (uint256 shares);

	function withdraw(
		uint256 assets,
		address receiver,
		address owner
	) external returns (uint256 shares);

	function maxRedeem(address owner) external view returns (uint256 shares);

	function previewRedeem(uint256 shares) external view returns (uint256 assets);

	function redeem(
		uint256 shares,
		address receiver,
		address owner
	) external returns (uint256 assets);
}