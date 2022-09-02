pragma solidity ^0.8.0;

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}