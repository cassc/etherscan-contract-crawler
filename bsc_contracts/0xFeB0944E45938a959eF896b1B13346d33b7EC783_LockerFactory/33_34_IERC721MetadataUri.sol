//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface IERC721MetadataUri {
     function tokenURI(uint256 tokenId) external view returns (string memory);
}