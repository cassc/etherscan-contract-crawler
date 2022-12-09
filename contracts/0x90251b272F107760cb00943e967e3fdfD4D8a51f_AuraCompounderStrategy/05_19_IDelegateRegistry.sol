// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;

    function delegation(address, bytes32) external view returns (address);
}