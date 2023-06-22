/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2023 Origin Protocol, Inc
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
 *
 * Changelog
 * =========
 *
 * V3
 * --
 * - Fixed a rewards calculation bug that caused users to miss out on rewards
 *      if they stake during the claim period of a season they did not
 *      previously interact with.
 *
 * V2
 * --
 * - Fixed a bug where a user would receive 0 points for a season they did not
 *      interact with but should have rolled over from a previous season.
 */

pragma solidity ^0.8.4;

import {AddressUpgradeable as Address} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IERC20Upgradeable as IERC20} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import {Governable} from '../governance/Governable.sol';
import {IFeeVault} from './FeeVault.sol';
import {ISeason} from './ISeason.sol';

interface ISeries {
    function ogn() external view returns (address);

    function vault() external view returns (address);

    function currentClaimingIndex() external view returns (uint256);

    function currentStakingIndex() external view returns (uint256);

    function liveSeason() external view returns (uint256);

    function expectedClaimingSeason() external view returns (address);

    function expectedStakingSeason() external view returns (address);

    function latestStakeTime(
        address userAddress
    ) external view returns (uint256);

    function balanceOf(address userAddress) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim() external returns (uint256, uint256);

    function stake(uint256 amount) external returns (uint256, uint256);

    function unstake() external returns (uint256);

    function popSeason() external;

    function pushSeason(address season) external;

    function bootstrapSeason(uint256 seasonIndex, uint256 totalStaked) external;
}

/**
 * @title Story Series staking contract
 * @notice Primary interaction OGN staking contract for Story profit sharing
 *      and rewards.
 */
