// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "BalancerMath.sol";
import "BalancerFixedPoint.sol";

// https://etherscan.io/address/0x7b50775383d3d6f0215a8f290f2c9e2eebbeceb2#code#F14#L25
library BalancerStableMath {
    using BalancerFixedPoint for uint256;
	
    uint256 internal constant _AMP_PRECISION = 1e3;
	
    function _calculateInvariant(uint256 amplificationParameter, uint256[] memory balances, bool roundUp) internal pure returns (uint256) {
        /**********************************************************************************************
        // invariant                                                                                 //
        // D = invariant                                                  D^(n+1)                    //
        // A = amplification coefficient      A  n^n S + D = A D n^n + -----------                   //
        // S = sum of balances                                             n^n P                     //
        // P = product of balances                                                                   //
        // n = number of tokens                                                                      //
        **********************************************************************************************/

        uint256 sum = 0; // S in the Curve version
        uint256 numTokens = balances.length;
        for (uint256 i = 0; i < numTokens; i++) {
            sum = sum.add(balances[i]);
        }
        if (sum == 0) {
            return 0;
        }

        uint256 prevInvariant = 0;	
        uint256 invariant = sum;	
        uint256 ampTimesTotal = amplificationParameter * numTokens;
		
        for (uint256 i = 0; i < 255; i++) {	
            uint256 P_D = balances[0] * numTokens;	
            for (uint256 j = 1; j < numTokens; j++) {	
                P_D = BalancerMath.div(BalancerMath.mul(BalancerMath.mul(P_D, balances[j]), numTokens), invariant, roundUp);	
            }	
            prevInvariant = invariant;	
            invariant = BalancerMath.div(	
                BalancerMath.mul(BalancerMath.mul(numTokens, invariant), invariant).add(	
                    BalancerMath.div(BalancerMath.mul(BalancerMath.mul(ampTimesTotal, sum), P_D), _AMP_PRECISION, roundUp)	
                ),	
                BalancerMath.mul(numTokens + 1, invariant).add(	
                    // No need to use checked arithmetic for the amp precision, the amp is guaranteed to be at least 1	
                    BalancerMath.div(BalancerMath.mul(ampTimesTotal - _AMP_PRECISION, P_D), _AMP_PRECISION, !roundUp)	
                ),	
                roundUp	
            );

            if (invariant > prevInvariant) {
                if (invariant - prevInvariant <= 1) {
                    return invariant;
                }
            } else if (prevInvariant - invariant <= 1) {
                return invariant;
            }
        }

        require(invariant < 0, '!INVT');
    }

    function _getTokenBalanceGivenInvariantAndAllOtherBalances(uint256 amplificationParameter, uint256[] memory balances, uint256 invariant, uint256 tokenIndex) internal pure returns (uint256) {
        // Rounds result up overall

        uint256 ampTimesTotal = amplificationParameter * balances.length;
        uint256 sum = balances[0];
        uint256 P_D = balances[0] * balances.length;
        for (uint256 j = 1; j < balances.length; j++) {
            P_D = BalancerMath.divDown(BalancerMath.mul(BalancerMath.mul(P_D, balances[j]), balances.length), invariant);
            sum = sum.add(balances[j]);
        }
        // No need to use safe math, based on the loop above `sum` is greater than or equal to `balances[tokenIndex]`
        sum = sum - balances[tokenIndex];

        uint256 inv2 = BalancerMath.mul(invariant, invariant);
        // We remove the balance from c by multiplying it
        uint256 c = BalancerMath.mul(
            BalancerMath.mul(BalancerMath.divUp(inv2, BalancerMath.mul(ampTimesTotal, P_D)), _AMP_PRECISION),
            balances[tokenIndex]
        );
        uint256 b = sum.add(BalancerMath.mul(BalancerMath.divDown(invariant, ampTimesTotal), _AMP_PRECISION));

        // We iterate to find the balance
        uint256 prevTokenBalance = 0;
        // We multiply the first iteration outside the loop with the invariant to set the value of the
        // initial approximation.
        uint256 tokenBalance = BalancerMath.divUp(inv2.add(c), invariant.add(b));

        for (uint256 i = 0; i < 255; i++) {
            prevTokenBalance = tokenBalance;

            tokenBalance = BalancerMath.divUp(
                BalancerMath.mul(tokenBalance, tokenBalance).add(c),
                BalancerMath.mul(tokenBalance, 2).add(b).sub(invariant)
            );

            if (tokenBalance > prevTokenBalance) {
                if (tokenBalance - prevTokenBalance <= 1) {
                    return tokenBalance;
                }
            } else if (prevTokenBalance - tokenBalance <= 1) {
                return tokenBalance;
            }
        }

        require(tokenBalance < 0, '!COVG');
    }

}