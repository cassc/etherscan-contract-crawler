// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICerc20 {
	function underlying() external view returns (address token);

	function getAccountSnapshot(address account)
		external
		view
		returns (
			uint256 errorCode,
			uint256 balance,
			uint256 borrowed,
			uint256 exchangeRate
		);

	function mint(uint256 assetAmount) external returns (uint256 errorCode);

	function redeem(uint256 cTokenAmount) external returns (uint256 errorCode);

	function borrow(uint256 assetAmount) external returns (uint256 errorCode);

	function repayBorrow(uint256 assetAmount) external returns (uint256 errorCode);

	function redeemUnderlying(uint256 assetAmount) external returns (uint256 errorCode);

	function balanceOfUnderlying(address account) external returns (uint256 assetAmount);

	function borrowBalanceCurrent(address account) external returns (uint256 assetAmount);
}