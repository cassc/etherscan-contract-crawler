// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract PancakeLibrary is SafeMath {

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        // amountB = amountA.mul(reserveB) / reserveA;
        amountB = mul(amountA, reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        // uint amountInWithFee = amountIn.mul(998);
        uint amountInWithFee = mul(amountIn, 998);
        // uint numerator = amountInWithFee.mul(reserveOut);
        uint numerator = mul(amountInWithFee, reserveOut);
        // uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint denominator = add(mul(reserveIn,1000), amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        // uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint numerator = mul(mul(reserveIn,amountOut), 1000);
        // uint denominator = reserveOut.sub(amountOut).mul(998);
        uint denominator = mul(sub(reserveOut, amountOut), 998);
        // amountIn = (numerator / denominator).add(1);
        amountIn = add((numerator / denominator), 1);
    }

}
