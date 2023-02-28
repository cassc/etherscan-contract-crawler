// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}