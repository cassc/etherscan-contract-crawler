// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IRewardEscrow.sol";

interface IStakingRewards {
    // Views
    function earned(address account, address token)
        external
        view
        returns (uint256);

    function getRewardForDuration(address token)
        external
        view
        returns (uint256);

    function getRewardTokens() external view returns (address[] memory tokens);

    function getRewardTokensCount() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime(address) external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewardEscrow() external view returns (IRewardEscrow);

    function rewardInfo(address)
        external
        view
        returns (
            uint256 rewardRate,
            uint256 rewardPerTokenStored,
            uint256 totalRewardAmount,
            uint256 remainingRewardAmount
        );

    function rewardPerToken(address token) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewardsAreEscrowed() external view returns (bool);

    function rewardsDuration() external view returns (uint256);

    function stakedBalanceOf(address account) external view returns (uint256);

    function stakedTotalSupply() external view returns (uint256);

    // Mutative
    function claimReward() external;

    function initializeReward(uint256 rewardAmount, address token) external;

    function setRewardsDuration(uint256 _rewardsDuration) external;
}