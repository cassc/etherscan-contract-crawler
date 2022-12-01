// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersion {
    function version() external view returns(uint8,uint8,uint16);
}