// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Pair } from "../../core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "../../core/interfaces/IUniswapV2Factory.sol";
import { DELEGATE_FACTORY, DELEGATE_INIT_CODE_HASH, DELEGATE_NET_FEE } from "../../core/Delegation.sol";

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SweepnFlipLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SweepnFlipLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (pair,) = pairForWithDelegates(factory, tokenA, tokenB);
    }
    function pairForWithDelegates(address factory, address tokenA, address tokenB) internal view returns (address pair, bool delegates) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        delegates = IUniswapV2Factory(factory).delegates(token0, token1);
        if (delegates) {
            pair = address(uint160(uint(keccak256(abi.encodePacked(
                    hex"ff",
                    DELEGATE_FACTORY,
                    keccak256(abi.encodePacked(token0, token1)),
                    DELEGATE_INIT_CODE_HASH
                )))));
        } else {
            pair = address(uint160(uint(keccak256(abi.encodePacked(
                    hex"ff",
                    factory,
                    keccak256(abi.encodePacked(token0, token1)),
                    hex"40fe3646dbd1de3a7a1432bfc8c3130e20f8835674c82fe36ce7af22d3a70490" // init code hash
                )))));
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB,) = getReservesWithDelegates(factory, tokenA, tokenB);
    }
    function getReservesWithDelegates(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB, bool delegates) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair;
        (pair, delegates) = pairForWithDelegates(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "SweepnFlipLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SweepnFlipLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        return getAmountOut(amountIn, reserveIn, reserveOut, DELEGATE_NET_FEE);
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint netFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, "SweepnFlipLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SweepnFlipLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * netFee;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        return getAmountIn(amountOut, reserveIn, reserveOut, DELEGATE_NET_FEE);
    }
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint netFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, "SweepnFlipLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SweepnFlipLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * netFee;
        amountIn = numerator / denominator + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "SweepnFlipLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, bool delegates) = getReservesWithDelegates(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, delegates ? DELEGATE_NET_FEE : 9900);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "SweepnFlipLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, bool delegates) = getReservesWithDelegates(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, delegates ? DELEGATE_NET_FEE : 9900);
        }
    }
}