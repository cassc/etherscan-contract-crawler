// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/LogExpMath.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeCast.sol";
import "@swaap-labs/v2-errors/contracts/SwaapV2Errors.sol";

library SafeguardMath {

    using FixedPoint for uint256;
    using SafeCast for uint256;

    uint256 private constant _ONE_YEAR = 365 days;

    /**
    * @notice slippage based on the lag between quotation and execution time
    */
    function calcTimeBasedPenalty(
        uint256 currentTimestamp,
        uint256 startTime,
        uint256 timeBasedSlippage
    ) internal pure returns(uint256) {

        if(currentTimestamp <= startTime) {
            return 0;
        }

        return Math.mul(timeBasedSlippage, (currentTimestamp - startTime));

    }

    /**
    * @notice slippage based on the change of the pool's balance between quotation and execution time
    * @param balanceTokenIn actual balance of the token in before the swap
    * @param balanceTokenOut actual balance of the token out before the swap
    * @param totalSupply total supply of the pool during swap time
    * @param quoteBalanceIn expected balance of the token in at the time of the quote
    * @param quoteBalanceOut expected balance of the token out at the time of the quote
    * @param quoteTotalSupply expected total supply of the pool at the time of the quote
    * @param balanceChangeTolerance max percentage change of the pool's balance between quotation and execution
    * @param balanceBasedSlippage slope based on the change of the pool's balance between quotation and execution
    */
    function calcBalanceBasedPenalty(
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        uint256 totalSupply,
        uint256 quoteBalanceIn,
        uint256 quoteBalanceOut,
        uint256 quoteTotalSupply,
        uint256 balanceChangeTolerance,
        uint256 balanceBasedSlippage
    ) internal pure returns (uint256) {
        
        // if the expected balance of the token in is lower than the actual balance, we apply a penalty
        uint256 balanceDevIn = Math.max(
            calcBalanceDeviation(balanceTokenIn, quoteBalanceIn),
            calcBalanceDeviation(balanceTokenIn.divDown(totalSupply), quoteBalanceIn.divDown(quoteTotalSupply))
        );

        // if the expected balance of the token out is lower than the actual balance, we apply a penalty
        uint256 balanceDevOut = Math.max(
            calcBalanceDeviation(balanceTokenOut, quoteBalanceOut),
            calcBalanceDeviation(balanceTokenOut.divDown(totalSupply), quoteBalanceOut.divDown(quoteTotalSupply))
        );

        uint256 maxDeviation = Math.max(balanceDevIn, balanceDevOut);

        _srequire(maxDeviation <= balanceChangeTolerance, SwaapV2Errors.QUOTE_BALANCE_NO_LONGER_VALID);

        return balanceBasedSlippage.mulUp(maxDeviation);
    }

    function calcBalanceDeviation(uint256 currentBalance, uint256 quoteBalance) internal pure returns(uint256) {
        return currentBalance >= quoteBalance ? 0 : (quoteBalance - currentBalance).divDown(quoteBalance);
    }

    /**
    * @notice slippage based on the transaction origin
    */
    function calcOriginBasedPenalty(
        address expectedOrigin,
        uint256 originBasedSlippage
    ) internal view returns(uint256) {
 
        if(expectedOrigin != tx.origin) {
            return originBasedSlippage;
        }

        return 0;
    }

    /**********************************************************************************************
    // aE = amountIn in excess                                                                   //
    // aL = limiting amountIn                                                                    //
    // bE = current balance of excess token                  /       aE * bL - aL * bE       \   //
    // bL = current balance of limiting token         sIn = | ------------------------------- |  //
    // sIn = swap amount in needed before the join           \ bL + aL + (1/p) * ( bE + aE ) /   //
    // sOut = swap amount out needed before the join                                             //
    // p = relative price such that: sIn = p * sOut                                              //
    **********************************************************************************************/
    function calcJoinSwapAmounts(
        uint256 excessTokenBalance,
        uint256 limitTokenBalance,
        uint256 excessTokenAmountIn,
        uint256 limitTokenAmountIn,
        uint256 quoteAmountInPerOut
    ) internal pure returns (uint256, uint256) {

        uint256 foo = excessTokenAmountIn.mulDown(limitTokenBalance);
        uint256 bar = limitTokenAmountIn.mulDown(excessTokenBalance);
        _srequire(foo >= bar, SwaapV2Errors.WRONG_TOKEN_IN_IN_EXCESS);
        uint256 num = foo - bar;

        uint256 denom = limitTokenBalance.add(limitTokenAmountIn);
        denom = denom.add((excessTokenBalance.add(excessTokenAmountIn)).divDown(quoteAmountInPerOut));

        uint256 swapAmountIn = num.divDown(denom);
        uint256 swapAmountOut = swapAmountIn.divDown(quoteAmountInPerOut);

        return (swapAmountIn, swapAmountOut);
    }

    /**********************************************************************************************
    // aE = amountIn in excess                                                                   //
    // bE = current balance of excess token                        / aE - sIn  \                 //
    // sIn = swap amount in needed before the join         rOpt = | ----------- |                //
    // rOpt = amountIn TV / current pool TVL                       \ bE + sIn  /                 //
    **********************************************************************************************/
    function calcJoinSwapROpt(
        uint256 excessTokenBalance,
        uint256 excessTokenAmountIn,
        uint256 swapAmountIn
    ) internal pure returns (uint256) {
        uint256 num   = excessTokenAmountIn.sub(swapAmountIn);
        uint256 denom = excessTokenBalance.add(swapAmountIn);

        // removing 1wei from the numerator and adding 1wei to the denominator to make up for rounding errors
        // that may have accumulated in previous calculations
        return (num.sub(1)).divDown(denom.add(1));
    }

    /**********************************************************************************************
    // aE = amountOut in excess                                                                  //
    // aL = limiting amountOut                                                                   //
    // bE = current balance of excess token                   /     aE * bL - aL * bE     \      //
    // bL = current balance of limiting token         sOut = | --------------------------- |     //
    // sIn = swap amount in needed before the exit            \ bL - aL + p * ( bE - aE ) /      //
    // sOut = swap amount out needed before the exit                                             //
    // p = relative price such that: sIn = p * sOut                                              //
    **********************************************************************************************/
    function calcExitSwapAmounts(
        uint256 excessTokenBalance,
        uint256 limitTokenBalance,
        uint256 excessTokenAmountOut,
        uint256 limitTokenAmountOut,
        uint256 quoteAmountInPerOut
    ) internal pure returns (uint256, uint256) {

        uint256 foo = excessTokenAmountOut.mulDown(limitTokenBalance);
        uint256 bar = limitTokenAmountOut.mulDown(excessTokenBalance);
        _srequire(foo >= bar, SwaapV2Errors.WRONG_TOKEN_OUT_IN_EXCESS);
        uint256 num = foo - bar;

        uint256 denom = limitTokenBalance.sub(limitTokenAmountOut);
        denom = denom.add((excessTokenBalance.sub(excessTokenAmountOut)).mulDown(quoteAmountInPerOut));

        uint256 swapAmountOut = num.divDown(denom);

        uint256 swapAmountIn = quoteAmountInPerOut.mulDown(swapAmountOut);

        return (swapAmountIn, swapAmountOut);
    }

    /**********************************************************************************************
    // aE = amountOut in excess                                                                  //
    // bE = current balance of excess token                        / aE - sOut  \                //
    // sOut = swap amount out needed before the exit       rOpt = | ----------- |                //
    // rOpt = amountOut TV / current pool TVL                      \ bE - sOut  /                //
    **********************************************************************************************/
    function calcExitSwapROpt(
        uint256 excessTokenBalance,
        uint256 excessTokenAmountOut,
        uint256 swapAmountOut
    ) internal pure returns (uint256) {
        uint256 num   = excessTokenAmountOut.sub(swapAmountOut);
        uint256 denom = excessTokenBalance.sub(swapAmountOut);
        
        // adding 1wei to the numerator and removing 1wei from the denominator to make up for rounding errors
        // that may have accumulated in previous calculations
        return (num.add(1)).divDown(denom.sub(1));
    }

    /**********************************************************************************************
    // f = yearly management fees percentage          /  ln(1 - f) \                             //
    // 1y = 1 year                             a = - | ------------ |                            //
    // a = yearly rate constant                       \     1y     /                             //
    **********************************************************************************************/
    function calcYearlyRate(uint256 yearlyFees) internal pure returns(uint256) {
        uint256 logInput = FixedPoint.ONE.sub(yearlyFees);
        // Since 0 < logInput <= 1 => logResult <= 0
        int256 logResult = LogExpMath.ln(int256(logInput));
        return(uint256(-logResult) / _ONE_YEAR);
    }

    /**********************************************************************************************
    // bptOut = bpt tokens to be minted as fees                                                  //
    // TS = total supply                                   bptOut = TS * (e^(a*dT) -1)           //
    // a = yearly rate constant                                                                  //
    // dT = elapsed time between the previous and current claim                                  //
    **********************************************************************************************/
    function calcAccumulatedManagementFees(
        uint256 elapsedTime,
        uint256 yearlyRate,
        uint256 currentSupply
     ) internal pure returns(uint256) {
        uint256 expInput = Math.mul(yearlyRate, elapsedTime);
        uint256 expResult = uint256(LogExpMath.exp(expInput.toInt256()));
        return (currentSupply.mulDown(expResult.sub(FixedPoint.ONE)));
    }

}