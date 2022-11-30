// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; 

interface IETHRegistrarController { 
    function available(string calldata name) external view returns(bool);
    function rentPrice(string calldata name, uint duration) external view returns(uint);
    function makeCommitment(string calldata name, address owner, bytes32 secret) pure external returns(bytes32);
    function makeCommitmentWithConfig(string calldata name, address owner, bytes32 secret, address resolver, address addr) pure external returns(bytes32);
    function commit(bytes32 commitment) external;
    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable;
    function registerWithConfig(string calldata name, address owner, uint duration, bytes32 secret, address resolver, address addr) external payable;
    function renew(string calldata name, uint duration) external payable;
}