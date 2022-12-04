// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRenderModule {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}