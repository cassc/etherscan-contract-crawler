// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminon {
    function GEX() external view returns(address);
    function oracleGeminon() external view returns(address);
}