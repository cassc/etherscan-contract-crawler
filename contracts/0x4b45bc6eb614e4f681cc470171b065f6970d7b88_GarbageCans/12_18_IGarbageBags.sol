// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGarbageBags { 
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burnBatch(uint256[] calldata tokenIds) external;
}