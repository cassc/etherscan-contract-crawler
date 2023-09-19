// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import {DecimalMath} from "./DecimalMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DODOMath
 * @author DODO Breeder
 *
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library DODOMath {
    /*
        Integrate dodo curve from V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))

        i is the price of V-res trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        uint256 fairAmount = i * (V1 - V2); // i*delta
        if (k == 0) {
            return fairAmount / DecimalMath.ONE;
        }
        uint256 V0V0V1V2 = DecimalMath.divFloor(V0 * V0 / V1, V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return (DecimalMath.ONE - k + penalty) * fairAmount / DecimalMath.ONE2;
    }

    /*
        Follow the integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2 
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan

        if deltaBSig=true, then Q2>Q1, user sell Q and receive B
        if deltaBSig=false, then Q2<Q1, user sell B and receive Q
        return |Q1-Q2|

        as we only support sell amount as delta, the deltaB is always negative
        the input ideltaB is actually -ideltaB in the equation

        i is the price of delta-V trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 V0,
        uint256 V1,
        uint256 delta,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        if (delta == 0) {
            return 0;
        }

        if (k == 0) {
            // why v1
            return DecimalMath.mulFloor(i, delta) > V1 ? V1 : DecimalMath.mulFloor(i, delta);
        }

        if (k == DecimalMath.ONE) {
            // if k==1
            // Q2=Q1/(1+ideltaBQ1/Q0/Q0)
            // temp = ideltaBQ1/Q0/Q0
            // Q2 = Q1/(1+temp)
            // Q1-Q2 = Q1*(1-1/(1+temp)) = Q1*(temp/(1+temp))
            // uint256 temp = i.mul(delta).mul(V1).div(V0.mul(V0));
            uint256 temp;
            uint256 idelta = i * (delta);
            if (idelta == 0) {
                temp = 0;
            } else if ((idelta * V1) / idelta == V1) {
                temp = (idelta * V1) / (V0 * (V0));
            } else {
                temp = delta * (V1) / (V0) * (i) / (V0);
            }
            return V1 * (temp) / (temp + (DecimalMath.ONE));
        }

        // calculate -b value and sig
        // b = kQ0^2/Q1-i*deltaB-(1-k)Q1
        // part1 = (1-k)Q1 >=0
        // part2 = kQ0^2/Q1-i*deltaB >=0
        // bAbs = abs(part1-part2)
        // if part1>part2 => b is negative => bSig is false
        // if part2>part1 => b is positive => bSig is true
        uint256 part2 = k * (V0) / (V1) * (V0) + (i * (delta)); // kQ0^2/Q1-i*deltaB
        uint256 bAbs = (DecimalMath.ONE - k) * (V1); // (1-k)Q1

        bool bSig;
        if (bAbs >= part2) {
            bAbs = bAbs - part2;
            bSig = false;
        } else {
            bAbs = part2 - bAbs;
            bSig = true;
        }
        bAbs = bAbs / (DecimalMath.ONE);

        // calculate sqrt
        uint256 squareRoot = DecimalMath.mulFloor((DecimalMath.ONE - k) * (4), DecimalMath.mulFloor(k, V0) * (V0)); // 4(1-k)kQ0^2
        squareRoot = Math.sqrt((bAbs * bAbs) + squareRoot); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = (DecimalMath.ONE - k) * 2; // 2(1-k)
        uint256 numerator;
        if (bSig) {
            numerator = squareRoot - bAbs;
        } else {
            numerator = bAbs + squareRoot;
        }

        uint256 V2 = DecimalMath.divCeil(numerator, denominator);
        if (V2 > V1) {
            return 0;
        } else {
            return V1 - V2;
        }
    }
}