// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenVaultAuction {    
    event AuctionSettings(address indexed from, bytes settings);    
    function auctioning() external view returns (bool);
    function getPrice() external view returns (uint256);
    function getAuctionSettings() external view returns (bytes memory);
    function getAuctionType() external pure returns (bytes4);
    function setAuctionSettings(bytes calldata) external;
}