pragma solidity =0.5.16;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./Math.sol";
import "../interfaces/IZirconPair.sol";

library ZirconLibrary {
    using SafeMath for uint256;
    using SafeMath for uint112;
    struct Decimals {
        uint float;
        uint anchor;
        uint priceMultiplier; //avoids precision loss
    }

    struct ParabolaCoefficients {
        uint a;
        uint b;
        bool aNegative;
        bool bNegative;
    }

    function calculateParabolaCoefficients(Decimals storage decimals, uint p2x, uint p2y, uint p3x, uint p3y, bool check) view public returns (ParabolaCoefficients memory coefficients) {

        // Makes it a line if the points are are within 0.1% of each other;
        if((p3x * decimals.anchor)/p2x <= (1001*(decimals.anchor/1e3))) {
            return ParabolaCoefficients(0, p3y.mul(1e18)/p3x, false, false);
        }

        // Allows us to use the function for checking without reverting everything
        // For now this particular case we keep to a revert. In principle it should just snap out of line formula.
        if(p3x < p2x) {
            if(check) {
                return ParabolaCoefficients(42e25, 42e25, false, false);
            } else {
                revert("ZP: ExFlt0");
            }
        }


        // We pass a and b as 1e18s.
        // We use a bool flag to see if a is negative. B negative can happen sometimes, in that case the parabola becomes a line to p2
        // a can take values from approx. 1e19 to 0, so using encoding is ill-advised.

        uint aNumerator;

        //convert denominator to anchor decimals
        uint aPartial1 = p3y.mul(p2x); //1e18 * anchor
        uint aPartial2 = p3x.mul(p2y); //1e18 * anchor
        uint aDenominator = ((p3x.mul(p3x - p2x)/1e18) * decimals.anchor)/1e18; //convert to anchor form

        if(aPartial1 >= aPartial2) {
            // a is positive
            aNumerator = ((aPartial1 - aPartial2)/p2x);


            coefficients.a = aNumerator * decimals.anchor/aDenominator;

            // If b is positive
            if(p2y * 1e18/p2x >= (p2x * coefficients.a)/1e18) {
                coefficients.b = p2y * 1e18/p2x - (p2x * coefficients.a)/1e18;
                coefficients.bNegative = false;
            } else {
                // If b is negative we must construct a further piecewise definition upstream
                // Parabola becomes a line from 0 to p2, and then returns to its normal self.
                coefficients.b = (p2x * coefficients.a)/1e18 - p2y * 1e18/p2x; //1e18 * 1e18/1e18 - 1e18*1e18/1e18 = 1e18
                coefficients.bNegative = true;
            }

            coefficients.aNegative = false;

        } else {
            //a is negative
            aNumerator = ((aPartial2 - aPartial1)/p2x);

            coefficients.a = (aNumerator * decimals.anchor)/aDenominator;
            coefficients.b = (p2y * 1e18/p2x).add((p2x * coefficients.a)/1e18); //1e18 * 1e18/1e18 - 1e18*1e18/1e18 = 1e18

            coefficients.aNegative = true;
            coefficients.bNegative = false;

        }
    }

    function calculateP2(Decimals storage decimals, uint k, uint vab, uint vfb) view public returns (uint p2x, uint p2y) {
        p2y = ((k * 2)/vfb) - vab; // anchor decimals
        p2x = (p2y * decimals.priceMultiplier)/vfb;
    }

    function evaluateP2(Decimals storage decimals, uint x, uint adjustedVab, uint adjustedVfb, uint reserve0, uint reserve1, uint desiredFtv) view external returns (uint p2x, uint p2y) {

        uint p3x = (adjustedVab ** 2)/ reserve1;
        p3x = (p3x * decimals.priceMultiplier) / reserve0;

        if(x < p3x) {
            p2y = desiredFtv;
            p2x = x;
        } else {
            (p2x, p2y) = calculateP2(decimals, reserve0 * reserve1, adjustedVab, adjustedVfb);
        }
    }

    //         if x < (adjusted_vab ** 2)/k:
    //            self.p2y = adjusted_ftv
    //            self.p2x = reserve1/reserve0
    //
    //        else:
    //            # resets p2 to its default value
    //            self.p2y = (2 * k/adjusted_vfb) - adjusted_vab
    //            self.p2x = self.p2y/adjusted_vfb

    function calculateFtv(ParabolaCoefficients memory coefficients, uint x) pure public returns (uint ftv) {
        ftv = coefficients.aNegative
        ? ((coefficients.b * x).sub(((coefficients.a * x)/1e18) * x))/1e18
        : coefficients.bNegative
        ? ((((coefficients.a * x)/1e18) * x).sub(coefficients.b * x))/1e18
        : ((((coefficients.a * x)/1e18) * x).add(coefficients.b * x))/1e18;


    }
    function getFTVForX(Decimals storage decimals, uint _x, uint p2x, uint p2y, uint reserve0, uint reserve1, uint adjustedVab) view external returns (uint ftv, bool lineFormula, bool reduceOnly) {
        uint p3x = (adjustedVab ** 2) / reserve1;
        p3x = (p3x * decimals.priceMultiplier) / reserve0;


        if (_x >= p3x) {
            //x and reserves may not match, which is why we use this more general formula

            //adjustment for the sqrt so that it's in anchor units
            uint sqrt = (reserve0 * reserve1/decimals.float).mul(_x);
            sqrt = decimals.anchor > 1e18 ? sqrt * decimals.anchor/1e18 : sqrt / (1e18/decimals.anchor);

            ftv = (2 * Math.sqrt(sqrt)).sub(adjustedVab);
            reduceOnly = false;
            lineFormula = false;
        } else {

            lineFormula = true;

            ParabolaCoefficients memory coefficients = calculateParabolaCoefficients(
                decimals, p2x, p2y, p3x, adjustedVab, false
            ); //p3y is just adjustedVab

            uint x = _x;

            if(coefficients.bNegative && x <= p2x) {
                ftv = p2y.mul(x)/p2x; //straight line to p2
                return (ftv, true, false);
            }

            //Different conditions
            //a negative means parabola is pointing downwards (concave)
            //B can never be negative in this case
            //if a is positive, we differentiate for b being negative
            //b being negative means parabola can go below 0 for a while, which is no good.

            ftv = calculateFtv(coefficients, x);

            //If derivative is positive at p3x
            //B can only be negative when a is positive

            if(!coefficients.aNegative || coefficients.b > (2 * coefficients.a * p3x)/1e18) {
                reduceOnly = false;
            } else {
                //This means there is an excess of floats and the derivative becomes negative at some point before the juncture
                //At this point float liquidity can only be removed until this condition doesn't persist anymore.
                reduceOnly = true;
            }

        }
    }

    function checkDerivative(Decimals storage decimals, uint p2x, uint p2y, uint reserve0, uint reserve1, uint adjustedVab) view external returns (bool isNeg) {

        uint p3x = (adjustedVab ** 2)/ reserve1;
        p3x = (p3x * decimals.priceMultiplier) / reserve0;

        ParabolaCoefficients memory coefficients = calculateParabolaCoefficients(decimals, p2x, p2y, p3x, adjustedVab, true);

        if(coefficients.a == 42e25) {
            return true;
        }

        if(!coefficients.aNegative || coefficients.bNegative || coefficients.b > (2 * coefficients.a * p3x)/1e18) {
            return false;

        } else {
            return true;
        }

    }



}