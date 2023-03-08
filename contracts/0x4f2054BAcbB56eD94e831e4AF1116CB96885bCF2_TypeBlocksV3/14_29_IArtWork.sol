// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IArtWork {
    function generateArt(bytes1[] memory letters, string memory color) external pure returns (bytes memory);
}