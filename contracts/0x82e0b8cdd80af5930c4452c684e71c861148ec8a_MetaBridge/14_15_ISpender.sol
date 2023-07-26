pragma solidity ^0.8.0;


interface ISpender {
    function bridge(address adapterAddress, bytes calldata data) external payable;
}