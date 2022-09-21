// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IDNAChip {
    function tokenIdToTraits(uint256 tokenId) external view returns (uint256);

    function getTraitsArray(uint256 _tokenId) external view returns (uint8[8] memory);

    function isEvolutionPod(uint256 tokenId) external view returns (bool);

    function breedingIdToEvolutionPod(uint256 tokenId) external view returns (uint256);
}