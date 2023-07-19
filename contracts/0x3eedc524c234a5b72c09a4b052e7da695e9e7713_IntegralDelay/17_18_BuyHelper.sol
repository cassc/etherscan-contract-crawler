// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
// pragma abicoder v2;

import 'IIntegralOracle.sol';
import 'IIntegralPair.sol';
import 'SafeMath.sol';

library BuyHelper {
    using SafeMath for uint256;
    uint256 public constant PRECISION = 10**18;

    function getSwapAmount0In(address pair, uint256 amount1Out) external view returns (uint256 swapAmount0In) {
        (uint112 reserve0, uint112 reserve1, ) = IIntegralPair(pair).getReserves();
        (uint112 reference0, uint112 reference1, ) = IIntegralPair(pair).getReferences();
        uint256 balance1After = uint256(reserve1).sub(amount1Out);
        uint256 balance0After = IIntegralOracle(IIntegralPair(pair).oracle()).tradeY(
            balance1After,
            reference0,
            reference1
        );
        uint256 swapFee = IIntegralPair(pair).swapFee();
        return balance0After.sub(uint256(reserve0)).mul(PRECISION).ceil_div(PRECISION.sub(swapFee));
    }

    function getSwapAmount1In(address pair, uint256 amount0Out) external view returns (uint256 swapAmount1In) {
        (uint112 reserve0, uint112 reserve1, ) = IIntegralPair(pair).getReserves();
        (uint112 reference0, uint112 reference1, ) = IIntegralPair(pair).getReferences();
        uint256 balance0After = uint256(reserve0).sub(amount0Out);
        uint256 balance1After = IIntegralOracle(IIntegralPair(pair).oracle()).tradeX(
            balance0After,
            reference0,
            reference1
        );
        uint256 swapFee = IIntegralPair(pair).swapFee();
        return balance1After.add(1).sub(uint256(reserve1)).mul(PRECISION).ceil_div(PRECISION.sub(swapFee));
    }
}