// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "fullrange/libraries/TickMath.sol";
import {FullMath} from "fullrange/libraries/FullMath.sol";
import {SafeCast} from "v3-core/contracts/libraries/SafeCast.sol";

import {PoolAddress} from "./PoolAddress.sol";

library UniswapHelpers {
    using SafeCast for uint256;

    /// @param minOut The minimum out amount the user wanted
    /// @param actualOut The actual out amount the user received
    error TooLittleOut(uint256 minOut, uint256 actualOut);

    /// @param deadline The minimum out amount the user wanted
    /// @param currentTimestamp The actual out amount the user received
    error PassedDeadline(uint256 deadline, uint256 currentTimestamp);

    IUniswapV3Factory constant FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    /// @notice executes a swap on the Uniswap
    /// @param pool The pool to swap on
    /// @param recipient The address to send the output to
    /// @param zeroForOne Whether to swap token0 for token1 or vice versa
    /// @param amountSpecified The amount of token0 or token1 to swap
    /// @param minOut The minimum amount of token0 or token1 to receive
    /// @param sqrtPriceLimitX96 The price limit for the swap
    /// @param deadline timestamp after which the swap should revert
    /// @param data Any data to pass to the uniswap callback handler
    /// @return amountOut The amount of token0 or token1 received
    /// @return amountIn The amount of token0 or token1 sent
    function swap(
        address pool,
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint256 minOut,
        uint160 sqrtPriceLimitX96,
        uint256 deadline,
        bytes memory data
    ) internal returns (uint256 amountOut, uint256 amountIn) {
        if (block.timestamp > deadline) revert PassedDeadline(deadline, block.timestamp);

        (int256 amount0, int256 amount1) = IUniswapV3Pool(pool).swap(
            recipient,
            zeroForOne,
            amountSpecified.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : sqrtPriceLimitX96,
            data
        );

        if (zeroForOne) {
            amountOut = uint256(-amount1);
            amountIn = uint256(amount0);
        } else {
            amountOut = uint256(-amount0);
            amountIn = uint256(amount1);
        }

        if (amountOut < minOut) {
            revert TooLittleOut(amountOut, minOut);
        }
    }

    /// @notice initializes a UniswapV3 pool with the given sqrt ratio
    /// @param tokenA the first token in the pool
    /// @param tokenB the second token in the pool
    /// @param feeTier the fee tier of the pool
    /// @param sqrtRatio the sqrt ratio to initialize the pool with
    /// @return pool the address of the newly created pool
    function deployAndInitPool(address tokenA, address tokenB, uint24 feeTier, uint160 sqrtRatio)
        internal
        returns (address)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(FACTORY.createPool(tokenA, tokenB, feeTier));
        pool.initialize(sqrtRatio);

        return address(pool);
    }

    /// @notice returns the current price tick of a UniswapV3 pool
    /// @param pool the address of the pool
    /// @return tick the current price tick of the pool
    function poolCurrentTick(address pool) internal returns (int24) {
        (, int24 tick,,,,,) = IUniswapV3Pool(pool).slot0();

        return tick;
    }

    /// @notice returns whether or not two pools have the same tokens
    /// @param pool1 the first pool
    /// @param pool2 the second pool
    /// @return same whether or not the two pools have the same tokens
    function poolsHaveSameTokens(address pool1, address pool2) internal view returns (bool) {
        return IUniswapV3Pool(pool1).token0() == IUniswapV3Pool(pool2).token0()
            && IUniswapV3Pool(pool1).token1() == IUniswapV3Pool(pool2).token1();
    }

    /// @notice returns whether or not a pool is a UniswapV3 pool
    /// @param pool the address of the pool
    /// @return isUniswapPool whether or not the pool is a UniswapV3 pool
    function isUniswapPool(address pool) internal view returns (bool) {
        IUniswapV3Pool p = IUniswapV3Pool(pool);
        PoolAddress.PoolKey memory k = PoolAddress.getPoolKey(p.token0(), p.token1(), p.fee());
        return pool == PoolAddress.computeAddress(address(FACTORY), k);
    }

    /// @notice returns the sqrt ratio at which token0 and token1 are trading at 1:1
    /// @param token0ONE 10 ** token0.decimals()
    /// @param token1ONE 10 ** token1.decimals()
    /// @return sqrtRatio at which token0 and token1 are trading at 1:1
    function oneToOneSqrtRatio(uint256 token0ONE, uint256 token1ONE) internal pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(TickMath.getTickAtSqrtRatio(uint160((token1ONE << 96) / token0ONE)) / 2);
    }
}