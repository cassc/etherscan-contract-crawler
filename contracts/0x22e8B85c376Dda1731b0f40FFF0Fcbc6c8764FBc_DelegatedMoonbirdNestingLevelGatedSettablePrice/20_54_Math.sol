// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

library Math {
    /**
     * @notice Returns the largest integer less than or equal to the square root of a given integer.
     * @dev Uses the Babylonian method.
     * @dev Not optimised and should therefore only be used for testing.
     * TODO(arran): control this through Bazel visibility
     */
    function intSqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        if (x < 4) {
            return 1;
        }

        uint256 z = x;
        uint256 y = x / 2 + 1;
        while (y < z) {
            z = y;
            y = (x / y + y) / 2;
        }

        return z;
    }
}