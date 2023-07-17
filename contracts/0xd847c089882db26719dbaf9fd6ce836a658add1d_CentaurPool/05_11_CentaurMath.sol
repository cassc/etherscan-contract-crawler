// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { SafeMath } from "./SafeMath.sol";
import { ABDKMathQuad } from './ABDKMathQuad.sol';

library CentaurMath {
    using SafeMath for uint256;

    bytes16 constant ONE_ETHER_QUAD = 0x403ABC16D674EC800000000000000000;

    // Helper Functions
    function getAmountOutFromValue(uint _value, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint amount) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 value_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_value), ONE_ETHER_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X2 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X1 = _solveEquationForAmountOut(
            value_quad,
            X2,
            k_quad,
            P_quad
        );

        bytes16 amountOut = ABDKMathQuad.sub(X2, X1);
        amount = ABDKMathQuad.toUInt(ABDKMathQuad.mul(amountOut, DECIMAL_QUAD));
    }

    function getValueFromAmountIn(uint _amount, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint value) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 amount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_amount), DECIMAL_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X1 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X2 = ABDKMathQuad.add(X1, amount_quad);

        value = _solveForIntegral(
            X1,
            X2,
            k_quad,
            P_quad
        );
    }

    function getAmountInFromValue(uint _value, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint amount) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 value_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_value), ONE_ETHER_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X1 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X2 = _solveEquationForAmountIn(
            value_quad,
            X1,
            k_quad,
            P_quad
        );

        bytes16 amountOut = ABDKMathQuad.sub(X2, X1);
        amount = ABDKMathQuad.toUInt(ABDKMathQuad.mul(amountOut, DECIMAL_QUAD));
    }

    function getValueFromAmountOut(uint _amount, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint value) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 amount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_amount), DECIMAL_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X2 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X1 = ABDKMathQuad.sub(X2, amount_quad);

        value = _solveForIntegral(
            X1,
            X2,
            k_quad,
            P_quad
        );
    }
    // Core Functions
    
    // Solve for Delta
    function _solveForIntegral (
        bytes16 X1, 
        bytes16 X2, 
        bytes16 k,
        bytes16 P
    ) internal pure returns (uint256) {
        bytes16 multiplier = ABDKMathQuad.mul(k, P);

        bytes16 NLog_X2 = ABDKMathQuad.ln(ABDKMathQuad.add(X2, k));
        bytes16 NLog_X1 = ABDKMathQuad.ln(ABDKMathQuad.add(X1, k));

        bytes16 delta = ABDKMathQuad.mul(multiplier, ABDKMathQuad.sub(NLog_X2, NLog_X1));

        return ABDKMathQuad.toUInt(ABDKMathQuad.mul(delta, ONE_ETHER_QUAD));
    }

    // Solve for amountOut
    // Given X2, solve for X1
    function _solveEquationForAmountOut (
        bytes16 delta,
        bytes16 X2,
        bytes16 k,
        bytes16 P
    ) internal pure returns (bytes16 X1) {
        bytes16 NLog_X2 = ABDKMathQuad.ln(ABDKMathQuad.add(X2, k));
        bytes16 deltaOverTotal = ABDKMathQuad.div(delta, ABDKMathQuad.mul(k, P));

        bytes16 ePower = ABDKMathQuad.exp(ABDKMathQuad.sub(NLog_X2, deltaOverTotal));

        X1 = ABDKMathQuad.sub(ePower, k);
    }

    // Solve for amountOut
    // Given X1, solve for X2
    function _solveEquationForAmountIn (
        bytes16 delta,
        bytes16 X1,
        bytes16 k,
        bytes16 P
    ) internal pure returns (bytes16 X2) {
        bytes16 NLog_X1 = ABDKMathQuad.ln(ABDKMathQuad.add(X1, k));
        bytes16 deltaOverTotal = ABDKMathQuad.div(delta, ABDKMathQuad.mul(k, P));

        bytes16 ePower = ABDKMathQuad.exp(ABDKMathQuad.add(deltaOverTotal, NLog_X1));

        X2 = ABDKMathQuad.sub(ePower, k);
    }
}