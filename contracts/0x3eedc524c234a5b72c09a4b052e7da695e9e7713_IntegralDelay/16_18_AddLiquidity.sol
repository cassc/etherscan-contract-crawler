// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'TransferHelper.sol';
import 'SafeMath.sol';
import 'Math.sol';
import 'Normalizer.sol';
import 'IIntegralPair.sol';
import 'IIntegralOracle.sol';

library AddLiquidity {
    using SafeMath for uint256;

    function _quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256 amountB) {
        require(amount0 > 0, 'AL_INSUFFICIENT_AMOUNT');
        require(reserve0 > 0 && reserve1 > 0, 'AL_INSUFFICIENT_LIQUIDITY');
        amountB = amount0.mul(reserve1) / reserve0;
    }

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 amount0, uint256 amount1) {
        if (amount0Desired == 0 || amount1Desired == 0) {
            return (0, 0);
        }
        (uint256 reserve0, uint256 reserve1, ) = IIntegralPair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = _quote(amount0Desired, reserve0, reserve1);
            if (amount1Optimal <= amount1Desired) {
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = _quote(amount1Desired, reserve1, reserve0);
                assert(amount0Optimal <= amount0Desired);
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
    }

    function swapDeposit0(
        address pair,
        address token0,
        uint256 amount0,
        uint256 minSwapPrice
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount0In = IIntegralPair(pair).getDepositAmount0In(amount0);
        amount1Left = IIntegralPair(pair).getSwapAmount1Out(amount0In);
        if (amount1Left == 0) {
            return (amount0, amount1Left);
        }
        uint256 price = getPrice(amount0In, amount1Left, pair);
        require(minSwapPrice == 0 || price >= minSwapPrice, 'AL_PRICE_TOO_LOW');
        TransferHelper.safeTransfer(token0, pair, amount0In);
        IIntegralPair(pair).swap(0, amount1Left, address(this));
        amount0Left = amount0.sub(amount0In);
    }

    function swapDeposit1(
        address pair,
        address token1,
        uint256 amount1,
        uint256 maxSwapPrice
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount1In = IIntegralPair(pair).getDepositAmount1In(amount1);
        amount0Left = IIntegralPair(pair).getSwapAmount0Out(amount1In);
        if (amount0Left == 0) {
            return (amount0Left, amount1);
        }
        uint256 price = getPrice(amount0Left, amount1In, pair);
        require(maxSwapPrice == 0 || price <= maxSwapPrice, 'AL_PRICE_TOO_HIGH');
        TransferHelper.safeTransfer(token1, pair, amount1In);
        IIntegralPair(pair).swap(amount0Left, 0, address(this));
        amount1Left = amount1.sub(amount1In);
    }

    function getPrice(
        uint256 amount0,
        uint256 amount1,
        address pair
    ) internal view returns (uint256) {
        IIntegralOracle oracle = IIntegralOracle(IIntegralPair(pair).oracle());
        uint8 xDecimals = oracle.xDecimals();
        uint8 yDecimals = oracle.yDecimals();
        return Normalizer.normalize(amount1, yDecimals).mul(1e18).div(Normalizer.normalize(amount0, xDecimals));
    }

    function canSwap(
        uint256 initialRatio, // setting it to 0 disables swap
        uint256 minRatioChangeToSwap,
        address pairAddress
    ) external view returns (bool) {
        (uint256 reserve0, uint256 reserve1, ) = IIntegralPair(pairAddress).getReserves();
        if (reserve0 == 0 || reserve1 == 0 || initialRatio == 0) {
            return false;
        }
        uint256 ratio = reserve0.mul(1e18).div(reserve1);
        // ratioChange(before, after) = MAX(before, after) / MIN(before, after) - 1
        uint256 change = Math.max(initialRatio, ratio).mul(1e3).div(Math.min(initialRatio, ratio)).sub(1e3);
        return change >= minRatioChangeToSwap;
    }
}