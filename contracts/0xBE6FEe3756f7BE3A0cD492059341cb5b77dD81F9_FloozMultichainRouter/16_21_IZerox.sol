pragma solidity ^0.6.5;

interface IZerox {
    function getFunctionImplementation(bytes4 selector) external returns (address payable);
}