contract SeriesV3 is Initializable, Governable, ISeries {
    address public override vault;
    address public override ogn;

    address[] public seasons;
    uint256 public override currentStakingIndex;
    uint256 public override currentClaimingIndex;
    uint256 private totalStakedOGN;

    mapping(address => uint256) private stakedOGN;
    mapping(address => uint256) private userLastStakingTime;

    /**
     * @dev A new season has been registered
     * @param number - The season ID (1-indexed)
     * @param season - The address of the new season
     */
    event NewSeason(uint256 indexed number, address indexed season);

    /**
     * @dev A season has started
     * @param number - The season ID (1-indexed)
     * @param season - The address of the new season
     */
    event SeasonStart(uint256 indexed number, address indexed season);

    /**
     * @dev A season has been cancelled and removed
     * @param season - The address of the new season
     */
    event SeasonCancelled(address indexed season);

    // @dev only execute if there's an active season set
    modifier requireActiveSeason() {
        require(seasons.length > 0, 'Series: No active season');
        _;
    }

    /**
     * @param ogn_ - Address for the OGN token
     * @param vault_ - Address for the FeeVault
     */
    function initialize(address ogn_, address vault_) external initializer {
        require(ogn_ != address(0), 'Series: Zero address: OGN');
        require(vault_ != address(0), 'Series: Zero address: Vault');
        ogn = ogn_;
        vault = vault_;
    }

    ///
    /// Externals
    ///

    /**
     * @notice The current "live" season (earliest non-ended season)
     * @return index of the live season
     */
    function liveSeason() external view override returns (uint256) {
        if (seasons.length <= 1) {
            return 0;
        }

        for (uint256 i = seasons.length; i > 0; i--) {
            uint256 idx = i - 1;

            if (block.timestamp >= ISeason(seasons[idx]).startTime()) {
                return idx;
            }
        }

        return currentStakingIndex;
    }

    /**
     * @notice The staking season, should stake() be called.  This takes into
     * account currentStakingIndex potentially advancing.
     * @return address of the expected claiming season
     */
    function expectedStakingSeason() external view override returns (address) {
        if (seasons.length < 1) {
            return address(0);
        }

        ISeason season = ISeason(seasons[currentStakingIndex]);

        if (
            block.timestamp >= season.lockStartTime() &&
            seasons.length > currentStakingIndex + 1
        ) {
            return seasons[currentStakingIndex + 1];
        }

        return seasons[currentStakingIndex];
    }

    /**
     * @notice The claiming season, should claim/unstake be called.  This
     * takes into account currentClaimingIndex potentially advancing.
     * @return address of the expected claiming season
     */
    function expectedClaimingSeason() external view override returns (address) {
        if (seasons.length < 1) {
            return address(0);
        }

        ISeason season = ISeason(seasons[currentClaimingIndex]);

        if (
            block.timestamp >= season.claimEndTime() &&
            seasons.length > currentClaimingIndex + 1
        ) {
            return seasons[currentClaimingIndex + 1];
        }

        return seasons[currentClaimingIndex];
    }

    /**
     * @notice Get the latest stake block timestamp for a user
     * @param userAddress - address for which to return their last stake time
     * @return timestamp for last stake time for a user (or 0 if none)
     */
    function latestStakeTime(
        address userAddress
    ) external view override returns (uint256) {
        return userLastStakingTime[userAddress];
    }

    /**
     * @notice Total staked OGN for a user
     * @param userAddress - address for which to return their points
     * @return total OGN staked
     */
    function balanceOf(
        address userAddress
    ) external view override returns (uint256) {
        return stakedOGN[userAddress];
    }

    /**
     * @notice Total staked OGN of all users
     * @return total OGN staked from all users
     */
    function totalSupply() external view override returns (uint256) {
        return totalStakedOGN;
    }

    /**
     * @notice Set the address for the OGN token.
     * @dev other contracts reference this value as well
     * @param ogn_ - address for the contract
     */
    function setOGN(address ogn_) external onlyGovernor {
        require(ogn_ != address(0), 'Series: Zero address: OGN');
        ogn = ogn_;
    }

    /**
     * @notice Set the address for the FeeVault.
     * @dev other contracts reference this value as well
     * @param vault_ - address for the contract
     */
    function setVault(address vault_) external onlyGovernor {
        require(vault_ != address(0), 'Series: Zero address: FeeVault');
        vault = vault_;
    }

    /**
     * @notice Stake OGN for fee sharing and rewards. Users can call this
     *      multiple times to add to their stake. This contract must be
     *      approved to transfer the given amount of OGN from the user.
     *
     * @param amount - The amount of OGN to stake
     * @return total amount of OGN staked by the user
     * @return total points received for the user's entire stake for the
     *      staking season
     */
    function stake(
        uint256 amount
    ) external override requireActiveSeason returns (uint256, uint256) {
        require(amount > 0, 'Series: No stake amount');

        uint128 stakePoints;
        address userAddress = msg.sender;
        IERC20 token = IERC20(ogn);
        ISeason season = _acquireStakingSeason();

        // Transfer OGN to Series
        require(
            token.transferFrom(userAddress, address(this), amount),
            'Series: OGN transfer failed'
        );

        if (currentStakingIndex > 0 && stakedOGN[userAddress] > 0) {
            uint256 lastIndex = currentStakingIndex - 1;
            ISeason lastSeason = ISeason(seasons[lastIndex]);

            // This is to make sure the previous (locked) season is aware of
            // pre-existing stakes so points are attributed for rewards claims
            lastSeason.stake(userAddress, amount);
        }

        // Record stake for the user and get their points total for return
        stakePoints = season.stake(userAddress, amount);

        // Update balances. This must occur after the stake() call to allow
        // for clean rollover.  Otherwise, this new balance could be
        // considered historical and used as rollover on top of new amount.
        stakedOGN[userAddress] += amount;
        totalStakedOGN += amount;
        userLastStakingTime[userAddress] = block.timestamp;

        return (stakedOGN[userAddress], stakePoints);
    }

    /**
     * @notice Unstake previously staked OGN. This will unstake their full
     *      OGN stake amount and pay out any rewards (if within a claim period)
     *
     * @return amount of OGN unstaked
     */
    function unstake() external override requireActiveSeason returns (uint256) {
        address userAddress = msg.sender;
        uint256 amount = stakedOGN[userAddress];
        ISeason claimSeason = _acquireClaimingSeason();

        (uint256 rewardETH, uint256 rewardOGN) = claimSeason.unstake(
            userAddress
        );

        // Make sure to unstake from staking season as well to zero-out user
        if (currentClaimingIndex < currentStakingIndex) {
            ISeason stakeSeason = ISeason(seasons[currentStakingIndex]);
            // Ignored return val because there can't be multiple seasons in
            // claim period at one time.  This should return (0,0).
            stakeSeason.unstake(userAddress);
        }

        // Balance updates need to happen after unstake() calls to allow
        // rollover calculation to get a user's stake balance.
        stakedOGN[userAddress] = 0;
        totalStakedOGN -= amount;

        // Send rewards to user (if any)
        _transferRewards(userAddress, rewardETH, rewardOGN);

        // Send staked OGN back to user
        require(
            IERC20(ogn).transfer(userAddress, amount),
            'Series: OGN transfer failed'
        );

        return amount;
    }

    /**
     * @notice Claim profit share and OGN rewards.
     *
     * @return claimedETH - amount of ETH profit share claimed
     * @return claimedOGN - amount of OGN rewards claimed
     */
    function claim()
        external
        override
        requireActiveSeason
        returns (uint256, uint256)
    {
        address userAddress = msg.sender;
        ISeason season = _acquireClaimingSeason();

        (uint256 rewardETH, uint256 rewardOGN) = season.claim(userAddress);

        _transferRewards(userAddress, rewardETH, rewardOGN);

        return (rewardETH, rewardOGN);
    }

    /**
     * @notice Add a new season.  It will be the last season in the sequence.
     *
     * @param season - address for the new season
     */
    function pushSeason(address season) external override onlyGovernor {
        require(Address.isContract(season), 'Series: Season not a contract');

        ISeason newSeason = ISeason(season);

        // If we have seasons to compare, do some sanity checks
        if (seasons.length > 0) {
            ISeason prevSeason = ISeason(seasons[seasons.length - 1]);

            // End time must be after claim period to prevent overlap of claim
            // periods
            require(
                newSeason.endTime() > prevSeason.claimEndTime(),
                'Series: Invalid end time'
            );

            // It's critical the start time begins after the previous season's
            // lock start time to avoid advancing early into the staking slot.
            // Since its end time is after the lock start time and seasons
            // probably shouldn't overlap for clarity sake, we check against
            // end time.
            require(
                newSeason.startTime() >= prevSeason.endTime(),
                'Series: Invalid start time'
            );
        }

        seasons.push(season);

        emit NewSeason(seasons.length - 1, season);

        if (seasons.length == 1) {
            ISeason(season).bootstrap(totalStakedOGN);
            emit SeasonStart(0, season);
        }
    }

    /**
     * @notice Remove the final scheduled season if it is not an active
     *      staking season.
     */
    function popSeason() external override onlyGovernor {
        require(seasons.length > 0, 'Series: No seasons to cancel');
        require(
            currentStakingIndex < seasons.length - 1,
            'Series: Season is active'
        );

        address cancelled = seasons[seasons.length - 1];

        // Remove the last element
        seasons.pop();

        emit SeasonCancelled(cancelled);
    }

    /**
     * @notice Manually bootstrap a season.  This should only be used in the
     *      rare case a season receives no new stakes, so was never
     *      bootstraped.
     * @param totalStaked - The amount of totalStakedOGN to send to
     *      Season.bootstrap()
     */
    function bootstrapSeason(
        uint256 seasonIndex,
        uint256 totalStaked
    ) external override onlyGovernor {
        require(seasonIndex < seasons.length, 'Series: Season does not exist');

        ISeason season = ISeason(seasons[seasonIndex]);

        require(
            block.timestamp >= season.lockStartTime(),
            'Series: Not locked'
        );

        season.bootstrap(totalStaked);
    }

    ///
    /// Internals
    ///

    /**
     * @dev Return the season to use for staking, advancing if necessary
     * @return staking season
     */
    function _acquireStakingSeason() internal returns (ISeason) {
        ISeason season = ISeason(seasons[currentStakingIndex]);

        // Locked seasons can accept stakes but will not award points,
        // therefore the staker will receive no rewards.  If we have another
        // Season available for (pre)staking, advance the index and use that
        // for staking operations.
        if (
            block.timestamp >= season.lockStartTime() &&
            seasons.length > currentStakingIndex + 1
        ) {
            currentStakingIndex += 1;
            season = ISeason(seasons[currentStakingIndex]);
            season.bootstrap(totalStakedOGN);
            emit SeasonStart(currentStakingIndex, seasons[currentStakingIndex]);
        }

        return season;
    }

    /**
     * @dev Return the season to use for claiming, advancing if necessary
     * @return claiming season
     */
    function _acquireClaimingSeason() internal returns (ISeason) {
        ISeason season = ISeason(seasons[currentClaimingIndex]);

        // If the claim period has ended, advance to the next season, if
        // available.
        if (
            block.timestamp >= season.claimEndTime() &&
            seasons.length > currentClaimingIndex + 1
        ) {
            currentClaimingIndex += 1;
            season = ISeason(seasons[currentClaimingIndex]);
        }

        return season;
    }

    /**
     * @dev Transfer the given ETH and OGN to the given user from the vault
     * @param userAddress - Recipient of the rewards
     * @param rewardETH - Amount of ETH to transfer
     * @param rewardOGN - Amount of OGN to transfer
     */
    function _transferRewards(
        address userAddress,
        uint256 rewardETH,
        uint256 rewardOGN
    ) internal {
        IFeeVault rewards = IFeeVault(vault);

        if (rewardETH > 0) {
            rewards.sendETHRewards(userAddress, rewardETH);
        }

        if (rewardOGN > 0) {
            rewards.sendTokenRewards(ogn, userAddress, rewardOGN);
        }
    }
}