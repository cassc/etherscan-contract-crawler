// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IMasterChef
{
	function bankroll() external view returns (address _bankroll);
	function poolInfo(uint256 _pid) external view returns (address _token, uint256 _allocPoint, uint256 _lastRewardTime, uint256 _accRewardPerShare, uint256 _amount, uint256 _depositFee, uint256 _withdrawalFee, uint256 _epochAccRewardPerShare);
	function userInfo(uint256 _pid, address _account) external view returns (uint256 _amount, uint256 _rewardDebt, uint256 _unclaimedReward);

	function depositOnBehalfOf(uint256 _pid, uint256 _amount, address _account, address _referral) external;
}