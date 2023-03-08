// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBanditsRenderer {
    function hashToSVG(string memory _hash) external view returns (string memory);
    function hashToSVG(string memory _hash, uint tokenId) external view returns (string memory);
    function hashToMetadata(string memory _hash) external view returns (string memory);
}