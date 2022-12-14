/*
ERC20FriendlyRewardModule

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./interfaces/IRewardModule.sol";
import "./interfaces/IEvents.sol";
import "./ERC20BaseRewardModule.sol";
import "./GysrUtils.sol";

/**
 * @title ERC20 friendly reward module
 *
 * @notice this reward module distributes a single ERC20 token as the staking reward.
 * It is designed to offer simple and predictable reward mechanics.
 *
 * @dev rewards are immutable once earned, and can be claimed by the user at
 * any time. The module can be configured with a linear vesting schedule to
 * incentivize longer term staking. The user can spend GYSR at the time of
 * staking to receive a multiplier on their earning rate.
 */
contract ERC20FriendlyRewardModule is ERC20BaseRewardModule {
    using GysrUtils for uint256;

    // constants
    uint256 public constant FULL_VESTING = 10**DECIMALS;

    // single stake by user
    struct Stake {
        uint256 shares;
        uint256 gysr;
        uint256 bonus;
        uint256 rewardTally;
        uint256 timestamp;
    }

    // mapping of user to all of their stakes
    mapping(address => Stake[]) public stakes;

    // total shares without GYSR multiplier applied
    uint256 public totalRawStakingShares;
    // total shares with GYSR multiplier applied
    uint256 public totalStakingShares;
    // counter representing the current rate of rewards per share
    uint256 public rewardsPerStakedShare;
    // value to keep track of earnings to be put back into the pool
    uint256 public rewardDust;
    // timestamp of last update
    uint256 public lastUpdated;

    // minimum ratio of earned rewards measured against FULL_VESTING (i.e. 2.5 * 10^17 would be 25%)
    uint256 public immutable vestingStart;
    // length of time in seconds until the user receives a FULL_VESTING (1x) multiplier on rewards
    uint256 public immutable vestingPeriod;

    IERC20 private immutable _token;
    address private immutable _factory;

    /**
     * @param token_ the token that will be rewarded
     * @param vestingStart_ minimum ratio earned
     * @param vestingPeriod_ period (in seconds) over which investors vest to 100%
     * @param factory_ address of module factory
     */
    constructor(
        address token_,
        uint256 vestingStart_,
        uint256 vestingPeriod_,
        address factory_
    ) {
        require(vestingStart_ <= FULL_VESTING, "Invalid vesting start value");

        _token = IERC20(token_);
        _factory = factory_;

        vestingStart = vestingStart_;
        vestingPeriod = vestingPeriod_;

        lastUpdated = block.timestamp;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(_token);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function balances()
        external
        view
        override
        returns (uint256[] memory balances_)
    {
        balances_ = new uint256[](1);
        balances_[0] = totalLocked();
    }

    /**
     * @inheritdoc IRewardModule
     */
    function usage() external view override returns (uint256) {
        return _usage();
    }

    /**
     * @inheritdoc IRewardModule
     */
    function stake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256, uint256) {
        _update();
        return _stake(account, user, shares, data);
    }

    /**
     * @notice internal implementation of stake method
     * @param account address of staking account
     * @param user address of user
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function _stake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) internal returns (uint256, uint256) {
        require(data.length == 0 || data.length == 32, "Invalid calldata");

        uint256 gysr;
        if (data.length == 32) {
            assembly {
                gysr := calldataload(164)
            }
        }

        uint256 bonus =
            gysr.gysrBonus(shares, totalRawStakingShares + shares, _usage());

        if (gysr > 0) {
            emit GysrSpent(user, gysr);
        }

        // update user staking info
        stakes[account].push(
            Stake(shares, gysr, bonus, rewardsPerStakedShare, block.timestamp)
        );

        // add new shares to global totals
        totalRawStakingShares += shares;
        totalStakingShares += (shares * bonus) / 10**DECIMALS;

        return (gysr, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function unstake(
        address account,
        address user,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        _update();
        return _unstake(account, user, shares);
    }

    /**
     * @notice internal implementation of unstake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares burned
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function _unstake(
        address account,
        address user,
        uint256 shares
    ) internal returns (uint256, uint256) {
        // redeem first-in-last-out
        uint256 sharesLeftToBurn = shares;
        Stake[] storage userStakes = stakes[account];
        uint256 rewardAmount;
        uint256 gysrVested;
        uint256 preVestingRewards;
        uint256 timeVestingCoeff;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = userStakes[userStakes.length - 1];
            require(lastStake.timestamp < block.timestamp, "Unstaking can't be done in same block with staking");

            if (lastStake.shares <= sharesLeftToBurn) {
                // fully redeem a past stake

                preVestingRewards = _rewardForStakedShares(
                    lastStake.shares,
                    lastStake.bonus,
                    lastStake.rewardTally
                );

                timeVestingCoeff = timeVestingCoefficient(lastStake.timestamp);
                rewardAmount +=
                    (preVestingRewards * timeVestingCoeff) /
                    10**DECIMALS;

                rewardDust +=
                    (preVestingRewards * (FULL_VESTING - timeVestingCoeff)) /
                    10**DECIMALS;

                totalStakingShares -=
                    (lastStake.shares * lastStake.bonus) /
                    10**DECIMALS;
                sharesLeftToBurn -= lastStake.shares;
                gysrVested += lastStake.gysr;
                userStakes.pop();
            } else {
                // partially redeem a past stake

                preVestingRewards = _rewardForStakedShares(
                    sharesLeftToBurn,
                    lastStake.bonus,
                    lastStake.rewardTally
                );

                timeVestingCoeff = timeVestingCoefficient(lastStake.timestamp);
                rewardAmount +=
                    (preVestingRewards * timeVestingCoeff) /
                    10**DECIMALS;

                rewardDust +=
                    (preVestingRewards * (FULL_VESTING - timeVestingCoeff)) /
                    10**DECIMALS;

                totalStakingShares -=
                    (sharesLeftToBurn * lastStake.bonus) /
                    10**DECIMALS;

                uint256 partialVested =
                    (sharesLeftToBurn * lastStake.gysr) / lastStake.shares;
                gysrVested += partialVested;
                lastStake.shares -= sharesLeftToBurn;
                lastStake.gysr -= partialVested;
                sharesLeftToBurn = 0;
            }
        }

        // update global totals
        totalRawStakingShares -= shares;

        if (rewardAmount > 0) {
            _distribute(user, address(_token), rewardAmount);
        }

        if (gysrVested > 0) {
            emit GysrVested(user, gysrVested);
        }

        return (0, gysrVested);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function claim(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256 spent, uint256 vested) {
        _update();
        (, vested) = _unstake(account, user, shares);
        (spent, ) = _stake(account, user, shares, data);
    }

    /**
     * @dev compute rewards owed for a specific stake
     * @param shares number of shares to calculate rewards for
     * @param bonus associated bonus for this stake
     * @param rewardTally associated rewardTally for this stake
     * @return reward for these staked shares
     */
    function _rewardForStakedShares(
        uint256 shares,
        uint256 bonus,
        uint256 rewardTally
    ) internal view returns (uint256) {
        return
            ((((rewardsPerStakedShare - rewardTally) * shares) / 10**DECIMALS) * // counteract rewardsPerStakedShare coefficient
                bonus) / 10**DECIMALS; // counteract bonus coefficient
    }

    /**
     * @notice compute vesting multiplier as function of staking time
     * @param time epoch time at which the tokens were staked
     * @return vesting multiplier rewards
     */
    function timeVestingCoefficient(uint256 time)
        public
        view
        returns (uint256)
    {
        if (vestingPeriod == 0) return FULL_VESTING;
        uint256 stakeTime = block.timestamp - time;
        if (stakeTime > vestingPeriod) return FULL_VESTING;
        return
            vestingStart +
            (stakeTime * (FULL_VESTING - vestingStart)) /
            vestingPeriod;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function update(address) external override {
        requireOwner();
        _update();
    }

    /**
     * @notice method called ad hoc to clean up and perform additional accounting
     * @dev will only be called manually, and should not contain any essential logic
     */
    function clean() external override {
        requireOwner();
        _update();
        _clean(address(_token));
    }

    /**
     * @notice fund Geyser by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     */
    function fund(uint256 amount, uint256 duration) external {
        _update();
        _fund(address(_token), amount, duration, block.timestamp);
    }

    /**
     * @notice fund Geyser by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function fund(
        uint256 amount,
        uint256 duration,
        uint256 start
    ) external {
        _update();
        _fund(address(_token), amount, duration, start);
    }

    /**
     * @dev updates the internal accounting for rewards per staked share
     * retrieves unlocked tokens and adds on any unvested rewards from the last unstake operation
     */
    function _update() private {
        lastUpdated = block.timestamp;

        if (totalStakingShares == 0) {
            rewardsPerStakedShare = 0;
            return;
        }

        uint256 rewardsToUnlock = _unlockTokens(address(_token)) + rewardDust;
        rewardDust = 0;

        // global accounting
        rewardsPerStakedShare +=
            (rewardsToUnlock * 10**DECIMALS) /
            totalStakingShares;
    }

    /**
     * @return total number of locked reward tokens
     */
    function totalLocked() public view returns (uint256) {
        if (lockedShares(address(_token)) == 0) {
            return 0;
        }
        return
            (_token.balanceOf(address(this)) * lockedShares(address(_token))) /
            totalShares(address(_token));
    }

    /**
     * @return total number of unlocked reward tokens
     */
    function totalUnlocked() public view returns (uint256) {
        uint256 unlockedShares =
            totalShares(address(_token)) - lockedShares(address(_token));

        if (unlockedShares == 0) {
            return 0;
        }
        return
            (_token.balanceOf(address(this)) * unlockedShares) /
            totalShares(address(_token));
    }

    /**
     * @dev internal helper to get current usage ratio
     * @return GYSR usage ratio
     */
    function _usage() private view returns (uint256) {
        if (totalStakingShares == 0) {
            return 0;
        }
        return
            ((totalStakingShares - totalRawStakingShares) * 10**DECIMALS) /
            totalStakingShares;
    }

    /**
     * @param addr address of interest
     * @return number of active stakes for user
     */
    function stakeCount(address addr) public view returns (uint256) {
        return stakes[addr].length;
    }
}