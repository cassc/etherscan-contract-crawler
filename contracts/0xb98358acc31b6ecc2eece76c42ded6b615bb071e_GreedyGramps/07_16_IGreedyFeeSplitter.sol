pragma solidity ^0.8.6;

interface IGreedyFeeSplitter {
    function logSale(uint256 salePrice, uint256 tokenId, address sender) external;
}