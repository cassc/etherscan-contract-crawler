// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


abstract contract GeneScienceInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() public pure virtual returns (bool);

    /// @dev given genes of kitten 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public virtual returns (bytes32);

    function randomGenes(uint256 lastBlock) public virtual returns (bytes32);
    function mergeGens(bytes1[32] memory b) internal pure virtual returns (bytes32);

    function _parseBytes32(bytes32 gens, uint8 index) public pure virtual returns (bytes1 result);
}