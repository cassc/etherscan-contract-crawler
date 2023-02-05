// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "lib/array-lib/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

library UintArrayLib {
    using SafeCast for uint256;

    /**
     * @dev Returns maximal element in array
     */
    function max(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] > m) {
                m = x[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns minimum element in array
     */
    function min(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i = 1; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return the min and max for an array.
     */
    function minMax(uint256[] memory x) internal pure returns (uint256 min_, uint256 max_) {
        if (x.length == 1) return (x[0], x[0]);
        (min_, max_) = (x[0], x[0]);

        for (uint256 i = 1; i < x.length;) {
            if (x[i] < min_) {
                min_ = x[i];
            } else if (x[i] > max_) {
                max_ = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return a new array that append element v at the end of array x
     */
    function append(uint256[] memory x, uint256 v) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];

            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    /**
     * @dev Return a new array that removes element at index z.
     * @return y new array
     */
    function remove(uint256[] memory x, uint256 z) internal pure returns (uint256[] memory y) {
        if (z >= x.length) return x;
        y = new uint256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            unchecked {
                if (i < z) y[i] = x[i];
                else if (i > z) y[i - 1] = x[i];
                ++i;
            }
        }
    }

    /**
     * @dev Return index of the first element in array x with value v
     * @return found set to true if found
     * @return i index in the array
     */
    function indexOf(uint256[] memory x, uint256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }

            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    /**
     * @dev Compute sum of all elements
     * @return s sum
     */
    function sum(uint256[] memory x) internal pure returns (uint256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return a new array that's the result of concatting a and b
     */
    function concat(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory y) {
        y = new uint256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];

            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];

            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /**
     * @dev Populates array a with values from b
     * @dev modifies array a in place.
     */
    function populate(uint256[] memory a, uint256[] memory b) internal pure {
        for (uint256 i; i < a.length;) {
            a[i] = b[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return the element at index i
     *      if i is positive, it's the same as requesting x[i]
     *      if i is negative, return the value positioned at -i from the end
     * @param i can be positive or negative
     */
    function at(uint256[] memory x, int256 i) internal pure returns (uint256) {
        if (i >= 0) {
            // will revert with out of bound error if i is too large
            return x[uint256(i)];
        } else {
            // will revert with underflow error if i is too small
            return x[x.length - uint256(-i)];
        }
    }

    /**
     * @dev return a new array y with y[i] = z - x[i]
     */
    function subEachFrom(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        int256 intZ = z.toInt256();
        for (uint256 i; i < x.length;) {
            y[i] = intZ - x[i].toInt256();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return a new array y with y[i] = x[i] - z
     */
    function subEachBy(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        int256 intZ = z.toInt256();
        for (uint256 i; i < x.length;) {
            y[i] = x[i].toInt256() - intZ;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return dot of 2 vectors
     *      will revert if 2 vectors has different length
     * @param a uint256 array
     * @param b uint256 array
     */
    function dot(uint256[] memory a, uint256[] memory b) internal pure returns (uint256 s) {
        for (uint256 i; i < a.length;) {
            s += a[i] * b[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return dot of 2 vectors
     *      will revert if 2 vectors has different length
     * @param a uint256 array
     * @param b int256 array
     */
    function dot(uint256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i; i < a.length;) {
            s += int256(a[i]) * b[i];

            unchecked {
                ++i;
            }
        }
    }
}