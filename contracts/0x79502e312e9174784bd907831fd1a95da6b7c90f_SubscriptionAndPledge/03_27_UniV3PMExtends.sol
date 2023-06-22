// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./FixedPoint128.sol";
import "./PoolAddress.sol";


/// @title UniV3 extends libraries
/// @notice libraries
library UniV3PMExtends {

    //Nonfungible Position Manager
    INonfungiblePositionManager constant internal PM = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function positionKey(
        address addr,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr, tickLower, tickUpper));
    }

    /// @notice get pool by tokenId
    /// @param tokenId position Id
    function getPool(uint256 tokenId) internal view returns (address){
        (
        ,
        ,
        address token0,
        address token1,
        uint24 fee,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PM.positions(tokenId);
        return PoolAddress.getPool(token0, token1, fee);
    }

    function get_liquidty(uint256 tokenId) internal view returns (address,address,uint24,int24,int24,uint128){
        (
        ,
        ,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        ,
        ,
        ,
        ) = PM.positions(tokenId);
        return (token0,token1,fee,tickLower,tickUpper,liquidity);
    }
    /// @notice Calculate the number of redeemable tokens based on the amount of liquidity
    /// @dev Used when redeeming liquidity
    /// @param token0 Token 0 address
    /// @param token1 Token 1 address
    /// @param fee Fee rate
    /// @param tickLower Tick lower price bound
    /// @param tickUpper Tick upper price bound
    /// @param liquidity Liquidity amount
    /// @return amount0 Token 0 amount
    /// @return amount1 Token 1 amount
    function getAmountsForLiquidity(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(PoolAddress.getPool(token0, token1, fee)).slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );
    }

    ///@notice Calculate unreceived handling fees for liquid positions
    /// @param tokenId Position ID
    /// @return fee0 Token 0 fee amount
    /// @return fee1 Token 1 fee amount
    function getFeesForLiquidity(
        uint256 tokenId
    ) internal view returns (uint256 fee0, uint256 fee1){
        (
        ,
        ,
        ,
        ,
        ,
        ,
        ,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
        ) = PM.positions(tokenId);
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(tokenId);
        fee0 = tokensOwed0 + FullMath.mulDiv(
            feeGrowthInside0X128 - feeGrowthInside0LastX128,
            liquidity,
            FixedPoint128.Q128
        );
        fee1 = tokensOwed1 + FullMath.mulDiv(
            feeGrowthInside1X128 - feeGrowthInside1LastX128,
            liquidity,
            FixedPoint128.Q128
        );
    }

    /// @notice Retrieves fee growth data
    function getFeeGrowthInside(
        uint256 tokenId
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        (
        ,
        ,
        ,
        ,
        ,
        int24 tickLower,
        int24 tickUpper,
        ,
        ,
        ,
        ,
        ) = PM.positions(tokenId);
        IUniswapV3Pool pool = IUniswapV3Pool(getPool(tokenId));
        (,int24 tickCurrent,,,,,) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();

        (
        ,
        ,
        uint256 lowerFeeGrowthOutside0X128,
        uint256 lowerFeeGrowthOutside1X128,
        ,
        ,
        ,
        ) = pool.ticks(tickLower);

        (
        ,
        ,
        uint256 upperFeeGrowthOutside0X128,
        uint256 upperFeeGrowthOutside1X128,
        ,
        ,
        ,
        ) = pool.ticks(tickUpper);

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lowerFeeGrowthOutside0X128;
            feeGrowthBelow1X128 = lowerFeeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upperFeeGrowthOutside0X128;
            feeGrowthAbove1X128 = upperFeeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }
}