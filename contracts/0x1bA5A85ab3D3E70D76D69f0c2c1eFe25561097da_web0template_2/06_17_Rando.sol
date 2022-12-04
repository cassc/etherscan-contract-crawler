// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Rando {

    function number(string memory seed, uint min, uint max) internal pure returns (uint) {
      if (max <= min) return min;
        return (uint256(keccak256(abi.encodePacked(seed))) % (max - min)) + min;
    }

}