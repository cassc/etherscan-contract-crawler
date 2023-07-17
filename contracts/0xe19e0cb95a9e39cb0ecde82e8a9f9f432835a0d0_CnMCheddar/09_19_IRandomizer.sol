// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function commitId() external view returns (uint16);
    function getCommitRandom(uint16 id) external view returns (uint256);
    function random() external returns (uint256);
    function sRandom(uint256 tokenId) external returns (uint256);
}