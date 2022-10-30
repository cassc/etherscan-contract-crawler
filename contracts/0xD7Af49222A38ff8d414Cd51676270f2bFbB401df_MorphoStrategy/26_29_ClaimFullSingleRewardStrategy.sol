// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./RewardStrategy.sol";
import "../shared/SwapHelperMainnet.sol";

/**
 * @notice Claim full single reward strategy logic
 */
abstract contract ClaimFullSingleRewardStrategy is RewardStrategy, SwapHelperMainnet {
    /* ========== STATE VARIABLES ========== */

    IERC20 internal immutable rewardToken;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _rewardToken Reward token contract
     */
    constructor(
        IERC20 _rewardToken
    ) {
        require(address(_rewardToken) != address(0), "ClaimFullSingleRewardStrategy::constructor: Token address cannot be 0");
        rewardToken = _rewardToken;
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Claim rewards
     * @param swapData Slippage and path array
     * @return Rewards
     */
    function _claimRewards(SwapData[] calldata swapData) internal override returns(Reward[] memory) {
        return _claimSingleRewards(type(uint128).max, swapData);
    }

    /**
     * @dev Claim fast withdraw rewards
     * @param shares Amount of shares
     * @param swapData Swap slippage and path
     * @return Rewards
     */
    function _claimFastWithdrawRewards(uint128 shares, SwapData[] calldata swapData) internal override returns(Reward[] memory) {
        return _claimSingleRewards(shares, swapData);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Claim single rewards
     * @param shares Amount of shares
     * @param swapData Swap slippage and path
     * @return rewards Collected reward amounts
     */
    function _claimSingleRewards(uint128 shares, SwapData[] calldata swapData) private returns(Reward[] memory rewards) {
        if (swapData.length > 0 && swapData[0].slippage > 0) {
            uint128 rewardAmount = _claimStrategyReward();

            if (rewardAmount > 0) {
                Strategy storage strategy = strategies[self];

                uint128 claimedAmount = _getRewardClaimAmount(shares, rewardAmount);

                rewards = new Reward[](1);
                rewards[0] = Reward(claimedAmount, rewardToken);

                // if we don't claim all the rewards save the amount left, otherwise reset amount left to 0
                if (rewardAmount > claimedAmount) {
                    uint128 rewardAmountLeft = rewardAmount - claimedAmount;
                    strategy.pendingRewards[address(rewardToken)] = rewardAmountLeft;
                } else if (strategy.pendingRewards[address(rewardToken)] > 0) {
                    strategy.pendingRewards[address(rewardToken)] = 0;
                }
            }
        }
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    function _claimStrategyReward() internal virtual returns(uint128);
}