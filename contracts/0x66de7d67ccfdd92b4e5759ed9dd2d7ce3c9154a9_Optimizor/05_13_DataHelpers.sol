// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

function packTokenId(uint256 challengeId, uint32 solutionId) pure returns (uint256) {
    return (challengeId << 32) | solutionId;
}

function unpackTokenId(uint256 tokenId) pure returns (uint256 challengeId, uint32 solutionId) {
    challengeId = tokenId >> 32;
    solutionId = uint32(tokenId);
}