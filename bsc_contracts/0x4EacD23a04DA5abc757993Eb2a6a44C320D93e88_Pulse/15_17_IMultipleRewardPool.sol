// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with multiple reward pool contracts.
*/
interface IMultipleRewardPool {
    function notifyRewardAmount(
        address rewardToken,
        uint256 reward
    )
        external;
    function stake(uint256 amount) external;
    function getReward() external;
    function getBalance(address user) external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function withdraw(uint256 amount) external;
}