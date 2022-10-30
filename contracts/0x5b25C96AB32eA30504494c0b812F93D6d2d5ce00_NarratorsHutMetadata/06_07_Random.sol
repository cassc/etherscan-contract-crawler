//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Random {
    function randomFromSeed(string memory seed)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seed)));
    }
}