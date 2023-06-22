// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./UniV3PMExtends.sol";

contract univ3sdk {

    function getAmountsForLiquidity(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) public view returns (uint256 amount0, uint256 amount1) {
        return UniV3PMExtends.getAmountsForLiquidity(
            token0, token1, fee, tickLower, tickUpper, liquidity
        );
    }

    function getFeesForLiquidity(uint256 tokenId) public view returns (uint256 fee0, uint256 fee1) {
        return UniV3PMExtends.getFeesForLiquidity(tokenId);
    }

    function getLiquidty(uint256 tokenId) public view returns (address,address,uint24,int24,int24,uint128){
        // token0,token1,fee,tickLower,tickUpper,liquidity
        return UniV3PMExtends.get_liquidty(tokenId);
    }

    function getAmountsForLiquidityNew(uint256 tokenId) public virtual view returns(uint256 amount0, uint256 amount1){
        (
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
        ) = getLiquidty(tokenId);
        return getAmountsForLiquidity(token0,token1,fee,tickLower,tickUpper,liquidity);
    }
}