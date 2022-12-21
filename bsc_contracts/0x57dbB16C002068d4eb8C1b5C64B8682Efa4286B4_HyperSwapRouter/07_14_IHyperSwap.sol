// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IHyperSwap {
    function getFunctionImplementation(bytes4 _signature) external returns (address);
}