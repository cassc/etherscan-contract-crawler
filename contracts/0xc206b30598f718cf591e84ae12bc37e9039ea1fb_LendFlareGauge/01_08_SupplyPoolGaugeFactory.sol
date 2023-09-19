// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../common/IVirtualBalanceWrapper.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ILendFlareToken {
    function futureEpochTimeWrite() external returns (uint256);

    function rate() external view returns (uint256);
}

interface IMinter {
    function minted(address addr, address self) external view returns (uint256);
}

interface ILendFlareGaugeModel {
    function getGaugeWeightShare(address addr) external view returns (uint256);
}

contract LendFlareGauge is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant BOOST_WARMUP = 2 weeks;
    uint256 constant WEEK = 1 weeks;

    address public virtualBalance;
    uint256 public working_supply;
    uint256 public period;
    uint256 public inflation_rate;
    uint256 public future_epoch_time;

    address public lendFlareVotingEscrow;
    address public lendFlareToken;
    address public lendFlareTokenMinter;
    address public lendFlareGaugeModel;

    mapping(uint256 => uint256) public period_timestamp;
    mapping(uint256 => uint256) public integrate_inv_supply;

    mapping(address => uint256) public integrate_inv_supply_of;
    mapping(address => uint256) public integrate_checkpoint_of;
    mapping(address => uint256) public totalAccrued;
    mapping(address => uint256) public rewardLiquidityLimits;

    event UpdateLiquidityLimit(
        address user,
        uint256 original_balance,
        uint256 original_supply,
        uint256 reward_liquidity_limits,
        uint256 working_supply
    );

    constructor(
        address _virtualBalance,
        address _lendFlareToken,
        address _lendFlareVotingEscrow,
        address _lendFlareGaugeModel,
        address _lendFlareTokenMinter
    ) public {
        virtualBalance = _virtualBalance;
        lendFlareVotingEscrow = _lendFlareVotingEscrow;
        lendFlareToken = _lendFlareToken;
        lendFlareTokenMinter = _lendFlareTokenMinter;
        lendFlareGaugeModel = _lendFlareGaugeModel;
    }

    function _updateLiquidityLimit(
        address addr,
        uint256 l,
        uint256 L
    ) internal {
        uint256 voting_balance = IERC20(lendFlareVotingEscrow).balanceOf(addr);
        uint256 voting_total = IERC20(lendFlareVotingEscrow).totalSupply();
        uint256 lim = (l * TOKENLESS_PRODUCTION) / 100;

        if (
            voting_total > 0 &&
            block.timestamp > period_timestamp[0] + BOOST_WARMUP
        ) {
            lim +=
                (((L * voting_balance) / voting_total) *
                    (100 - TOKENLESS_PRODUCTION)) /
                100;
        }

        lim = min(l, lim);

        uint256 old_bal = rewardLiquidityLimits[addr];

        rewardLiquidityLimits[addr] = lim;

        uint256 _working_supply = working_supply + lim - old_bal;
        working_supply = _working_supply;

        emit UpdateLiquidityLimit(addr, l, L, lim, _working_supply);
    }

    function _checkpoint(address addr) internal {
        uint256 _period_time = period_timestamp[period];
        uint256 _integrate_inv_supply = integrate_inv_supply[period];
        uint256 rate = inflation_rate;
        uint256 new_rate = rate;
        uint256 prev_future_epoch = future_epoch_time;

        if (prev_future_epoch >= _period_time) {
            future_epoch_time = ILendFlareToken(lendFlareToken)
                .futureEpochTimeWrite();
            new_rate = ILendFlareToken(lendFlareToken).rate();

            require(new_rate > 0, "!new_rate");

            inflation_rate = new_rate;
        }

        uint256 _reward_liquidity_limits = rewardLiquidityLimits[addr];
        uint256 _working_supply = working_supply;

        if (block.timestamp > _period_time) {
            uint256 prev_week_time = _period_time;
            uint256 week_time = min(
                ((_period_time + WEEK) / WEEK) * WEEK,
                block.timestamp
            );

            for (uint256 i = 0; i < 500; i++) {
                uint256 dt = week_time - prev_week_time;
                uint256 w = ILendFlareGaugeModel(lendFlareGaugeModel)
                    .getGaugeWeightShare(address(this));

                if (_working_supply > 0) {
                    if (
                        prev_future_epoch >= prev_week_time &&
                        prev_future_epoch < week_time
                    ) {
                        _integrate_inv_supply +=
                            (rate * w * (prev_future_epoch - prev_week_time)) /
                            _working_supply;
                        rate = new_rate;
                        _integrate_inv_supply +=
                            (rate * w * (week_time - prev_future_epoch)) /
                            _working_supply;
                    } else {
                        _integrate_inv_supply +=
                            (rate * w * dt) /
                            _working_supply;
                    }

                    if (week_time == block.timestamp) break;

                    prev_week_time = week_time;
                    week_time = min(week_time + WEEK, block.timestamp);
                }
            }
        }

        period += 1;
        period_timestamp[period] = block.timestamp;
        integrate_inv_supply[period] = _integrate_inv_supply;

        totalAccrued[addr] +=
            (_reward_liquidity_limits *
                (_integrate_inv_supply - integrate_inv_supply_of[addr])) /
            10**18;
        integrate_inv_supply_of[addr] = _integrate_inv_supply;
        integrate_checkpoint_of[addr] = block.timestamp;
    }

    function updateReward(address addr) public nonReentrant returns (bool) {
        _checkpoint(addr);
        _updateLiquidityLimit(
            addr,
            IVirtualBalanceWrapper(virtualBalance).balanceOf(addr),
            IVirtualBalanceWrapper(virtualBalance).totalSupply()
        );

        return true;
    }

    function claimableTokens(address addr)
        public
        nonReentrant
        returns (uint256)
    {
        _checkpoint(addr);

        return
            totalAccrued[addr] -
            IMinter(lendFlareTokenMinter).minted(addr, address(this));
    }

    function lastCheckpointTimestamp() public view returns (uint256) {
        return period_timestamp[period];
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract SupplyPoolGaugeFactory {
    address public owner;

    event CreateGauge(address gauge);

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "SupplyPoolGaugeFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createGauge(
        address _virtualBalance,
        address _lendflareToken,
        address _lendflareVotingEscrow,
        address _lendflareGaugeModel,
        address _lendflareTokenMinter
    ) public returns (address) {
        require(
            msg.sender == owner,
            "SupplyPoolGaugeFactory: !authorized createGauge"
        );

        LendFlareGauge gauge = new LendFlareGauge(
            _virtualBalance,
            _lendflareToken,
            _lendflareVotingEscrow,
            _lendflareGaugeModel,
            _lendflareTokenMinter
        );

        emit CreateGauge(address(gauge));

        return address(gauge);
    }
}