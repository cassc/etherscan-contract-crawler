// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice V1 Staking Interface
interface FraxStakingRewardsMultiGauge {
    // Locked liquidity for a given account
    function lockedLiquidityOf(address account) external view returns (uint256);

    // Total 'balance' used for calculating the percent of the pool the account owns
    // Takes into account the locked stake time multiplier
    function totalCombinedWeight() external view returns (uint256);

    // Total locked liquidity tokens
    function totalLiquidityLocked() external view returns (uint256);

    // Combined weight for a specific account
    function combinedWeightOf(address account) external view returns (uint256);

    function getReward() external returns (uint256[] memory);

    // Get the amount of FRAX 'inside' of the lp tokens
    function fraxPerLPToken() external view returns (uint256);

    function userStakedFrax(address account) external view returns (uint256);

    function minVeFXSForMaxBoost(address account) external view returns (uint256);

    function veFXSMultiplier(address account) external view returns (uint256);

    // Calculated the combined weight for an account
    function calcCurCombinedWeight(address account)
        external
        view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        );

    // All the reward tokens
    function getAllRewardTokens() external view returns (address[] memory);

    // Multiplier amount, given the length of the lock
    function lockMultiplier(uint256 secs) external view returns (uint256);

    function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

    // Amount of reward tokens per LP token
    function rewardsPerToken() external view returns (uint256[] memory newRewardsPerTokenStored);

    function stakeLocked(uint256 liquidity, uint256 secs) external;

    function withdrawLocked(bytes32 kek_id) external;
}