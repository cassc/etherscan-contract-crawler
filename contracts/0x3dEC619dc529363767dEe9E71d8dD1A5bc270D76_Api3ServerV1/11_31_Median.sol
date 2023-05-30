// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Sort.sol";
import "./QuickSelect.sol";

/// @title Contract to be inherited by contracts that will calculate the median
/// of an array
/// @notice The operation will be in-place, i.e., the array provided as the
/// argument will be modified.
contract Median is Sort, Quickselect {
    /// @notice Returns the median of the array
    /// @dev Uses an unrolled sorting implementation for shorter arrays and
    /// quickselect for longer arrays for gas cost efficiency
    /// @param array Array whose median is to be calculated
    /// @return Median of the array
    function median(int256[] memory array) internal pure returns (int256) {
        uint256 arrayLength = array.length;
        if (arrayLength <= MAX_SORT_LENGTH) {
            sort(array);
            if (arrayLength % 2 == 1) {
                return array[arrayLength / 2];
            } else {
                assert(arrayLength != 0);
                unchecked {
                    return
                        average(
                            array[arrayLength / 2 - 1],
                            array[arrayLength / 2]
                        );
                }
            }
        } else {
            if (arrayLength % 2 == 1) {
                return array[quickselectK(array, arrayLength / 2)];
            } else {
                uint256 mid1;
                uint256 mid2;
                unchecked {
                    (mid1, mid2) = quickselectKPlusOne(
                        array,
                        arrayLength / 2 - 1
                    );
                }
                return average(array[mid1], array[mid2]);
            }
        }
    }

    /// @notice Averages two signed integers without overflowing
    /// @param x Integer x
    /// @param y Integer y
    /// @return Average of integers x and y
    function average(int256 x, int256 y) private pure returns (int256) {
        unchecked {
            int256 averageRoundedDownToNegativeInfinity = (x >> 1) +
                (y >> 1) +
                (x & y & 1);
            // If the average rounded down to negative infinity is negative
            // (i.e., its 256th sign bit is set), and one of (x, y) is even and
            // the other one is odd (i.e., the 1st bit of their xor is set),
            // add 1 to round the average down to zero instead.
            // We will typecast the signed integer to unsigned to logical-shift
            // int256(uint256(signedInt)) >> 255 ~= signedInt >>> 255
            return
                averageRoundedDownToNegativeInfinity +
                (int256(
                    (uint256(averageRoundedDownToNegativeInfinity) >> 255)
                ) & (x ^ y));
        }
    }
}