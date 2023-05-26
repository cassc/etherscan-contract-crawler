// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IUniswapV2Pair.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Pair pair);
}

library UniswapV2Library {
    using SafeMath for uint256;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TOKordinator: insufficient input amount');
        require(reserveIn > 0 && reserveOut > 0, 'TOKordinator: insufficient liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(IUniswapV2Factory factory, uint amountIn, IERC20[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TOKordinator: invalid path');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IUniswapV2Pair pair = factory.getPair(path[i], path[i + 1]);
            (uint reserveA, uint reserveB, ) = pair.getReserves();
            (uint reserveIn, uint reserveOut) = address(path[i]) < address(path[i + 1]) ? (reserveA, reserveB) : (reserveB, reserveA);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
}