// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IProxy {
    function getImplementationAddress() external view returns (address);
}