// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import '../../core/interfaces/ISCRYPair.sol';

import "./SafeMathSCRY.sol";

library SCRYLibrary {
    using SafeMathSCRY for uint;

    uint256 private constant MAX_FEE = 10000;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SCRYLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SCRYLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'145dd2cfa2424da880d617d54d12f91d8751490aed761f21141a44032bee5947' // hardhat
                // hex'f2b57fa1700ce1fa58cc33bd5169a52d4fee4581fe629136551e37fe91552963' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReservesAndFee(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB, uint swapFee) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pairAddress = pairFor(factory, tokenA, tokenB);
        ISCRYPair pair = ISCRYPair(pairAddress);
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        swapFee = pair.getSwapFee();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SCRYLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SCRYLibrary: INSUFFICIENT_LIQUIDITYQ');
        // amount * price
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SCRYLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SCRYLibrary: INSUFFICIENT_LIQUIDITY1');
        uint GAMMA = MAX_FEE.sub(swapFee);
        uint amountInWithFee = amountIn.mul(GAMMA);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(MAX_FEE).add(amountIn.mul(MAX_FEE.add(GAMMA)));
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'SCRYLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SCRYLibrary: INSUFFICIENT_LIQUIDITY2');
        uint GAMMA = MAX_FEE.sub(swapFee);
        uint numerator = reserveIn.mul(amountOut).mul(MAX_FEE);
        uint denominator = reserveOut.mul(GAMMA).sub(amountOut.mul(MAX_FEE.add(GAMMA)));
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SCRYLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, uint swapFee) = getReservesAndFee(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, swapFee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SCRYLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, uint swapFee) = getReservesAndFee(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, swapFee);
        }
    }
}