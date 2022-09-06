/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2022 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {ISeason} from './ISeason.sol';
import {ISeries} from './Series.sol';

/**
 * @title Story Season staking contract
 * @notice Season logic contract to calculate rewards of stakers
 */
contract Season is ISeason {
    struct User {
        bool exists;
        uint128 points;
    }

    struct SeasonMeta {
        bool bootstrapped;
        bool snapshotTaken;
        uint128 totalPoints;
    }

    // Final rewards values taken at end of season
    struct Snapshot {
        uint128 rewardETH;
        uint128 rewardOGN;
    }

    ISeries public immutable series;

    uint256 public immutable override startTime;
    uint256 public immutable override lockStartTime;
    uint256 public immutable override endTime;
    uint256 public immutable override claimEndTime;

    SeasonMeta public season;
    Snapshot public snapshot;
    mapping(address => User) public users;

    /**
     * @dev User has staked
     * @param userAddress - address of the user
     * @param amount - amount of OGN staked
     * @param points - points user received for this stake
     */
    event Stake(
        address indexed userAddress,
        uint256 indexed amount,
        uint256 points
    );

    /**
     * @dev User has unstaked
     * @param userAddress - address of the user
     */
    event Unstake(address indexed userAddress);

    /**
     * @dev Staking period has ended and reward snapshot taken
     * @param totalRewardETH - Total ETH reward to split amongst stakers
     * @param totalRewardOGN - Total OGN reward to split amongst stakers
     */
    event Finale(uint256 totalRewardETH, uint256 totalRewardOGN);

    /**
     * @param series_ - The Series staking and registry contract
     * @param startTime_ - Timestamp starting this season
     * @param lockStartTime_ - Timestamp at which new stakes are no longer
            accepted
     * @param endTime_ - Timestamp ending this season
     * @param claimEndTime_ - Timestamp at which users can no longer claim
     *      profit share and rewards
     */
    constructor(
        address series_,
        uint256 startTime_,
        uint256 lockStartTime_,
        uint256 endTime_,
        uint256 claimEndTime_
    ) {
        series = ISeries(series_);
        startTime = startTime_;
        endTime = endTime_;
        lockStartTime = lockStartTime_;
        claimEndTime = claimEndTime_;

        require(startTime_ > block.timestamp, 'Season: Invalid startTime');
        require(lockStartTime_ > startTime_, 'Season: Invalid lockStartTime');
        require(endTime_ > lockStartTime_, 'Season: Invalid endTime');
        require(claimEndTime_ > endTime_, 'Season: Invalid claimEndTime');
    }

    // @dev only execute if sender is the Series contract
    modifier onlySeries() {
        require(msg.sender == address(series), 'Season: Not series contract');
        _;
    }

    ///
    /// Externals
    ///

    /**
     * @dev Calculate the points a user would receive if they staked at a
     *      specific block timestamp.
     * @param amount - The amount of OGN they would stake
     * @param blockStamp - The block timestamp to calculate for
     * @return points. 0 if out of season.
     */
    function pointsInTime(uint256 amount, uint256 blockStamp)
        external
        view
        override
        returns (uint128)
    {
        return _pointsInTime(amount, blockStamp);
    }

    /**
     * @notice Total points for a user's stake
     * @param userAddress - address for which to return their points
     * @return total points
     */
    function getPoints(address userAddress)
        external
        view
        override
        returns (uint128)
    {
        User memory user = _initMemUser(userAddress);
        return user.points;
    }

    /**
     * @notice Total points of all stakes
     * @return total points of all users' stakes
     */
    function getTotalPoints() external view override returns (uint128) {
        if (season.bootstrapped) {
            return season.totalPoints;
        } else if (block.timestamp >= startTime) {
            // Any new stakes should trigger a bootstrap using these same
            // numbers.  This is just a convenience for early season fetch
            // before new stakes.
            uint256 stakedOGN = series.totalSupply();
            return _pointsInTime(stakedOGN, startTime);
        }

        return 0;
    }

    /**
     * @notice Return the expected rewards for a user.
     * @dev This will return zero values if outside the claim period.
     *
     * @param userAddress - Address for the user to calculate
     * @return ethShare - Amount of ETH a user would receive if claimed now
     * @return ognRewards - Amount of OGN a user would receive if claimed now
     */
    function expectedRewards(address userAddress)
        external
        view
        override
        returns (uint256, uint256)
    {
        if (
            block.timestamp < endTime ||
            block.timestamp >= claimEndTime ||
            season.totalPoints == 0
        ) {
            return (0, 0);
        }

        User memory user = _initMemUser(userAddress);

        // Include the vault balance if it hasn't been collected
        address vault = series.vault();
        uint256 ethBalance = season.snapshotTaken
            ? snapshot.rewardETH
            : vault.balance;
        uint256 ognBalance = season.snapshotTaken
            ? snapshot.rewardOGN
            : IERC20(series.ogn()).balanceOf(vault);

        uint256 ethShare = _calculateShare(user.points, ethBalance);
        uint256 ognRewards = _calculateShare(user.points, ognBalance);

        return (ethShare, ognRewards);
    }

    /**
     * @notice Stake OGN for a share of ETH profits and OGN rewards
     * @dev This may be called multiple times and the amount returned will
     *      be for the user's totals, not the amount for this specific call.
     *
     * @param userAddress - the user staking their OGN
     * @param amount - the amount of (st)OGN being staked
     * @return total points received for the user's stake
     */
    function stake(address userAddress, uint256 amount)
        external
        override
        onlySeries
        returns (uint128)
    {
        require(amount > 0, 'Season: No incoming OGN');
        // Bootstrapping should have happened before we got here
        require(season.bootstrapped, 'Season: Season not bootstrapped.');

        // calculate stake points
        uint128 points = _pointsInTime(amount, block.timestamp);

        User memory user = _initMemUser(userAddress);

        // Update season and user points
        season.totalPoints += points;
        user.points += points;

        // Store user (updates may have also come from _initMemUser())
        users[userAddress] = user;

        emit Stake(userAddress, amount, user.points);

        return user.points;
    }

    /**
     * @notice Calculate and return  ETH profit share and OGN rewards and zero
     *      out the user's stake points.
     *
     * @param userAddress - the user staking their OGN
     * @return Amount of ETH profit share to pay the user
     * @return Amount of OGN rewards to pay the user
     */
    function claim(address userAddress)
        external
        override
        onlySeries
        returns (uint256, uint256)
    {
        // Do not unstake and claim if not in claim period
        if (block.timestamp < endTime) {
            return (0, 0);
        }

        return _unstake(userAddress);
    }

    /**
     * @notice Calculate and return  ETH profit share and OGN rewards and zero
     *      out the user's stake points.
     *
     * @param userAddress - the user staking their OGN
     * @return Amount of ETH profit share to pay the user
     * @return Amount of OGN rewards to pay the user
     */
    function unstake(address userAddress)
        external
        override
        onlySeries
        returns (uint256, uint256)
    {
        return _unstake(userAddress);
    }

    /**
     * @dev Set the initial total points, potentially rolling over stake
     *      totals from the previous season.
     * @param initialSupply - The amount of staked OGN at the start of the
     *      season.
     */
    function bootstrap(uint256 initialSupply) external override onlySeries {
        require(!season.bootstrapped, 'Season: Already bootstrapped');

        // Gas favorable update
        SeasonMeta memory meta = season;
        meta.bootstrapped = true;
        meta.totalPoints = _pointsInTime(initialSupply, startTime);
        season = meta;
    }

    ///
    /// Internals
    ///

    /**
     * @dev creates the final snapshot of rewards totals entitled to the
     *      stakers of this period. This only happens once at the end of the
     *      season.  This constitutes the full amount of rewards for this
     *      season.  WARNING: This should not be called before endTime or a
     *      snapshot will be taken and frozen too early, leaving rewards on
     *      the table.
     */
    function _snapshot() internal {
        address vault = series.vault();
        Snapshot memory snap = Snapshot(
            uint128(vault.balance),
            uint128(IERC20(series.ogn()).balanceOf(vault))
        );

        emit Finale(snap.rewardETH, snap.rewardOGN);

        season.snapshotTaken = true;
        snapshot = snap;
    }

    /**
     * @dev Calculate a user's rewards amounts and clear stake points
     *
     * @param userAddress - The address of the user account
     * @return Amount of ETH entitlement
     * @return Amount of OGN entitlement
     */
    function _unstake(address userAddress) internal returns (uint256, uint256) {
        if (!season.bootstrapped) {
            // Unable to calculate rewards because we aren't bootstrapped
            require(block.timestamp < endTime, 'Season: Not bootstrapped.');

            // Nothing to unstake, no rewards to give. Season can still be
            // bootstrapped by Series with a new stake.
            return (0, 0);
        }

        User memory user = _initMemUser(userAddress);

        uint256 rewardETH = 0;
        uint256 rewardOGN = 0;

        // Only remove points from season totals if season has not ended to
        // preserve shares proportion calculation
        if (block.timestamp < endTime) {
            season.totalPoints -= user.points;
        } else {
            // Within claim period
            if (block.timestamp < claimEndTime) {
                (rewardETH, rewardOGN) = _calcRewards(user.points);
            }
        }

        // Zero out user points
        users[userAddress] = User(true, 0);

        emit Unstake(userAddress);

        return (rewardETH, rewardOGN);
    }

    /**
     * @dev Calculate the points a user would receive if they staked at a
     *      specific block timestamp.
     *
     * @param amount - The amount of OGN they would stake
     * @param blockStamp - The block timestamp to calculate for
     * @return points
     */
    function _pointsInTime(uint256 amount, uint256 blockStamp)
        internal
        view
        returns (uint128)
    {
        if (amount == 0 || blockStamp >= lockStartTime) {
            return 0;
        }

        // Pre-season stake points start at startTime
        uint256 effectiveStamp = blockStamp < startTime
            ? startTime
            : blockStamp;

        // Remainder ignored intentionally, only full days are counted
        uint256 stakeDays = (endTime - effectiveStamp) / 1 days;

        // Imprecise math intentional since resolution is only to 1 day
        uint256 points = amount * stakeDays;

        require(points < type(uint128).max, 'Season: Points overflow');

        return uint128(points);
    }

    /**
     * @dev Claim and return amounts of ETH profit share and OGN rewards
     *      entitled to the user.
     *
     * @param userPoints - a user's points to use for rewards calculation
     * @return userRewardETH - Amount of ETH share a user is entitled to
     * @return userRewardOGN - Amount of OGN rewards a user is entitled to
     */
    function _calcRewards(uint256 userPoints)
        internal
        returns (uint256, uint256)
    {
        if (userPoints == 0) {
            return (0, 0);
        }

        // Get final rewards totals
        if (!season.snapshotTaken && block.timestamp >= endTime) {
            _snapshot();
        }

        uint256 userRewardETH = _calculateShare(
            userPoints,
            uint256(snapshot.rewardETH)
        );
        uint256 userRewardOGN = _calculateShare(
            userPoints,
            uint256(snapshot.rewardOGN)
        );

        return (userRewardETH, userRewardOGN);
    }

    /**
     * @dev Initialize a user, potentially rolling over stakes from the
     *      previous season. NOTE: This does not write to storage.
     *
     * @return initialized User
     */
    function _initMemUser(address userAddress)
        internal
        view
        returns (User memory)
    {
        User memory user = users[userAddress];
        ISeries staking = ISeries(series);

        // If the user is new, the user might be rolling over from a previous
        // season.  Check for pre-existing stakes on Season.
        if (!user.exists) {
            uint256 latestStakeTime = staking.latestStakeTime(userAddress);

            // Do not assign points to a user that staked in a future season.
            // This could happen if a user stakes in the next season while
            // this one is in claim period.
            if (latestStakeTime > 0 && latestStakeTime <= startTime) {
                uint256 stakeBalance = staking.balanceOf(userAddress);
                user.points = _pointsInTime(stakeBalance, startTime);
            }

            // Mark the user as existing so we do not repeat this step
            user.exists = true;
        }

        return user;
    }

    /**
     * @dev Calculate the given user's share of a given value.
     *
     * @return share the user is currently entitled to of given rewards
     */
    function _calculateShare(uint256 userPoints, uint256 totalRewards)
        internal
        view
        returns (uint256)
    {
        return (totalRewards * userPoints) / uint256(season.totalPoints);
    }
}