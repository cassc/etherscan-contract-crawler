pragma solidity ^0.6.12;

// File: contracts/uniswapv2/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}