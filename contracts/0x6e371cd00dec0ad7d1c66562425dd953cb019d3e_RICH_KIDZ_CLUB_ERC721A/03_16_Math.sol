pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


library Math {
    function unsafeInc(uint256 x) internal pure returns(uint256) {
        unchecked {
            return x + 1;
        }
    }
}