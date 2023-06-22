// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

library MathUtils {
    using SafeMath for uint256;

    /// @notice Calculates the square root of a given value.
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }

    /// @notice Rounds a division result.
    function roundedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'div by 0');

        uint256 halfB = (b.mod(2) == 0) ? (b.div(2)) : (b.div(2).add(1));
        return (a.mod(b) >= halfB) ? (a.div(b).add(1)) : (a.div(b));
    }
}