// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISnxAddressResolver {
    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external;

    function rebuildCaches(address[] calldata destinations) external;

    function owner() external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function getAddress(bytes32 name) external view returns (address);
}