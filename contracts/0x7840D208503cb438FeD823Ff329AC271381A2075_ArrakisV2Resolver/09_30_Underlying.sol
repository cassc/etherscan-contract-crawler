// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IArrakisV2} from "../interfaces/IArrakisV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    LiquidityAmounts
} from "@arrakisfi/v3-lib-0.8/contracts/LiquidityAmounts.sol";
import {TickMath} from "@arrakisfi/v3-lib-0.8/contracts/TickMath.sol";
import {
    UnderlyingPayload,
    RangeData,
    PositionUnderlying,
    FeesEarnedPayload
} from "../structs/SArrakisV2.sol";
import {UniswapV3Amounts} from "./UniswapV3Amounts.sol";
import {Position} from "./Position.sol";

library Underlying {
    // solhint-disable-next-line function-max-lines
    function totalUnderlyingWithFees(
        UnderlyingPayload memory underlyingPayload_
    )
        public
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        for (uint256 i = 0; i < underlyingPayload_.ranges.length; i++) {
            {
                IUniswapV3Pool pool = IUniswapV3Pool(
                    underlyingPayload_.factory.getPool(
                        underlyingPayload_.token0,
                        underlyingPayload_.token1,
                        underlyingPayload_.ranges[i].feeTier
                    )
                );
                (uint256 a0, uint256 a1, uint256 f0, uint256 f1) = underlying(
                    RangeData({
                        self: underlyingPayload_.self,
                        range: underlyingPayload_.ranges[i],
                        pool: pool
                    })
                );
                amount0 += a0 + f0;
                amount1 += a1 + f1;
                fee0 += f0;
                fee1 += f1;
            }
        }

        IArrakisV2 arrakisV2 = IArrakisV2(underlyingPayload_.self);

        amount0 +=
            IERC20(underlyingPayload_.token0).balanceOf(
                underlyingPayload_.self
            ) -
            arrakisV2.managerBalance0() -
            arrakisV2.arrakisBalance0();
        amount1 +=
            IERC20(underlyingPayload_.token1).balanceOf(
                underlyingPayload_.self
            ) -
            arrakisV2.managerBalance1() -
            arrakisV2.arrakisBalance1();
    }

    function underlying(RangeData memory underlying_)
        public
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = underlying_.pool.slot0();
        bytes32 positionId = Position.getPositionId(
            underlying_.self,
            underlying_.range.lowerTick,
            underlying_.range.upperTick
        );
        PositionUnderlying memory positionUnderlying = PositionUnderlying({
            positionId: positionId,
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            lowerTick: underlying_.range.lowerTick,
            upperTick: underlying_.range.upperTick,
            pool: underlying_.pool
        });
        (amount0, amount1, fee0, fee1) = getUnderlyingBalances(
            positionUnderlying
        );
    }

    // solhint-disable-next-line function-max-lines
    function getUnderlyingBalances(
        PositionUnderlying memory positionUnderlying_
    )
        public
        view
        returns (
            uint256 amount0Current,
            uint256 amount1Current,
            uint256 fee0,
            uint256 fee1
        )
    {
        (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = positionUnderlying_.pool.positions(positionUnderlying_.positionId);

        // compute current holdings from liquidity
        (amount0Current, amount1Current) = LiquidityAmounts
            .getAmountsForLiquidity(
                positionUnderlying_.sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionUnderlying_.lowerTick),
                TickMath.getSqrtRatioAtTick(positionUnderlying_.upperTick),
                liquidity
            );

        // compute current fees earned
        fee0 =
            UniswapV3Amounts.computeFeesEarned(
                FeesEarnedPayload({
                    feeGrowthInsideLast: feeGrowthInside0Last,
                    liquidity: liquidity,
                    tick: positionUnderlying_.tick,
                    lowerTick: positionUnderlying_.lowerTick,
                    upperTick: positionUnderlying_.upperTick,
                    isZero: true,
                    pool: positionUnderlying_.pool
                })
            ) +
            uint256(tokensOwed0);
        fee1 =
            UniswapV3Amounts.computeFeesEarned(
                FeesEarnedPayload({
                    feeGrowthInsideLast: feeGrowthInside1Last,
                    liquidity: liquidity,
                    tick: positionUnderlying_.tick,
                    lowerTick: positionUnderlying_.lowerTick,
                    upperTick: positionUnderlying_.upperTick,
                    isZero: false,
                    pool: positionUnderlying_.pool
                })
            ) +
            uint256(tokensOwed1);
    }
}