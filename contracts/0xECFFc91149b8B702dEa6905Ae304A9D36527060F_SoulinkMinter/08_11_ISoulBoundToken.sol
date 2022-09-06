// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface ISoulBoundToken is IERC165, IERC721Metadata {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}