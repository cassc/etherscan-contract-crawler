// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StringUtils.sol";

library Random {

    function randomIntStr(uint randomSeed, uint min, uint max) internal pure returns (string memory) {
        return StringUtils.uintToString(randomInt(randomSeed, min, max));
    }

    function randomInt(uint randomSeed, uint min, uint max) internal pure returns (uint) {
        if (max <= min) {
            return min;
        }

        uint seed = uint(keccak256(abi.encode(randomSeed)));
        return uint(seed % (max - min + 1)) + min;
    }

    function randomColour(uint randomSeed) internal pure returns (string memory) {
        return StringUtils.rgbString(randomInt(randomSeed, 0, 255), randomInt(randomSeed + 2, 0, 255), randomInt(randomSeed + 1, 0, 255));        
    }
}