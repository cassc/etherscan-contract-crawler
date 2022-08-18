// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IUniswapV2Factory.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function sortNumbersForTokens(address tokenA, address tokenB, uint amountA, uint amountB) internal pure returns (uint amount0, uint amount1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (amount0, amount1) = tokenA < tokenB ? (amountA, amountB) : (amountB, amountA);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    // The create code for a pair will match PairProxy
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).pairFor(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getQuantums(address factory, address tokenA, address tokenB) internal view returns (uint lpQuantum, uint tokenAQuantum, uint tokenBQuantum) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint _lpQuantum, uint token0Q, uint token1Q) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getQuantums();
        lpQuantum = _lpQuantum;
        (tokenAQuantum, tokenBQuantum) = tokenA == token0 ? (token0Q, token1Q) : (token1Q, token0Q);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn;
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            (, uint quantumA, uint quantumB) = getQuantums(factory, path[i], path[i + 1]);
            uint amount = truncate(quantumA, amounts[i]);
            amounts[i + 1] = truncate(quantumB, getAmountOut(amount, reserveIn, reserveOut));
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            (,uint quantumA, uint quantumB) = getQuantums(factory, path[i - 1], path[i]);
            uint amount = truncate(quantumB, amounts[i]);
            amounts[i - 1] = roundUp(quantumA, getAmountIn(amount, reserveIn, reserveOut));
        }
    }

    function truncate(uint quantum, uint amount) private pure returns (uint) {
      if (amount < quantum) {
        return 0;
      }

      return amount.sub(amount % quantum);
    }

    function roundUp(uint quantum, uint amount) private pure returns (uint) {
      if (amount < quantum) {
        return quantum;
      }

      if (amount % quantum == 0) {
        return amount;
      }

      return amount.sub(amount % quantum).add(quantum);
    }
}