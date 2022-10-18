// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RandSelect {

    function selectN(uint8 [] memory src, uint8 n, address sender, uint256 randNumber) internal view returns (bool res, uint8 [] memory dest) {
        if(src.length >= n) {
            dest = new uint8[](n);
            uint8[] memory temp = new uint8[](src.length);
            temp = src;
            uint8 i = 0;
            do {
                (uint8 selected, uint8 index) = _randomPosition(temp, uint8(src.length-i), sender, randNumber);
                dest[i] = selected;
                for(uint8 j = index; j < src.length-i-1; ++j) {
                    temp[j] = temp[j+1]; 
                }
                
                ++i;
            } while (i < n);

            res = true;
        }
    }

    function isDulplicated(uint8 [] memory arr) internal pure returns (bool) {
        for(uint8 i = 0; i < arr.length-1; ++i) {
            for(uint8 j = i+1; j < arr.length; ++j) {
                if(arr[i] == arr[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _randomPosition(
        uint8[] memory arr,
        uint8 len,
        address sender,
        uint256 randNumber
    ) internal view returns (uint8 res, uint8 index) {
        uint256 randomSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    sender,
                    randNumber,
                    len
                )
            )
        );
        uint8 min = 0;
        uint8 max = len - 1;
        uint256 _index = (randomSeed % (max - min + 1)) + min;
        res = arr[_index];
        index = uint8(_index);
    }
}