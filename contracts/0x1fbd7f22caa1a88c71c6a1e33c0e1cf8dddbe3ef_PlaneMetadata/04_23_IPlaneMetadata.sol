// File: contracts/IPlaneMetadata.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPlaneMetadata {

    function setRevealed(bool revealed) external;
    function genMetadata(string memory tokenSeed, uint256 tokenId) external view returns (string memory);

}