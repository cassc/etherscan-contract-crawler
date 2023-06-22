// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

// Optimized sqrt library originally based on code from Uniswap v2
library Sqrt {
    // y is the number to sqrt
    // x MUST BE > int(sqrt(y)). This is NOT CHECKED.
    function sqrt(uint256 y, uint256 x) internal pure returns (uint256) {
        unchecked {
            uint256 z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
            return z;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256) {
        unchecked {
            uint256 x = y / 6e17;
            if(y <= 37e34){
                x = y/2 +1;
            }
            return sqrt(y,x); 
        }
    }
}