// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;


interface IRewardVault {

	struct UserInfo {
		uint256 accRewardPerB0Liquidity; // last updated accRewardPerB0Liquidity when the user triggered claim/update ops
		uint256 accRewardPerBXLiquidity; // last updated accRewardPerBXLiquidity when the user triggered claim/update ops
		uint256 unclaimed; // the unclaimed reward
		uint256 liquidityB0;
	}

	function updateVault(uint256, uint256, uint256, uint256, int256) external;

	function initializeAave(address) external;

	function initializeFromAaveA(address) external;

	function initializeFromAaveB(address, address, uint256, uint256) external;

	function initializeVenus(address) external;

	function initializeFromVenus(address, address) external;

	function initializeLite(address, address) external;

	function setRewardPerSecond(address, uint256) external;

	function emergencyWithdraw(address) external;

	function claim(address) external;

	function pending(address, uint256) view external returns (uint256);

	function pending(address, address) view external returns (uint256);

	function getRewardPerLiquidityPerSecond(address) view external returns (uint256, uint256);

	function getUserInfo(address, address) view external returns (UserInfo memory);

	function getTotalLiquidityB0(address) view external returns (uint256);

	function getAccRewardPerB0Liquidity(address) view external returns (uint256);

	function getAccRewardPerBXLiquidity(address) view external returns (uint256);

	function getVaultBalance(uint256) view external returns (uint256, int256);

	function getPendingPerPool(address) view external returns (uint256);

}