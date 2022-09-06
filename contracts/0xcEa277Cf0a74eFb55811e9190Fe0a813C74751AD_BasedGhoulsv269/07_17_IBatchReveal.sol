//SPDX-License-Identifier: CC0
pragma solidity ^0.8.13;

interface IBatchReveal {
    struct Range {
        int128 start;
        int128 end;
    }

    function getShuffledTokenId(uint startId) view external returns (uint);

    function setBatchSeed(uint randomness) external;

    function setLastTokenRevealed(uint _index) external;
}