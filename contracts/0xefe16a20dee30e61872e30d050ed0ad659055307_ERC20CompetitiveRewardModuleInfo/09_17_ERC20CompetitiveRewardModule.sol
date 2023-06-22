/*
ERC20CompetitiveRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IRewardModule.sol";
import "./interfaces/IConfiguration.sol";
import "./ERC20BaseRewardModule.sol";
import "./GysrUtils.sol";
import "./TokenUtils.sol";

/**
 * @title ERC20 competitive reward module
 *
 * @notice this reward module distributes a single ERC20 token as the staking reward.
 * It is designed to offer competitive and engaging reward mechanics.
 *
 * @dev share seconds are the primary unit of accounting in this module. They
 * are accrued over time and burned during reward distribution. Users can
 * earn a time multiplier as an incentive for longer term staking. They can
 * also receive a GYSR multiplier by spending GYSR at the time of unstaking.
 *
 * h/t https://github.com/ampleforth/token-geyser
 */
contract ERC20CompetitiveRewardModule is ERC20BaseRewardModule {
    using TokenUtils for IERC20;
    using GysrUtils for uint256;

    // single stake by user
    struct Stake {
        uint256 shares;
        uint256 timestamp;
    }

    mapping(bytes32 => Stake[]) public stakes;

    // configuration fields
    uint256 public immutable bonusMin;
    uint256 public immutable bonusMax;
    uint256 public immutable bonusPeriod;
    IERC20 private immutable _token;
    address private immutable _factory;
    IConfiguration private immutable _config;

    // global state fields
    uint256 public totalStakingShares;
    uint256 public totalStakingShareSeconds;
    uint256 public lastUpdated;
    uint256 private _usage;

    /**
     * @param token_ the token that will be rewarded
     * @param bonusMin_ initial time bonus
     * @param bonusMax_ maximum time bonus
     * @param bonusPeriod_ period (in seconds) over which time bonus grows to max
     * @param config_ address for configuration contract
     * @param factory_ address of module factory
     */
    constructor(
        address token_,
        uint256 bonusMin_,
        uint256 bonusMax_,
        uint256 bonusPeriod_,
        address config_,
        address factory_
    ) {
        require(token_ != address(0));
        require(bonusMin_ <= bonusMax_, "crm1");

        _token = IERC20(token_);
        _config = IConfiguration(config_);
        _factory = factory_;

        bonusMin = bonusMin_;
        bonusMax = bonusMax_;
        bonusPeriod = bonusPeriod_;

        lastUpdated = block.timestamp;
    }

    // -- IRewardModule -------------------------------------------------------

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
        return _usage;
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
    function stake(
        bytes32 account,
        address,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        _update();
        _stake(account, shares);
        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function unstake(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256, uint256) {
        _update();
        return _unstake(account, sender, receiver, shares, data);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function claim(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256 spent, uint256 vested) {
        _update();
        (spent, vested) = _unstake(account, sender, receiver, shares, data);
        _stake(account, shares);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function update(bytes32, address, bytes calldata) external override {
        requireOwner();
        _update();
    }

    /**
     * @inheritdoc IRewardModule
     */
    function clean(bytes calldata) external override {
        requireOwner();
        _update();
        _clean(address(_token));
    }

    // -- ERC20CompetitiveRewardModule ----------------------------------------

    /**
     * @notice fund module by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     */
    function fund(uint256 amount, uint256 duration) external {
        _fund(address(_token), amount, duration, block.timestamp);
    }

    /**
     * @notice fund module by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function fund(uint256 amount, uint256 duration, uint256 start) external {
        _fund(address(_token), amount, duration, start);
    }

    /**
     * @notice compute time bonus earned as a function of staking time
     * @param time length of time for which the tokens have been staked
     * @return bonus multiplier for time
     */
    function timeBonus(uint256 time) public view returns (uint256) {
        if (time >= bonusPeriod) {
            return 1e18 + bonusMax;
        }

        // linearly interpolate between bonus min and bonus max
        uint256 bonus = bonusMin + ((bonusMax - bonusMin) * time) / bonusPeriod;
        return 1e18 + bonus;
    }

    /**
     * @return total number of locked reward tokens
     */
    function totalLocked() public view returns (uint256) {
        return
            _token.getAmount(
                totalShares(address(_token)),
                lockedShares(address(_token))
            );
    }

    /**
     * @return total number of unlocked reward tokens
     */
    function totalUnlocked() public view returns (uint256) {
        uint256 total = totalShares(address(_token));
        uint256 locked = lockedShares(address(_token));
        return _token.getAmount(total, total - locked);
    }

    /**
     * @param account bytes32 account of interest
     * @return number of active stakes for user
     */
    function stakeCount(bytes32 account) public view returns (uint256) {
        return stakes[account].length;
    }

    // -- ERC20CompetitiveRewardModule internal -------------------------------

    /**
     * @dev internal implementation of stake method
     * @param account bytes32 id of staking account
     * @param shares number of shares burned
     */
    function _stake(bytes32 account, uint256 shares) private {
        // update user staking info
        stakes[account].push(Stake(shares, block.timestamp));

        // add newly minted shares to global total
        totalStakingShares += shares;
    }

    /**
     * @dev internal implementation of unstake method
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of receiver
     * @param shares number of shares burned
     * @param data additional data
     * @return spent amount of gysr spent
     * @return vested amount of gysr vested
     */
    function _unstake(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) private returns (uint256 spent, uint256 vested) {
        // validate
        // note: we assume shares has been validated upstream
        require(data.length == 0 || data.length == 32, "crm2");

        // parse GYSR amount from data
        if (data.length == 32) {
            assembly {
                spent := calldataload(196)
            }
        }

        uint256 bonus = spent.gysrBonus(shares, totalStakingShares, _usage);

        // do unstaking, first-in last-out, respecting time bonus
        uint256 shareSeconds;
        uint256 timeWeightedShareSeconds;
        (shareSeconds, timeWeightedShareSeconds) = _unstakeFirstInLastOut(
            account,
            shares
        );

        // compute and apply GYSR token bonus
        uint256 gysrWeightedShareSeconds = (bonus * timeWeightedShareSeconds) /
            1e18;

        // get reward in shares
        uint256 unlockedShares = totalShares(address(_token)) -
            lockedShares(address(_token));

        uint256 rewardShares = (unlockedShares * gysrWeightedShareSeconds) /
            (totalStakingShareSeconds + gysrWeightedShareSeconds);

        if (rewardShares == 0) {
            return (0, 0);
        }

        // reward
        _distribute(receiver, address(_token), rewardShares);

        // update usage
        uint256 ratio;
        if (spent > 0) {
            vested = spent;
            emit GysrSpent(sender, spent);
            emit GysrVested(sender, vested);
            ratio = ((bonus - 1e18) * 1e18) / bonus;
        }
        uint256 weight = (shareSeconds * 1e18) /
            (totalStakingShareSeconds + shareSeconds);
        _usage = _usage - (weight * _usage) / 1e18 + (weight * ratio) / 1e18;
    }

    /**
     * @dev internal implementation of update method to
     * unlock tokens and do global accounting
     */
    function _update() private {
        _unlockTokens(address(_token));

        // global accounting
        totalStakingShareSeconds +=
            (block.timestamp - lastUpdated) *
            totalStakingShares;
        lastUpdated = block.timestamp;
    }

    /**
     * @dev helper function to actually execute unstaking, first-in last-out, 
     while computing and applying time bonus. This function also updates
     user and global totals for shares and share-seconds.
     * @param account address of user
     * @param shares number of staking shares to burn
     * @return rawShareSeconds raw share seconds burned
     * @return bonusShareSeconds time bonus weighted share seconds
     */
    function _unstakeFirstInLastOut(
        bytes32 account,
        uint256 shares
    ) private returns (uint256 rawShareSeconds, uint256 bonusShareSeconds) {
        // redeem first-in-last-out
        uint256 sharesLeftToBurn = shares;
        Stake[] storage userStakes = stakes[account];
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = userStakes[userStakes.length - 1];
            uint256 stakeTime = block.timestamp - lastStake.timestamp;
            require(stakeTime > 0, "crm3");

            uint256 bonus = timeBonus(stakeTime);

            if (lastStake.shares <= sharesLeftToBurn) {
                // fully redeem a past stake
                bonusShareSeconds +=
                    (lastStake.shares * stakeTime * bonus) /
                    1e18;
                rawShareSeconds += lastStake.shares * stakeTime;
                sharesLeftToBurn -= lastStake.shares;
                userStakes.pop();
            } else {
                // partially redeem a past stake
                bonusShareSeconds +=
                    (sharesLeftToBurn * stakeTime * bonus) /
                    1e18;
                rawShareSeconds += sharesLeftToBurn * stakeTime;
                lastStake.shares -= sharesLeftToBurn;
                sharesLeftToBurn = 0;
            }
        }

        // update global totals
        totalStakingShareSeconds -= rawShareSeconds;
        totalStakingShares -= shares;
    }

    /**
     * @dev private helper method for funding with fee processing
     */
    function _fund(
        address token,
        uint256 amount,
        uint256 duration,
        uint256 start
    ) private {
        _update();

        // get fees
        (address receiver, uint256 rate) = _config.getAddressUint96(
            keccak256("gysr.core.competitive.fund.fee")
        );

        // do funding
        _fund(token, amount, duration, start, receiver, rate);
    }
}