// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelotNFT {        
    function totalSupply() external view returns (uint256);
    function numberOfHolders() external view returns (uint256);
    function getHolderAt(uint256 index) external view returns (address);    
}