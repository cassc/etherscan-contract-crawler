//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title Math
    @author iMe Lab

    @notice Maths library. Generally, for financial computations.
 */
library Math {
    /**
        @notice Yields integer exponent of fixed-point number

        @dev Implementation of Exponintiation by squaring algorightm.
        Highly inspired by PRBMath library. Uses x33 precision instead
        of x18 in order to make financial computations more accurate.

        @param x Exponent base, 33x33 fixed number close to 1.0
        @param y Exponentiation parameter, integer
     */
    function powerX33(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 power) {
        unchecked {
            power = y & 1 > 0 ? x : 1e33;

            for (y >>= 1; y > 0; y >>= 1) {
                x = (x * x) / 1e33;
                if (y & 1 > 0) power = (power * x) / 1e33;
            }
        }
    }

    /**
        @notice Round x18 fixed number to an integer
     */
    function fromX18(uint256 fixedX18) internal pure returns (uint256 round) {
        unchecked {
            round = fixedX18 / 1e18;
            if (fixedX18 % 1e18 > 5e17) round += 1;
        }
    }
}