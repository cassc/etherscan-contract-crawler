/*
ERC20MultiRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IRewardModule.sol";
import "./interfaces/IConfiguration.sol";
import "./ERC20BaseRewardModule.sol";
import "./GysrUtils.sol";

/**
 * @title ERC20 multi reward module
 *
 * @notice this reward module distributes multiple ERC20 token as the staking reward.
 * It is designed to offer simple and flexible reward mechanics.
 *
 * @dev each reward token is opt-in and must be specified during user operations.
 * Rewards are immutable once earned, and can be claimed by the user at
 * any time. The module can be configured with a linear vesting schedule to
 * incentivize longer term staking.
 */
contract ERC20MultiRewardModule is ERC20BaseRewardModule {
    using GysrUtils for uint256;
    using TokenUtils for IERC20;

    // single stake by user
    struct Stake {
        uint256 shares;
        mapping(address => uint256) registered; // accumulator value when registered for reward
        uint128 timestamp;
        uint128 count;
    }

    // reward data for single token
    struct Reward {
        uint256 stakingShares;
        uint256 accumulator; // accumulator for reward shares per staking share
        uint256 dust; // placeholder to track earnings to be put back into the pool
    }

    // constant
    uint256 public constant MAX_TOKENS = 128; // only for viewing balances

    // data
    mapping(bytes32 => Stake[]) public stakes;
    mapping(address => Reward) public rewards;
    address[] private _tokens;

    // configuration
    uint256 public immutable vestingStart;
    uint256 public immutable vestingPeriod;
    address private immutable _factory;
    IConfiguration private immutable _config;

    /**
     * @param vestingStart_ minimum vesting portion earned
     * @param vestingPeriod_ period (in seconds) over which user positions fully vest
     * @param config_ address for configuration contract
     * @param factory_ address of module factory
     */
    constructor(
        uint256 vestingStart_,
        uint256 vestingPeriod_,
        address config_,
        address factory_
    ) {
        require(vestingStart_ <= 1e18, "mrm1");

        _config = IConfiguration(config_);
        _factory = factory_;

        vestingStart = vestingStart_;
        vestingPeriod = vestingPeriod_;
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
        return _tokens;
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
        uint256 len = _tokens.length;
        if (len > MAX_TOKENS) len = MAX_TOKENS;
        balances_ = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            balances_[i] = IERC20(_tokens[i]).getAmount(
                totalShares(_tokens[i]),
                lockedShares(_tokens[i])
            );
        }
    }

    /**
     * @inheritdoc IRewardModule
     */
    function usage() external pure override returns (uint256) {
        return 0.0;
    }

    /**
     * @inheritdoc IRewardModule
     *
     * @dev stake and register for rewards on specified tokens
     *
     * `data`: address[] tokens
     */
    function stake(
        bytes32 account,
        address,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256, uint256) {
        require(data.length % 32 == 0, "mrm2");
        uint256 count = data.length / 32;
        require(count <= _tokens.length, "mrm3");

        // create new user stake
        Stake storage s = stakes[account].push();
        s.shares = shares;
        s.timestamp = uint128(block.timestamp);
        s.count = uint64(count);

        for (uint256 i; i < count; ) {
            // get token address
            address addr;
            uint256 pos = 164 + 32 * i;
            assembly {
                addr := calldataload(pos)
            }
            _update(addr);

            // update staking data
            require(s.registered[addr] == 0, "mrm4"); // no duplicates
            s.registered[addr] = rewards[addr].accumulator;
            rewards[addr].stakingShares += shares;
            unchecked {
                ++i;
            }
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     *
     * @dev unstake and claim/unregister rewards on specified tokens
     *
     * `data`: address[] tokens (must be ordered)
     */
    function unstake(
        bytes32 account,
        address,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256, uint256) {
        require(data.length % 32 == 0, "mrm5");
        uint256 count = data.length / 32;
        require(count <= _tokens.length, "mrm6");

        address[] memory tkns = new address[](count);
        for (uint256 i; i < count; ) {
            // get token address
            uint256 pos = 196 + 32 * i;
            address addr;
            assembly {
                addr := calldataload(pos)
            }
            tkns[i] = addr;
            // verify ordered and no duplicates
            if (i > 0) require(addr > tkns[i - 1], "mrm7");

            // update token
            _update(addr);
            unchecked {
                ++i;
            }
        }

        // setup
        uint256[] memory earnings = new uint256[](count);
        uint256 remaining = shares;

        Stake[] storage userStakes = stakes[account];

        // redeem first-in-last-out
        while (remaining > 0) {
            Stake storage s = userStakes[userStakes.length - 1];
            uint256 sh = s.shares;
            uint256 vesting = _vesting(s.timestamp);

            uint256 unique;
            for (uint256 i; i < count; ++i) {
                // get token address
                address addr = tkns[i];

                // not registered
                if (s.registered[addr] == 0) continue;

                if (sh <= remaining) {
                    // fully redeem stake
                    earnings[i] += _reward(
                        sh,
                        addr,
                        s.registered[addr],
                        vesting
                    );

                    // clear reward token data for this stake
                    s.registered[addr] = 0;
                    rewards[addr].stakingShares -= sh;
                } else {
                    // partially redeem stake
                    earnings[i] += _reward(
                        remaining,
                        addr,
                        s.registered[addr],
                        vesting
                    );
                    // decrease reward token stake
                    rewards[addr].stakingShares -= remaining;
                }
                ++unique;
            }

            require(unique == s.count, "mrm8");

            if (sh <= remaining) {
                // fully redeem stake
                remaining -= sh;
                userStakes.pop();
            } else {
                // partially redeem stake
                s.shares = sh - remaining;
                remaining = 0;
            }
        }

        // distribute rewards
        for (uint256 i; i < count; ) {
            if (earnings[i] > 0) {
                _distribute(receiver, tkns[i], earnings[i]);
            }
            unchecked {
                ++i;
            }
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     *
     * @dev claim rewards on specified tokens, optionally specify stakes, and optionally deregister
     *
     * `data`: (bool continue, uint256 start, uint256 end, address[] tokens)
     *
     * note: encoded token array addresses must be sorted
     */
    function claim(
        bytes32 account,
        address,
        address receiver,
        uint256,
        bytes calldata data
    ) external override onlyOwner returns (uint256, uint256) {
        // validate
        require(data.length > 96, "mrm9");
        require(data.length % 32 == 0, "mrm10");
        uint256 count = data.length / 32 - 3;
        require(count <= _tokens.length, "mrm11");
        // count > 0 implied by above

        bool cont; // continue earning or deregister
        uint256 index; // start claim index
        uint256 end; // end of claim index range, exclusive
        assembly {
            cont := calldataload(196)
            index := calldataload(228)
            end := calldataload(260)
        }
        require(index < end, "mrm12");
        Stake[] storage userStakes = stakes[account];
        require(end <= userStakes.length, "mrm13");

        address[] memory tkns = new address[](count);
        for (uint256 i; i < count; ) {
            // get token address
            uint256 pos = 292 + 32 * i;
            address addr;
            assembly {
                addr := calldataload(pos)
            }
            tkns[i] = addr;
            // verify ordered and no duplicates
            if (i > 0) require(addr > tkns[i - 1], "mrm14");

            // update token
            _update(addr);
            unchecked {
                ++i;
            }
        }

        uint256[] memory earnings = new uint256[](count);

        for (; index < end; ) {
            Stake storage s = userStakes[index];
            uint256 sh = s.shares;
            uint256 vesting = _vesting(s.timestamp); // coeff

            for (uint256 i; i < count; ++i) {
                address addr = tkns[i];

                // not registered
                if (s.registered[addr] == 0) continue;
                // compute rewards with vesting
                earnings[i] += _reward(sh, addr, s.registered[addr], vesting);

                // continue earning or opt out
                if (cont) {
                    s.registered[addr] = rewards[addr].accumulator;
                } else {
                    s.registered[addr] = 0;
                    s.count--;
                    rewards[addr].stakingShares -= sh;
                }
            }
            unchecked {
                ++index;
            }
        }
        // distribute rewards
        for (uint256 i; i < count; ) {
            if (earnings[i] > 0) {
                _distribute(receiver, tkns[i], earnings[i]);
            }
            unchecked {
                ++i;
            }
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     *
     * @dev register or deregister for specified rewards token on existing stake
     *
     * `data`: (bool register, uint256 start, uint256 end, address[] tokens)
     *
     * note: encoded token array addresses must be sorted
     */
    function update(
        bytes32 account,
        address,
        bytes calldata data
    ) external override {
        requireOwner();

        if (data.length == 0) return; // empty data indicates skip

        // validate
        require(data.length > 96, "mrm15");
        require(data.length % 32 == 0, "mrm16");
        uint256 count = data.length / 32 - 3;
        require(count <= _tokens.length, "mrm17");
        // count > 0 implied by above

        bool register; // register or deregister
        uint256 index; // start claim index
        uint256 end; // end of claim index range, exclusive
        assembly {
            register := calldataload(132)
            index := calldataload(164)
            end := calldataload(196)
        }
        require(index < end, "mrm18");
        require(end <= stakes[account].length, "mrm19");

        address prev;
        for (uint256 i; i < count; ) {
            uint256 pos = 228 + 32 * i;
            address addr;
            assembly {
                addr := calldataload(pos)
            }
            // verify ordered and no duplicates
            if (i > 0) require(addr > prev, "mrm20");

            // update token
            _update(addr);

            // register or clear accumulator
            if (register) {
                for (uint256 j = index; j < end; ++j) {
                    Stake storage s = stakes[account][j];
                    if (s.registered[addr] > 0) continue;
                    s.count++;
                    s.registered[addr] = rewards[addr].accumulator;
                    rewards[addr].stakingShares += s.shares;
                }
            } else {
                for (uint256 j = index; j < end; ++j) {
                    Stake storage s = stakes[account][j];
                    if (s.registered[addr] == 0) continue;
                    _reward(s.shares, addr, s.registered[addr], 0); // renounce all rewards to dust
                    s.count--;
                    s.registered[addr] = 0;
                    rewards[addr].stakingShares -= s.shares;
                }
            }
            unchecked {
                ++i;
            }
            prev = addr;
        }

        emit RewardsUpdated(account);
    }

    /**
     * @notice method called ad hoc to clean up and perform additional accounting
     * @dev will only be called manually, and should not contain any essential logic
     */
    function clean(bytes calldata data) external override {
        requireOwner();

        if (data.length == 0) return; // empty data indicates skip

        // validate
        require(data.length % 32 == 0, "mrm21");
        uint256 count = data.length / 32;
        require(count <= _tokens.length, "mrm22");

        // for each token
        for (uint256 i; i < count; ++i) {
            uint256 pos = 68 + 32 * i;
            address addr;
            assembly {
                addr := calldataload(pos)
            }
            // do update and clean
            _update(addr);
            _clean(addr);
        }
    }

    /**
     * @notice fund module by locking up reward tokens for distribution
     * @param token address of reward token
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     */
    function fund(address token, uint256 amount, uint256 duration) external {
        _fund(token, amount, duration, block.timestamp);
    }

    /**
     * @notice fund module by locking up reward tokens for distribution
     * @param token address of reward token
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function fund(
        address token,
        uint256 amount,
        uint256 duration,
        uint256 start
    ) external {
        _fund(token, amount, duration, start);
    }

    /**
     * @dev private helper method for funding with market initialization and fee processing
     */
    function _fund(
        address token,
        uint256 amount,
        uint256 duration,
        uint256 start
    ) private {
        // initialize market
        if (rewards[token].accumulator == 0) {
            _tokens.push(token);
            rewards[token].accumulator = 1;
        }
        _update(token);

        // get fees
        (address receiver, uint256 rate) = _config.getAddressUint96(
            keccak256("gysr.core.multi.fund.fee")
        );

        // do funding
        _fund(token, amount, duration, start, receiver, rate);
    }

    /**
     * @dev updates the internal accounting for rewards per staked share
     * retrieves unlocked tokens and adds on any unvested rewards from the last unstake operation
     * @param token address of reward token
     */
    function _update(address token) private {
        Reward storage reward = rewards[token];
        require(reward.accumulator > 0, "mrm23"); // market exists

        if (reward.stakingShares == 0) {
            reward.accumulator = 1; // reset accumulator
            return;
        }

        uint256 rewardsToUnlock = _unlockTokens(token) + reward.dust;
        reward.dust = 0;

        reward.accumulator += (rewardsToUnlock * 1e18) / reward.stakingShares;
    }

    /**
     * @dev internal helper to get vesting coefficient
     */
    function _vesting(uint256 start) private view returns (uint256) {
        require(start < block.timestamp, "mrm24");
        uint256 elapsed = block.timestamp - start;
        if (elapsed > vestingPeriod) return 1e18;

        return vestingStart + ((1e18 - vestingStart) * elapsed) / vestingPeriod;
    }

    /**
     * @dev internal helper to get earned rewards on a specific stake and reward token
     * and rollover unvested rewards to dust
     */
    function _reward(
        uint256 shares,
        address token,
        uint256 accumulator,
        uint256 vesting
    ) private returns (uint256) {
        if (vesting < 1e18) {
            // compute rewards with vesting
            uint256 r = ((rewards[token].accumulator - accumulator) * shares) /
                1e18;
            rewards[token].dust += (r * (1e18 - vesting)) / 1e18; // rollover dust
            return (r * vesting) / 1e18;
        } else {
            // fully vested
            return ((rewards[token].accumulator - accumulator) * shares) / 1e18;
        }
    }

    /**
     * @dev helper to get module reward token count
     * @return number of reward tokens
     */
    function tokenCount() public view returns (uint256) {
        return _tokens.length;
    }

    /**
     * @dev helper to get user stake count
     * @param account bytes32 id for account of interest
     * @return number of active stakes for user
     */
    function stakeCount(bytes32 account) public view returns (uint256) {
        return stakes[account].length;
    }

    /**
     * @dev helper to get nested rewards accumulator data
     * @param account bytes32 id for account of interest
     * @param index array index of stake
     * @param token address of reward token
     */
    function stakeRegistered(
        bytes32 account,
        uint256 index,
        address token
    ) public view returns (uint256) {
        return stakes[account][index].registered[token];
    }
}