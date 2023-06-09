// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";

library IntArrayLib {
    using SafeCast for int256;
    using SafeCast for uint256;

    /**
     * @dev returns min value of aray x
     */
    function min(int256[] memory x) internal pure returns (int256 m) {
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
     * @dev Returns maximal element in array
     */
    function max(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i = 1; i < x.length;) {
            if (x[i] > m) {
                m = x[i];
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev returns min value of aray x and its index
     */
    function minWithIndex(int256[] memory x) internal pure returns (int256 m, uint256 idx) {
        m = x[0];
        idx = 0;
        for (uint256 i = 1; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
                idx = i;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns maximal elements compared to value z
     * @return y array
     */
    function maximum(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            if (x[i] > z) y[i] = x[i];
            else y[i] = z;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return a new array that removes element at index z.
     * @return y new array
     */
    function remove(int256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        if (z >= x.length) return x;
        y = new int256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            unchecked {
                if (i < z) y[i] = x[i];
                else if (i > z) y[i - 1] = x[i];
                ++i;
            }
        }
    }

    /**
     * @dev Returns index of element
     * @return found
     * @return index
     */
    function indexOf(int256[] memory x, int256 v) internal pure returns (bool, uint256) {
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
     */
    function sum(int256[] memory x) internal pure returns (int256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return a new array which is sorted by indexes array
     * @param x original array
     * @param idxs indexes to sort based on.
     */
    function sortByIndexes(int256[] memory x, uint256[] memory idxs) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[idxs[i]];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return a new array that append element v at the end of array x
     */
    function append(int256[] memory x, int256 v) internal pure returns (int256[] memory y) {
        y = new int256[](x.length + 1);
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
     * @dev return a new array that's the result of concatting a and b
     */
    function concat(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length + b.length);
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
     * @dev Fills array x with value v in place.
     */
    function fill(int256[] memory x, int256 v) internal pure {
        for (uint256 i; i < x.length;) {
            x[i] = v;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
     */
    function populate(int256[] memory a, int256[] memory b) internal pure {
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
    function at(int256[] memory x, int256 i) internal pure returns (int256) {
        if (i >= 0) {
            // will revert with out of bound error if i is too large
            return x[uint256(i)];
        } else {
            // will revert with underflow error if i is too small
            return x[x.length - uint256(-i)];
        }
    }

    /**
     * @dev return a new array contains the copy from x[start] to x[end]
     *      if i is positive, it's the same as requesting x[i]
     *      if i is negative, return the value positioned at -i from the end
     * @param x array to copy
     * @param _start starting index, can be negative
     * @param _start ending index, can be negative
     */
    function slice(int256[] memory x, int256 _start, int256 _end) internal pure returns (int256[] memory a) {
        int256 len = int256(x.length);
        if (_start < 0) _start = len + _start;
        if (_end <= 0) _end = len + _end;
        if (_end < _start) return new int256[](0);

        uint256 start = uint256(_start);
        uint256 end = uint256(_end);

        a = new int256[](end - start);
        uint256 y;
        for (uint256 i = start; i < end;) {
            a[y] = x[i];

            unchecked {
                ++i;
                ++y;
            }
        }
    }

    /**
     * @dev return an array y as the sum of 2 same-length array
     *      y[i] = a[i] + b[i]
     */
    function add(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length);
        for (uint256 i; i < a.length;) {
            y[i] = a[i] + b[i];

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev return an new array y with y[i] = x[i] + z
     */
    function addEachBy(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] + z;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return a new array y with y[i] = x[i] - z
     */
    function subEachBy(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = x[i] - z;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev return dot of 2 vectors
     *      will revert if 2 vectors have different length
     */
    function dot(int256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i; i < a.length;) {
            s += a[i] * b[i];

            unchecked {
                ++i;
            }
        }
    }
}