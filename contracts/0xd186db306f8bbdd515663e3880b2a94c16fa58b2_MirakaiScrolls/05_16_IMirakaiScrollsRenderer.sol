// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMirakaiScrollsRenderer {
    function render(uint256 tokenId, uint256 dna)
        external
        view
        returns (string memory);

    function tokenURI(uint256 tokenId, uint256 dna)
        external
        view
        returns (string memory);
}