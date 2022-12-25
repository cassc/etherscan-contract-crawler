// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface ISpaceEggz {

    
    function breedingBurn(uint256 id) external;
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getCurrentId() external view returns (uint256);
}