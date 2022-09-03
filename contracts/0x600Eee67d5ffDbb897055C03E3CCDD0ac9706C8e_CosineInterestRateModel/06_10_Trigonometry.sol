// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@prb/math/contracts/PRBMathSD59x18.sol";

library Trigonometry {
    using SafeCast for uint256;
    using PRBMathSD59x18 for int256;

    /// @notice Value of pi as 18-digit decimal
    int256 internal constant PI = 3141592653589793280;

    /// @notice Default number of sine calculation iterations
    int256 internal constant DEFAULT_ITERATIONS = 20;

    /// @notice Computes the sin(x) to a certain number of Taylor series terms
    /// @param x Number to compute sine for
    /// @param iterations Number of computation iterations (more iterations - higher precision)
    /// @return sin(x)
    function sinLimited(int256 x, int256 iterations)
        internal
        pure
        returns (int256)
    {
        int256 num = x;
        int256 denom = 1;
        int256 result = num;
        for (int256 i = 0; i < iterations; i++) {
            num = num.mul(x).mul(x);
            denom *= (2 * i + 2) * (2 * i + 3);
            result +=
                num.div(PRBMathSD59x18.fromInt(denom)) *
                (i % 2 == 0 ? int256(-1) : int256(1));
        }
        return result;
    }

    /// @notice Computes sin(x) with a sensible maximum iteration count to wait until convergence.
    /// @notice x Number to compute sine for
    function sin(int256 x) internal pure returns (int256) {
        return sinLimited(x, DEFAULT_ITERATIONS);
    }

    /// @notice Computes cos(x)
    /// @notice x Number to compute cosine for
    function cos(int256 x) internal pure returns (int256) {
        return sin(x + PI / 2);
    }
}