// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Reference: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code
interface IKittyCore {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function transfer(address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getKitty(uint256 id) external view returns (bool,bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function kittyIndexToApproved(uint256 id) external view returns (address);
}