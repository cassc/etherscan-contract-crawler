//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMirakaiHeroesRenderer {
    function tokenURI(uint256 _tokenId, uint256 dna)
        external
        view
        returns (string memory);
}