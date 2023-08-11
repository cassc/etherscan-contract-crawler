// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUncleFocusStrategy {
    function notifyRewardAmount() external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setDistributor(address _distributor) external;

    function getReward() external;

    function withdraw(uint256 amount) external;

    function stake(uint256 amount) external;

    function getRewardForDuration() external view returns (uint256);

    function earned() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function totalSupplyWithRewards() external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);

    function rewards() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function owner() external view returns (address);

    function redeemRewards(
        uint256 epoch,
        uint256[] calldata rewardIndexes
    ) external;
}