// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library Strings {
    function toBytes32(string memory a) internal pure returns (bytes32) {
        bytes32 b;
        assembly {
            b := mload(add(a, 32))
        }
        return b;
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function concat(
        string memory a,
        string memory b,
        bytes32 c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
}