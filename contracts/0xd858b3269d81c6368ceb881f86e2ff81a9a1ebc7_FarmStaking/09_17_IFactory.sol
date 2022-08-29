// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFactory {
    function mintDamo(address to,uint8 damoType,uint8 genera,uint8 numbers,uint8 source) external returns(uint256[] memory);
    function tokenDetail(uint8 damoType,uint256 tokenId)   external view returns (uint8,uint8,string memory) ;
    function batchMintDamo(uint8 damoType,address[] memory tos,uint256[] memory tokenIds,uint8[] memory gens) external returns(uint256[] memory);
}