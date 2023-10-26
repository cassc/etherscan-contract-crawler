// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath32 {
    function safe32(uint a, string memory errorMessage) internal pure returns (uint32 c) {
        require(a <= 2**32, errorMessage);// "SafeMath: exceeds 32 bits"
        c = uint32(a);
    }
}