// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IRewardVault {

	function updateVault(uint256, uint256, uint256) external;

	function claim() external;

	function pending(uint256) view external returns (uint256);

	function pending(address) view external returns (uint256);

	struct UserInfo {
		uint256 accRewardPerLiquidity; // last updated accRewardPerLiquidity when the user triggered claim/update ops
		uint256 unclaimed; // the unclaimed reward
	}

	function userInfo(uint256) external view returns (UserInfo memory);

	function lastRewardTimestamp() external view returns (uint256);

	function accRewardPerLiquidity() external view returns (uint256);

	function rewardPerSecond() external view returns (uint256);
}