// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

interface IMetroBlockScores {

    function getBlockScore(uint256 tokenId) external view returns (uint256 score);
}