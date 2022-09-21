// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;


interface IKyberPool {

    /// @notice The fee to be charged for a swap in basis points
    /// @return The swap fee in basis points
    function swapFeeUnits() external view returns (uint24);

    /// @notice The pool tick distance
    /// @dev Ticks can only be initialized and used at multiples of this value
    /// It remains an int24 to avoid casting even though it is >= 1.
    /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
    /// @return The tick distance
    function tickDistance() external view returns (int24);

    /// @notice Fetches the pool's liquidity values
    /// @return baseL pool's base liquidity without reinvest liqudity
    /// @return reinvestL the liquidity is reinvested into the pool
    /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
    function getLiquidityState()
        external
        view
        returns (
            uint128 baseL,
            uint128 reinvestL,
            uint128 reinvestLLast
        );

    /// @notice Fetches the pool's prices, ticks and lock status
    /// @return sqrtP sqrt of current price: sqrt(token1/token0)
    /// @return currentTick pool's current tick
    /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
    /// @return locked true if pool is locked, false otherwise
    function getPoolState()
        external
        view
        returns (
            uint160 sqrtP,
            int24 currentTick,
            int24 nearestCurrentTick,
            bool locked
        );

    function factory() external view returns (address);

    /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
    function getFeeGrowthGlobal() external view returns (uint256);

    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside,
            uint128 secondsPerLiquidityOutside
        );

    /// @notice Returns the previous and next initialized ticks of a specific tick
    /// @dev If specified tick is uninitialized, the returned values are zero.
    /// @param tick The tick to look up
    function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

    function totalSupply() external view returns (uint256);
    function getSecondsPerLiquidityData() external view returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

}