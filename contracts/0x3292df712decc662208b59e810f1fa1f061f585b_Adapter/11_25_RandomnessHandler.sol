// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RandomnessHandler {
    function _shuffle(uint256 upper, uint256 randomness) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](upper);
        for (uint256 k = 0; k < upper; k++) {
            arr[k] = k;
        }
        uint256 i = arr.length;
        uint256 j;
        uint256 t;

        while (--i > 0) {
            j = randomness % i;
            randomness = uint256(keccak256(abi.encode(randomness)));
            t = arr[i];
            arr[i] = arr[j];
            arr[j] = t;
        }

        return arr;
    }
}