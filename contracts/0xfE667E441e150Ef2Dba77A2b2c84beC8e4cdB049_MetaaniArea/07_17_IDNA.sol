// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDNA{
    //
    function balanceOf(address owner) external view returns (uint256 balance);

    //
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    
}