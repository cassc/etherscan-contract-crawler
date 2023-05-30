// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;


/**
 * @title IMillionPieces
 */
interface IMillionPieces {
    function mintTo(address to, uint256 tokenId) external;
    function mintToSpecial(address to, uint256 tokenId) external;
    function createArtwork(string calldata name) external;
    function setTokenURI(uint256 tokenId, string calldata uri) external;
    function setBaseURI(string calldata baseURI) external;
    function exists(uint256 tokenId) external view returns (bool);
    function isSpecialSegment(uint256 tokenId) external pure returns (bool);
    function isValidArtworkSegment(uint256 tokenId) external view returns (bool);
    function getArtworkName(uint256 id) external view returns (string memory);
}