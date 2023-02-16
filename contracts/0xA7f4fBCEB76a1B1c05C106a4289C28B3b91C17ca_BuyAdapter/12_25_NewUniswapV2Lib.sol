// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./IUniswapV2Pair.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library NewUniswapV2Lib {
    using SafeMath for uint256;

    function getReservesByPair(address pair, bool direction)
        internal
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (reserveIn, reserveOut) = direction ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(
        uint256 amountIn,
        address pair,
        bool direction,
        uint256 fee
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Lib: INSUFFICIENT_INPUT_AMOUNT");
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, direction);
        uint256 amountInWithFee = amountIn.mul(fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = uint256(numerator / denominator);
    }

    function getAmountIn(
        uint256 amountOut,
        address pair,
        bool direction,
        uint256 fee
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Lib: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, direction);
        require(reserveOut > amountOut, "UniswapV2Lib: reserveOut should be greater than amountOut");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }
}