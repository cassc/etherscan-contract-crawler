// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/* @title ArtGenerator
 * @author minimizer <[email protected]>; https://minimizer.art/
 * 
 * For Infininte Scribble, this is the interface between the minting contract and the artwork code.
 * Apart from name() and symbol() for ERC721Metadata, it provides tokenURI() which is passed all the data
 * needed to generate a given piece.
 */

interface ArtGenerator {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId, bytes32 hash, uint8 widthRatio, uint8 heightRatio) external view returns (string memory);
    
}