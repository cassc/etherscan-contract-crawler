// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Rewards Pool
/// @notice RewardsPool accepts a single reward token and releases it to the
///         AssetPool over time in one week reward intervals. The owner of this
///         contract is the reward distribution address funding it with reward
///         tokens.
contract RewardsPool is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant DURATION = 7 days;

    IERC20 public immutable rewardToken;
    address public immutable assetPool;

    // timestamp of the current reward interval end or the timestamp of the
    // last interval end in case a new reward interval has not been allocated
    uint256 public intervalFinish = 0;
    // rate per second with which reward tokens are unlocked
    uint256 public rewardRate = 0;
    // amount of rewards accumulated and not yet withdrawn from the previous
    // reward interval(s)
    uint256 public rewardAccumulated = 0;
    // the last time information in this contract was updated
    uint256 public lastUpdateTime = 0;

    event RewardToppedUp(uint256 amount);
    event RewardWithdrawn(uint256 amount);

    constructor(
        IERC20 _rewardToken,
        address _assetPool,
        address owner
    ) {
        rewardToken = _rewardToken;
        // slither-disable-next-line missing-zero-check
        assetPool = _assetPool;
        transferOwnership(owner);
    }

    /// @notice Transfers the provided reward amount into RewardsPool and
    ///         creates a new, one-week reward interval starting from now.
    ///         Reward tokens from the previous reward interval that unlocked
    ///         over the time will be available for withdrawal immediately.
    ///         Reward tokens from the previous interval that has not been yet
    ///         unlocked, are added to the new interval being created.
    /// @dev This function can be called only by the owner given that it creates
    ///      a new interval with one week length, starting from now.
    function topUpReward(uint256 reward) external onlyOwner {
        rewardAccumulated = earned();

        /* solhint-disable not-rely-on-time */
        if (block.timestamp >= intervalFinish) {
            // see https://github.com/crytic/slither/issues/844
            // slither-disable-next-line divide-before-multiply
            rewardRate = reward / DURATION;
        } else {
            uint256 remaining = intervalFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }
        intervalFinish = block.timestamp + DURATION;
        lastUpdateTime = block.timestamp;
        /* solhint-enable avoid-low-level-calls */

        emit RewardToppedUp(reward);
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
    }

    /// @notice Withdraws all unlocked reward tokens to the AssetPool.
    function withdraw() external {
        uint256 amount = earned();
        rewardAccumulated = 0;
        lastUpdateTime = lastTimeRewardApplicable();
        emit RewardWithdrawn(amount);
        rewardToken.safeTransfer(assetPool, amount);
    }

    /// @notice Returns the amount of earned and not yet withdrawn reward
    /// tokens.
    function earned() public view returns (uint256) {
        return
            rewardAccumulated +
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate);
    }

    /// @notice Returns the timestamp at which a reward was last time applicable.
    ///         When reward interval is pending, returns current block's
    ///         timestamp. If the last reward interval ended and no other reward
    ///         interval had been allocated, returns the last reward interval's
    ///         end timestamp.
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, intervalFinish);
    }
}