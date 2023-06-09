// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IKondux {
    function changeDenominator(uint96 _denominator) external returns (uint96);
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;
    function setBaseURI(string memory _newURI) external returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function pause() external;
    function unpause() external;
    function safeMint(address to, uint256 dna) external returns (uint256);
    function setDna(uint256 _tokenID, uint256 _dna) external;
    function getDna(uint256 _tokenID) external view returns (uint256);
    function readGen(uint256 _tokenID, uint8 startIndex, uint8 endIndex) external view returns (int256);
    function writeGen(uint256 _tokenID, uint256 inputValue, uint8 startIndex, uint8 endIndex) external;
    function getTransferDate(uint256 _tokenID) external view returns (uint256);
}