//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library SignedMathLib {
    int256 public constant WAD = 1e18;

    /**
     * @dev Returns the signum function of the specified int value.
     * @return -1 if the specified value is negative; 0 if the specified value is zero; and 1 if the specified value is positive
     */
    function signum(int256 x) internal pure returns (int256) {
        unchecked {
            return x > 0 ? int256(1) : x < 0 ? -1 : int256(0);
        }
    }

    /**
     * @return c the division of two signed numbers rounding UP (round away from zero)
     *
     * This differs from standard division with `/` that rounds DOWN (towards 0).
     */
    function divUp(int256 a, int256 b) internal pure returns (int256 c) {
        unchecked {
            c = a / b;
            if (a % b != 0) {
                c += c == 0 ? int256(1) : signum(c);
            }
        }
    }

    /// @dev Returns the absolute signed value of a signed value.
    function absi(int256 n) internal pure returns (int256) {
        return n >= 0 ? n : -n;
    }

    function mulWadDown(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        unchecked {
            c /= WAD;
        }
    }

    function divWadDown(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * WAD;
        unchecked {
            c /= b;
        }
    }

    function mulWadUp(int256 a, int256 b) internal pure returns (int256) {
        return divUp(a * b, WAD);
    }

    function divWadUp(int256 a, int256 b) internal pure returns (int256) {
        return divUp(a * WAD, b);
    }
}