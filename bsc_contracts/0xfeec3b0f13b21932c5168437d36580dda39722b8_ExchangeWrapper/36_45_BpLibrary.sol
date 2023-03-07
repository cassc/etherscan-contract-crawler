// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library BpLibrary {
    function bp(uint256 value, uint256 bpValue) internal pure returns (uint256) {
        return (value * (bpValue)) / (10000);
    }
}