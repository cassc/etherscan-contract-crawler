// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMintableCollection {
    function safeMint(address to, uint256 tokenId) external;
}