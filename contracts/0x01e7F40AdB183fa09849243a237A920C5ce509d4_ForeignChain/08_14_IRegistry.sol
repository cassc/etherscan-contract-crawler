//SPDX-License-Identifier: MIT
pragma solidity 0.6.8;


interface IRegistry {
    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name) external view returns (address);
}