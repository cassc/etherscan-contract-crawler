// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IOniiChainDescriptor {
    function tokenURI(uint256 tokenId, address owner)
        external
        view
        returns (string memory);

    function getSVG(uint256 tokenId) external view returns (string memory);
}