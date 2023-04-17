// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {IArrakisV2Resolver} from "./interfaces/IArrakisV2Resolver.sol";
import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IArrakisV2Helper} from "./interfaces/IArrakisV2Helper.sol";
import {IArrakisV2} from "./interfaces/IArrakisV2.sol";
import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Underlying as UnderlyingHelper} from "./libraries/Underlying.sol";
import {Position as PositionHelper} from "./libraries/Position.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/FullMath.sol";
import {TickMath} from "@arrakisfi/v3-lib-0.8/contracts/TickMath.sol";
import {
    LiquidityAmounts
} from "@arrakisfi/v3-lib-0.8/contracts/LiquidityAmounts.sol";
import {
    PositionLiquidity,
    Range,
    RangeWeight,
    Rebalance
} from "./structs/SArrakisV2.sol";
import {hundredPercent} from "./constants/CArrakisV2.sol";

/// @title ArrakisV2Resolver helpers that resolve / compute payloads for ArrakisV2 calls
contract ArrakisV2Resolver is IArrakisV2Resolver {
    IUniswapV3Factory public immutable factory;
    IArrakisV2Helper public immutable helper;

    constructor(IUniswapV3Factory factory_, IArrakisV2Helper helper_) {
        factory = factory_;
        helper = helper_;
    }

    /// @notice Standard rebalance (without swapping)
    /// @param rangeWeights_ list of ranges by weights.
    /// @param vaultV2_ Arrakis V2 vault.
    /// @return rebalanceParams payload to send to rebalance
    /// function on Arrakis V2 contract.
    // solhint-disable-next-line function-max-lines, code-complexity
    function standardRebalance(
        RangeWeight[] memory rangeWeights_,
        IArrakisV2 vaultV2_
    ) external view returns (Rebalance memory rebalanceParams) {
        uint256 amount0;
        uint256 amount1;
        address token0Addr;
        address token1Addr;
        {
            Range[] memory ranges = vaultV2_.getRanges();

            token0Addr = address(vaultV2_.token0());
            token1Addr = address(vaultV2_.token1());

            (amount0, amount1) = helper.totalUnderlying(vaultV2_);

            PositionLiquidity[] memory pl = new PositionLiquidity[](
                ranges.length
            );
            uint256 numberOfPosLiq;

            for (uint256 i; i < ranges.length; i++) {
                uint128 liquidity;
                {
                    (liquidity, , , , ) = IUniswapV3Pool(
                        factory.getPool(
                            token0Addr,
                            token1Addr,
                            ranges[i].feeTier
                        )
                    ).positions(
                            PositionHelper.getPositionId(
                                address(vaultV2_),
                                ranges[i].lowerTick,
                                ranges[i].upperTick
                            )
                        );
                }

                if (liquidity > 0) numberOfPosLiq++;

                pl[i] = PositionLiquidity({
                    liquidity: liquidity,
                    range: ranges[i]
                });
            }

            rebalanceParams.burns = new PositionLiquidity[](numberOfPosLiq);
            uint256 j;

            for (uint256 i; i < pl.length; i++) {
                if (pl[i].liquidity > 0) {
                    rebalanceParams.burns[j] = pl[i];
                    j++;
                }
            }
        }

        _requireWeightUnder100(rangeWeights_);

        rebalanceParams.mints = new PositionLiquidity[](rangeWeights_.length);

        for (uint256 i; i < rangeWeights_.length; i++) {
            RangeWeight memory rangeWeight = rangeWeights_[i];
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(
                factory.getPool(
                    token0Addr,
                    token1Addr,
                    rangeWeight.range.feeTier
                )
            ).slot0();

            uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(rangeWeight.range.lowerTick),
                TickMath.getSqrtRatioAtTick(rangeWeight.range.upperTick),
                FullMath.mulDiv(amount0, rangeWeight.weight, hundredPercent),
                FullMath.mulDiv(amount1, rangeWeight.weight, hundredPercent)
            );

            rebalanceParams.mints[i] = PositionLiquidity({
                liquidity: liquidity,
                range: rangeWeight.range
            });
        }
    }

    /// @notice Mint Amount.
    /// @param vaultV2_ Arrakis V2 vault.
    /// @param amount0Max_ max amount of token 0.
    /// @param amount1Max_ max amount of token 1.
    /// @return amount0 of token 0 expected to be deposited.
    /// @return amount1 of token 1 expected to be deposited.
    /// @return mintAmount amount f shares expected to be minted.
    // solhint-disable-next-line function-max-lines
    function getMintAmounts(
        IArrakisV2 vaultV2_,
        uint256 amount0Max_,
        uint256 amount1Max_
    )
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (uint256 current0, uint256 current1) = helper.totalUnderlying(vaultV2_);

        uint256 totalSupply = vaultV2_.totalSupply();
        if (totalSupply > 0) {
            (amount0, amount1, mintAmount) = UnderlyingHelper
                .computeMintAmounts(
                    current0,
                    current1,
                    totalSupply,
                    amount0Max_,
                    amount1Max_
                );
        } else
            (amount0, amount1, mintAmount) = UnderlyingHelper
                .computeMintAmounts(
                    vaultV2_.init0(),
                    vaultV2_.init1(),
                    1 ether,
                    amount0Max_,
                    amount1Max_
                );
    }

    /// @notice Exposes Uniswap's getAmountsForLiquidity helper function,
    /// returns amount0 and amount1 for a given amount of liquidity.
    function getAmountsForLiquidity(
        int24 currentTick_,
        int24 lowerTick_,
        int24 upperTick_,
        uint128 liquidity_
    ) external pure returns (uint256 amount0, uint256 amount1) {
        return
            LiquidityAmounts.getAmountsForLiquidity(
                TickMath.getSqrtRatioAtTick(currentTick_),
                TickMath.getSqrtRatioAtTick(lowerTick_),
                TickMath.getSqrtRatioAtTick(upperTick_),
                liquidity_
            );
    }

    /// @notice Expose getPositionId helper function for uniswap positionIds
    /// returns bytes32 positionId
    function getPositionId(
        address addr_,
        int24 lowerTick_,
        int24 upperTick_
    ) external pure returns (bytes32 positionId) {
        return PositionHelper.getPositionId(addr_, lowerTick_, upperTick_);
    }

    // #region view internal functions.

    function _requireWeightUnder100(RangeWeight[] memory rangeWeights_)
        internal
        pure
    {
        uint256 totalWeight;
        for (uint256 i; i < rangeWeights_.length; i++) {
            totalWeight += rangeWeights_[i].weight;
        }

        require(totalWeight <= hundredPercent, "total weight");
    }

    // #endregion view internal functions.
}