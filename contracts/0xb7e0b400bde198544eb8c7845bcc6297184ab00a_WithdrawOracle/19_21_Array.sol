// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

library Array {
    // @notice compareBytes32Arrays gas < compareBytes32ArraysByLoop gas
    // ----------------------------------------------------------------
    // gas test
    // arrCount   compareBytes32Arrays    compareBytes32ArraysByLoop
    // 10         4777                    4986
    // 100        34619                   40438
    // 1000       360883                  401922
    function compareBytes32Arrays(bytes32[] memory arr1, bytes32[] memory arr2) public pure returns (bool) {
        if (arr1.length != arr2.length) {
            return false;
        }

        bytes32 hash1 = keccak256(abi.encodePacked(arr1));
        bytes32 hash2 = keccak256(abi.encodePacked(arr2));

        return hash1 == hash2;
    }

    function compareBytes32ArraysByLoop(bytes32[] memory arr1, bytes32[] memory arr2) public pure returns (bool) {
        if (arr1.length != arr2.length) {
            return false;
        }

        for (uint256 i = 0; i < arr1.length; i++) {
            if (arr1[i] != arr2[i]) {
                return false;
            }
        }

        return true;
    }
}