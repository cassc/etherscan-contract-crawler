// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPoolRewards {
    /// Emitted after reward added
    event RewardAdded(address indexed rewardToken, uint256 reward, uint256 rewardDuration);
    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);
    /// Emitted after adding new rewards token into rewardTokens array
    event RewardTokenAdded(address indexed rewardToken, address[] existingRewardTokens);

    function claimReward(address) external;

    function notifyRewardAmount(address rewardToken_, uint256 _rewardAmount, uint256 _rewardDuration) external;

    function notifyRewardAmount(
        address[] memory rewardTokens_,
        uint256[] memory rewardAmounts_,
        uint256[] memory rewardDurations_
    ) external;

    function updateReward(address) external;

    function claimable(
        address account_
    ) external view returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts);

    function lastTimeRewardApplicable(address rewardToken_) external view returns (uint256);

    function rewardForDuration()
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardForDuration);

    function rewardPerToken()
        external
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardPerTokenRate);

    function getRewardTokens() external view returns (address[] memory);

    function isRewardToken(address) external view returns (bool);

    function addRewardToken(address newRewardToken_) external;

    function periodFinish(address) external view returns (uint256);
}