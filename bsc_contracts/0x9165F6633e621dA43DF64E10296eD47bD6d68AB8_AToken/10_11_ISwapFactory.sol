pragma solidity ^0.8.4;

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}