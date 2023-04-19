// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeUniswapV3Pool
 * @dev Wrappers around IUniswapV3Pool operations that throw on failure
 * (when the token contract returns false).
 * Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeUniswapV3Pool for
 * IUniswapV3Pool;` statement to your contract, which allows you
 * to call the safe operations as `token.observe(...)`, etc.
 */
library SafeUniswapV3Pool {
    using Address for address;

    function safeTicks(IUniswapV3Pool pool, int24 tick)
        internal
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        bytes memory returndata =
            address(pool).functionStaticCall(
                abi.encodeWithSelector(pool.ticks.selector, tick),
                "SafeUniswapV3Pool: low-level call failed"
            );
        return
            abi.decode(
                returndata,
                (
                    uint128,
                    int128,
                    uint256,
                    uint256,
                    int56,
                    uint160,
                    uint32,
                    bool
                )
            );
    }

    function safePositions(IUniswapV3Pool pool, bytes32 key)
        internal
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        bytes memory returndata =
            address(pool).functionStaticCall(
                abi.encodeWithSelector(pool.positions.selector, key),
                "SafeUniswapV3Pool: low-level call failed"
            );
        return
            abi.decode(
                returndata,
                (uint128, uint256, uint256, uint128, uint128)
            );
    }

    function safeSlot0(IUniswapV3Pool pool)
        internal
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint32 feeProtocol,
            bool unlocked
        )
    {
        bytes memory returndata =
            address(pool).functionStaticCall(
                abi.encodeWithSelector(pool.slot0.selector),
                "SafeUniswapV3Pool: low-level call failed"
            );
        return
            abi.decode(
                returndata,
                (uint160, int24, uint16, uint16, uint16, uint32, bool)
            );
    }

    function safeMint(
        IUniswapV3Pool pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes memory data
    ) internal returns (uint256 amount0, uint256 amount1) {
        bytes memory returndata =
            address(pool).functionCall(
                abi.encodeWithSelector(
                    pool.mint.selector,
                    recipient,
                    tickLower,
                    tickUpper,
                    amount,
                    data
                ),
                "SafeUniswapV3Pool: low-level call failed"
            );
        return abi.decode(returndata, (uint256, uint256));
    }
}