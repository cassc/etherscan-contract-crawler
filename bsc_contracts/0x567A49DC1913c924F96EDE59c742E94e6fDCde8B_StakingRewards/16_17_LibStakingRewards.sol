// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IStakingRewards} from "./IStakingRewards.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Library for simple staking of a token to receive staking rewards.
 *
 * The library is based of Synthetix staking contract's simplified version (by https://twitter.com/ProgrammerSmart)
 * See: https://solidity-by-example.org/defi/staking-rewards/
 */
library LibStakingRewards {
    using SafeERC20 for IERC20;

    struct Storage {
        IERC20 stakingToken;
        IERC20 rewardsToken;
        // Timestamp of when the rewards finish
        uint32 finishedAt;
        // Minimum of last updated time and reward finish time
        uint32 updatedAt;
        // Duration of rewards to be paid out (in seconds)
        uint32 duration;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardsPerTokenStored;
        // Total staked
        uint256 totalSupply;
        // Total amount of rewards ever added
        uint256 totalRewardsAdded;
        // Total amount of rewards ever claimed
        uint256 totalRewardsClaimed;
        // Amount of staked tokens by a user
        mapping(address => uint256) balanceOf;
        // User address => rewardsPerTokenStored
        mapping(address => uint256) userRewardsPerTokenPaid;
        // Total amount of rewards claimed by user
        mapping(address => uint256) userRewardsClaimed;
        // User address => rewards to be claimed
        mapping(address => uint256) rewards;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarlabs.modules.orb-staking.LibStakingRewards");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            s.slot := slot
        }
        // solhint-enable
    }

    /**
     * @dev Emitted when the duration is updated.
     */
    event StakingRewardsDurationUpdated(uint32 duration);

    /**
     * @dev Emitted when new rewards are added to the rewards pool.
     */
    event StakingRewardsAdded(uint256 amount);

    /**
     * @dev Emitted when a user stakes tokens.
     */
    event StakingRewardsStaked(address account, uint256 amount);

    /**
     * @dev Emitted when a user unstakes tokens.
     */
    event StakingRewardsUnstaked(address account, uint256 amount);

    /**
     * @dev Emitted when a user claims staking rewards.
     */
    event StakingRewardsClaimed(address account, uint256 amount);

    /**
     * @dev Stakes the `amount` of `stakingToken` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to stake
     */
    function stake(address account, uint256 amount) internal {
        if (amount == 0) revert IStakingRewards.StakingRewardsAmountIdsZero();

        Storage storage s = _storage();

        _updateRewards(account);

        // slither-disable-next-line arbitrary-send-erc20,unchecked-transfer
        s.stakingToken.transferFrom(account, address(this), amount);
        s.balanceOf[account] += amount;
        s.totalSupply += amount;

        emit StakingRewardsStaked(account, amount);
    }

    /**
     * @dev Unstakes the `amount` of `stakingToken` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to stake
     */
    function unstake(address account, uint256 amount) internal {
        if (amount == 0) revert IStakingRewards.StakingRewardsAmountIdsZero();

        Storage storage s = _storage();

        _updateRewards(account);

        s.balanceOf[account] -= amount;
        s.totalSupply -= amount;
        // slither-disable-next-line unchecked-transfer
        s.stakingToken.transfer(account, amount);

        emit StakingRewardsUnstaked(account, amount);
    }

    /**
     * @dev Claims the `account`'s pending rewards.
     *
     * @param account Address of the account.
     */
    function claimRewards(address account) internal {
        Storage storage s = _storage();

        _updateRewards(account);

        uint256 rewards = s.rewards[account];
        if (rewards > 0) {
            s.rewards[account] = 0;
            s.totalRewardsClaimed += rewards;
            s.userRewardsClaimed[account] += rewards;
            // slither-disable-next-line arbitrary-send-erc20
            s.rewardsToken.safeTransfer(account, rewards);
        }

        emit StakingRewardsClaimed(account, rewards);
    }

    /**
     * @dev Returns the amount of rewards the `account` can claim.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function rewardsOf(address account) internal view returns (uint256) {
        Storage storage s = _storage();

        return
            ((s.balanceOf[account] *
                (rewardPerToken() - s.userRewardsPerTokenPaid[account])) /
                1e18) + s.rewards[account];
    }

    /**
     * @dev Returns the amount of tokens staked by `account`.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of tokens staked by `account`.
     */
    function balanceOf(address account) internal view returns (uint256) {
        return _storage().balanceOf[account];
    }

    /**
     * @dev Returns the last timestamp when rewards where applicable.
     * Current timestamp if the reward duration is not finished yet, `finishedAt` otherwise.
     *
     * @return timestamp The smaller of the 2 timestamps.
     */
    function lastTimeRewardApplicable()
        internal
        view
        returns (uint32 timestamp)
    {
        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        timestamp = uint32(block.timestamp % 2 ** 32);
        // solhint-enable
        uint32 finishedAt = _storage().finishedAt;

        if (finishedAt < timestamp) {
            timestamp = finishedAt;
        }
    }

    /**
     * @dev Calculates the reward amount per token.
     *
     * @return rewardPerToken The calculated rewardPerToken amount.
     */
    function rewardPerToken() internal view returns (uint256) {
        Storage storage s = _storage();

        if (s.totalSupply == 0) {
            return s.rewardsPerTokenStored;
        }

        return
            s.rewardsPerTokenStored +
            (s.rewardRate * (lastTimeRewardApplicable() - s.updatedAt) * 1e18) /
            s.totalSupply;
    }

    /**
     * @dev Notifies the rewards pool about new tokens added.
     *
     * @param amount Amount of `rewardsToken` added to the pool.
     */
    function notifyRewardAmount(uint256 amount) internal {
        Storage storage s = _storage();

        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        // solhint-enable

        _updateRewards(address(0));

        if (block.timestamp >= s.finishedAt) {
            s.rewardRate = amount / s.duration;
        } else {
            uint256 remainingRewards = (s.finishedAt - blockTimestamp) *
                s.rewardRate;
            s.rewardRate = (amount + remainingRewards) / s.duration;
        }

        if (s.rewardRate == 0) {
            revert IStakingRewards.StakingRewardsRewardRateIsZero();
        }

        if (
            s.rewardRate * s.duration > s.rewardsToken.balanceOf(address(this))
        ) {
            revert IStakingRewards.StakingRewardsBalanceTooLow();
        }

        s.finishedAt = blockTimestamp + s.duration;
        s.updatedAt = blockTimestamp;
        s.totalRewardsAdded += amount;

        emit StakingRewardsAdded(amount);
    }

    /**
     * @dev Initialize the staking rewards
     */
    function initialize(address stakingToken, address rewardsToken) internal {
        _storage().stakingToken = IERC20(stakingToken);
        _storage().rewardsToken = IERC20(rewardsToken);
    }

    /**
     * @dev Updates the duration of rewards distribution.
     * Emits an {StakingRewardsDurationUpdated} event.
     *
     * @param duration The new duration.
     */
    function setRewardsDuration(uint32 duration) internal {
        Storage storage s = _storage();

        // solhint-disable-next-line not-rely-on-time
        if (s.finishedAt >= block.timestamp) {
            revert IStakingRewards.StakingRewardsDurationNotFinished();
        }

        s.duration = duration;

        emit StakingRewardsDurationUpdated(duration);
    }

    function getUserRewardsClaimed(
        address account
    ) internal view returns (uint256) {
        return _storage().userRewardsClaimed[account];
    }

    function getStakingToken() internal view returns (IERC20 stakingToken) {
        return _storage().stakingToken;
    }

    function getRewardsToken() internal view returns (IERC20 rewardsToken) {
        return _storage().rewardsToken;
    }

    function getInfoResponse()
        internal
        view
        returns (IStakingRewards.StakingRewardsInfoResponse memory response)
    {
        Storage storage s = _storage();

        response = IStakingRewards.StakingRewardsInfoResponse({
            stakingToken: address(s.stakingToken),
            rewardsToken: address(s.rewardsToken),
            finishedAt: s.finishedAt,
            updatedAt: s.updatedAt,
            duration: s.duration,
            rewardRate: s.rewardRate,
            rewardsPerTokenStored: s.rewardsPerTokenStored,
            totalSupply: s.totalSupply,
            totalRewardsAdded: s.totalRewardsAdded,
            totalRewardsClaimed: s.totalRewardsClaimed
        });
    }

    /**
     * Updates the `account`'s rewards and `rewardsPerTokenStored`.
     *
     * @param account Address of the account.
     */
    function _updateRewards(address account) private {
        Storage storage s = _storage();

        s.rewardsPerTokenStored = rewardPerToken();
        s.updatedAt = lastTimeRewardApplicable();

        if (account != address(0)) {
            s.rewards[account] = rewardsOf(account);
            s.userRewardsPerTokenPaid[account] = s.rewardsPerTokenStored;
        }
    }
}