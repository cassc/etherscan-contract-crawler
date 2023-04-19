// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library StringHelper {
    function toHash(string memory _s) internal pure returns (bytes32) {
        return keccak256(abi.encode(_s));
    }

    function isEmpty(string memory _s) internal pure returns (bool) {
        return length(_s) == 0;
    }

    function length(string memory _s) internal pure returns (uint256) {
        return bytes(_s).length;
    }
}