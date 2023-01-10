// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

function getRandomInRange(
    uint min,
    uint max,
    uint nonce
) view returns (uint) {
    uint rand = _rand(nonce);
    uint range = max - min + 1;
    return (rand % range) + min;
}

function _rand(uint nonce) view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, nonce)));
}