// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MathLib.sol";
import "./PendleStructs.sol";

library MarketMath {
    using SafeMath for uint256;

    /**
     * @notice calculate the exact amount of tokens that user need to put in the market
     *      in order to get back certain amount of the other token
     * @param inTokenReserve market reserve details of token that user wants to put in
     * @param outTokenReserve market reserve details of token that user wants to get back
     * @param exactOut exact amount of token that user wants to get back
     * @param swapFee swap fee ratio for swap
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcExactIn(
        TokenReserve memory inTokenReserve,
        TokenReserve memory outTokenReserve,
        uint256 exactOut,
        uint256 swapFee
    ) internal pure returns (uint256 exactIn) {
        uint256 weightRatio = Math.rdiv(outTokenReserve.weight, inTokenReserve.weight);
        uint256 diff = outTokenReserve.balance.sub(exactOut);
        uint256 y = Math.rdiv(outTokenReserve.balance, diff);
        uint256 foo = Math.rpow(y, weightRatio);

        foo = foo.sub(Math.RONE);
        exactIn = Math.RONE.sub(swapFee);
        exactIn = Math.rdiv(Math.rmul(inTokenReserve.balance, foo), exactIn);
    }

    /**
     * @notice calculate the exact amount of tokens that user can get back from the market
     *      if user put in certain amount of the other token
     * @param inTokenReserve market reserve details of token that user wants to put in
     * @param outTokenReserve market reserve details of token that user wants to get back
     * @param exactIn exact amount of token that user wants to put in
     * @param swapFee swap fee (percentage) for swap
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcExactOut(
        TokenReserve memory inTokenReserve,
        TokenReserve memory outTokenReserve,
        uint256 exactIn,
        uint256 swapFee
    ) internal pure returns (uint256 exactOut) {
        uint256 weightRatio = Math.rdiv(inTokenReserve.weight, outTokenReserve.weight);
        uint256 adjustedIn = Math.RONE.sub(swapFee);
        adjustedIn = Math.rmul(exactIn, adjustedIn);
        uint256 y = Math.rdiv(inTokenReserve.balance, inTokenReserve.balance.add(adjustedIn));
        uint256 foo = Math.rpow(y, weightRatio);
        uint256 bar = Math.RONE.sub(foo);

        exactOut = Math.rmul(outTokenReserve.balance, bar);
    }

    /**
     * @notice to calculate exact amount of lp token to be minted if single token liquidity is added to market
     * @param inAmount exact amount of the token that user wants to put in
     * @param inTokenReserve market reserve details of the token that user wants to put in
     * @param swapFee swap fee (percentage) for swap
     * @param totalSupplyLp current (before adding liquidity) lp supply
     * @dev swap fee applies here since add liquidity by single token is equivalent of a swap
     * @dev used when add liquidity by single token
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcOutAmountLp(
        uint256 inAmount,
        TokenReserve memory inTokenReserve,
        uint256 swapFee,
        uint256 totalSupplyLp
    ) internal pure returns (uint256 exactOutLp) {
        uint256 nWeight = inTokenReserve.weight;
        uint256 feePortion = Math.rmul(Math.RONE.sub(nWeight), swapFee);
        uint256 inAmountAfterFee = Math.rmul(inAmount, Math.RONE.sub(feePortion));

        uint256 inBalanceUpdated = inTokenReserve.balance.add(inAmountAfterFee);
        uint256 inTokenRatio = Math.rdiv(inBalanceUpdated, inTokenReserve.balance);

        uint256 lpTokenRatio = Math.rpow(inTokenRatio, nWeight);
        uint256 totalSupplyLpUpdated = Math.rmul(lpTokenRatio, totalSupplyLp);
        exactOutLp = totalSupplyLpUpdated.sub(totalSupplyLp);
        return exactOutLp;
    }

    /**
     * @notice to calculate exact amount of token that user can get back if
     *      single token liquidity is removed from market
     * @param outTokenReserve market reserve details of the token that user wants to get back
     * @param totalSupplyLp current (before adding liquidity) lp supply
     * @param inLp exact amount of the lp token (single liquidity to remove) that user wants to put in
     * @param swapFee swap fee (percentage) for swap
     * @dev swap fee applies here since add liquidity by single token is equivalent of a swap
     * @dev used when remove liquidity by single token
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcOutAmountToken(
        TokenReserve memory outTokenReserve,
        uint256 totalSupplyLp,
        uint256 inLp,
        uint256 swapFee
    ) internal pure returns (uint256 exactOutToken) {
        uint256 nWeight = outTokenReserve.weight;
        uint256 totalSupplyLpUpdated = totalSupplyLp.sub(inLp);
        uint256 lpRatio = Math.rdiv(totalSupplyLpUpdated, totalSupplyLp);

        uint256 outTokenRatio = Math.rpow(lpRatio, Math.rdiv(Math.RONE, nWeight));
        uint256 outTokenBalanceUpdated = Math.rmul(outTokenRatio, outTokenReserve.balance);

        uint256 outAmountTokenBeforeSwapFee = outTokenReserve.balance.sub(outTokenBalanceUpdated);

        uint256 feePortion = Math.rmul(Math.RONE.sub(nWeight), swapFee);
        exactOutToken = Math.rmul(outAmountTokenBeforeSwapFee, Math.RONE.sub(feePortion));
        return exactOutToken;
    }
}