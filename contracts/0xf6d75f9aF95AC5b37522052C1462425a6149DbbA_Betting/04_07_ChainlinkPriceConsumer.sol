pragma solidity ^0.6.0;

interface ChainlinkPriceConsumer {
    function getLatestPrice() external view returns (int);
    function getDecimals() external view returns (uint8);
}