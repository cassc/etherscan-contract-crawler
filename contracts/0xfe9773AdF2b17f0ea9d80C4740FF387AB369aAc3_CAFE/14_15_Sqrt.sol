pragma solidity ^0.8.0;

/**
 * @title Calculates the square root of a given value.
 * @dev Results may be off by 1.
 */
library Sqrt {
    // Source: https://github.com/ethereum/dapp-bin/pull/50
    function sqrt(uint x) internal pure returns (uint y) {
        if (x == 0) {
            return 0;
        } else if (x <= 3) {
            return 1;
        } else if (x == type(uint256).max) {
            // Without this we fail on x + 1 below
            return 2**128 - 1;
        }

        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}