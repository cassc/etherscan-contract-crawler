// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@pancakeswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@pancakeswap/v3-core/contracts/libraries/SafeCast.sol';
import '@pancakeswap/v3-core/contracts/libraries/FullMath.sol';
import '@pancakeswap/v3-core/contracts/libraries/FixedPoint128.sol';
import '@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol';

import './libraries/LmTick.sol';

import './interfaces/IPancakeV3LmPool.sol';
import './interfaces/ILMPool.sol';
import './interfaces/IMasterChefV3.sol';
import './interfaces/IPancakeV3LmPoolDeveloper.sol';

contract PancakeV3LmPool is IPancakeV3LmPool {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using LmTick for mapping(int24 => LmTick.Info);

    uint256 public constant REWARD_PRECISION = 1e12;

    IPancakeV3Pool public immutable pool;
    IMasterChefV3 public immutable masterChef;

    uint256 public rewardGrowthGlobalX128;

    mapping(int24 => LmTick.Info) public lmTicks;

    uint128 public lmLiquidity;

    uint32 public lastRewardTimestamp;

    // Record the first negative RewardGrowthInside value.
    mapping(int24 => mapping(int24 => uint256)) public negativeRewardGrowthInsideInitValue;

    modifier onlyPool() {
        require(msg.sender == address(pool), 'Not pool');
        _;
    }

    modifier onlyMasterChef() {
        require(msg.sender == address(masterChef), 'Not MC');
        _;
    }

    modifier onlyPoolOrMasterChef() {
        require(msg.sender == address(pool) || msg.sender == address(masterChef), 'Not pool or MC');
        _;
    }

    constructor() {
        (address poolAddress, address masterChefAddress) = IPancakeV3LmPoolDeveloper(msg.sender).parameters();
        pool = IPancakeV3Pool(poolAddress);
        masterChef = IMasterChefV3(masterChefAddress);
        lastRewardTimestamp = uint32(block.timestamp);
    }

    function accumulateReward(uint32 currTimestamp) external override onlyPoolOrMasterChef {
        if (currTimestamp <= lastRewardTimestamp) {
            return;
        }

        if (lmLiquidity != 0) {
            (uint256 rewardPerSecond, uint256 endTime) = masterChef.getLatestPeriodInfo(address(pool));

            uint32 endTimestamp = uint32(endTime);
            uint32 duration;
            if (endTimestamp > currTimestamp) {
                duration = currTimestamp - lastRewardTimestamp;
            } else if (endTimestamp > lastRewardTimestamp) {
                duration = endTimestamp - lastRewardTimestamp;
            }

            if (duration != 0) {
                rewardGrowthGlobalX128 += FullMath.mulDiv(
                    duration,
                    FullMath.mulDiv(rewardPerSecond, FixedPoint128.Q128, REWARD_PRECISION),
                    lmLiquidity
                );
            }
        }

        lastRewardTimestamp = currTimestamp;
    }

    function crossLmTick(int24 tick, bool zeroForOne) external override onlyPool {
        if (lmTicks[tick].liquidityGross == 0) {
            return;
        }

        int128 lmLiquidityNet = lmTicks.cross(tick, rewardGrowthGlobalX128);

        if (zeroForOne) {
            lmLiquidityNet = -lmLiquidityNet;
        }

        lmLiquidity = LiquidityMath.addDelta(lmLiquidity, lmLiquidityNet);
    }

    /// @notice This will check the whether the range RewardGrowthInside is negative when the range ticks were initialized.
    /// @dev This is for fixing the issues that rewardGrowthInsideX128 can be underflow on purpose.
    /// If the rewardGrowthInsideX128 is negative , we will process it as a positive number.
    /// Because the RewardGrowthInside is self-incrementing, so we record the initial value as zero point.
    function _checkNegativeRewardGrowthInside(int24 tickLower, int24 tickUpper) internal {
        (uint256 rewardGrowthInsideX128, bool isNegative) = _getRewardGrowthInsideInternal(tickLower, tickUpper);
        if (isNegative) {
            uint256 initValue = negativeRewardGrowthInsideInitValue[tickLower][tickUpper];
            if (initValue == 0 || initValue > rewardGrowthInsideX128) {
                negativeRewardGrowthInsideInitValue[tickLower][tickUpper] = rewardGrowthInsideX128;
            }
        }
    }

    /// @notice Need to rest Negative Tick info when tick flipped.
    function _clearNegativeTickInfo(int24 tickLower, int24 tickUpper) internal {
        negativeRewardGrowthInsideInitValue[tickLower][tickUpper] = 0;
    }

    function updatePosition(int24 tickLower, int24 tickUpper, int128 liquidityDelta) external onlyMasterChef {
        (, int24 tick, , , , , ) = pool.slot0();
        uint128 maxLiquidityPerTick = pool.maxLiquidityPerTick();
        uint256 _rewardGrowthGlobalX128 = rewardGrowthGlobalX128;

        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            flippedLower = lmTicks.update(
                tickLower,
                tick,
                liquidityDelta,
                _rewardGrowthGlobalX128,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = lmTicks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _rewardGrowthGlobalX128,
                true,
                maxLiquidityPerTick
            );
        }

        if (tick >= tickLower && tick < tickUpper) {
            lmLiquidity = LiquidityMath.addDelta(lmLiquidity, liquidityDelta);
        }

        if (liquidityDelta < 0) {
            if (flippedLower) {
                lmTicks.clear(tickLower);
            }
            if (flippedUpper) {
                lmTicks.clear(tickUpper);
            }
        }
        // Need to rest Negative Tick info when tick flipped.
        if (liquidityDelta < 0 && (flippedLower || flippedUpper)) {
            _clearNegativeTickInfo(tickLower, tickUpper);
        } else {
            _checkNegativeRewardGrowthInside(tickLower, tickUpper);
        }
    }

    function getRewardGrowthInside(
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256 rewardGrowthInsideX128) {
        (rewardGrowthInsideX128, ) = _getRewardGrowthInsideInternal(tickLower, tickUpper);
        rewardGrowthInsideX128 = rewardGrowthInsideX128 - negativeRewardGrowthInsideInitValue[tickLower][tickUpper];
    }

    function _getRewardGrowthInsideInternal(
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint256 rewardGrowthInsideX128, bool isNegative) {
        (, int24 tick, , , , , ) = pool.slot0();
        LmTick.Info memory lower = lmTicks[tickLower];

        LmTick.Info memory upper = lmTicks[tickUpper];

        // calculate reward growth below
        uint256 rewardGrowthBelowX128;
        if (tick >= tickLower) {
            rewardGrowthBelowX128 = lower.rewardGrowthOutsideX128;
        } else {
            rewardGrowthBelowX128 = rewardGrowthGlobalX128 - lower.rewardGrowthOutsideX128;
        }

        // calculate reward growth above
        uint256 rewardGrowthAboveX128;
        if (tick < tickUpper) {
            rewardGrowthAboveX128 = upper.rewardGrowthOutsideX128;
        } else {
            rewardGrowthAboveX128 = rewardGrowthGlobalX128 - upper.rewardGrowthOutsideX128;
        }

        rewardGrowthInsideX128 = rewardGrowthGlobalX128 - rewardGrowthBelowX128 - rewardGrowthAboveX128;
        isNegative = (rewardGrowthBelowX128 + rewardGrowthAboveX128) > rewardGrowthGlobalX128;
    }
}