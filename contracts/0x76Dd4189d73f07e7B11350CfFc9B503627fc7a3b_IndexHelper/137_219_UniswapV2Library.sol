// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/// @title Uniswap V2 library
/// @notice Provides list of helper functions to calculate pair amounts and reserves
library UniswapV2Library {
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA First pair token
    /// @param tokenB Second pair token
    /// @return token0 One of pair tokens that goes first after sorting
    /// @return token1 One of pair token that goes second after sorting
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /// @notice Returns address of pair for given tokens
    /// @param factory Uniswap V2 factory
    /// @param tokenA First pair token
    /// @param tokenB Second pair token
    /// @return pair Returns pair address of the provided tokens
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    /// @notice Fetches and sorts the reserves for a pair
    /// @param factory Uniswap V2 factory
    /// @param tokenA First pair token
    /// @param tokenB Second pair token
    /// @return reserveA Reserves of the token that goes first after sorting
    /// @return reserveB Reserves of the token that goes second after sorting
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @param amountA Amount of token A
    /// @param reserveA Token A reserves
    /// @param reserveB Token B reserves
    /// @return amountB Equivalent amount of token B
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA != 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA != 0 && reserveB != 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    /// @param amountIn Input token amount
    /// @param reserveIn Input token reserves
    /// @param reserveOut Output token reserves
    /// @return amountOut Output token amount
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn != 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn != 0 && reserveOut != 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    /// @param amountOut Output token amount
    /// @param reserveIn Input token reserves
    /// @param reserveOut Output token reserves
    /// @return amountIn Input token amount
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut != 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn != 0 && reserveOut != 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    /// @notice Performs chained getAmountOut calculations on any number of pairs
    /// @param factory Uniswap V2 factory
    /// @param amountIn Input amount for the first token
    /// @param path List of tokens, that will be used to compose pairs for chained getAmountOut calculations
    /// @return amounts Array of output amounts
    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; ) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Performs chained getAmountIn calculations on any number of pairs
    /// @param factory Uniswap V2 factory
    /// @param amountOut Output amount for the first token
    /// @param path List of tokens, that will be used to compose pairs for chained getAmountIn calculations
    /// @return amounts Array of input amounts
    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}