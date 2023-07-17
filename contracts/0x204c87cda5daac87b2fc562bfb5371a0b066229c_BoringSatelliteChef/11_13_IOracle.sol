// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IOracle {
    
    function setPrice(bytes32 _symbol, uint _price) external;
    function getPrice(bytes32 _symbol) external view returns (uint);
}