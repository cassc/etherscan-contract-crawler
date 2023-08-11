// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IENSRegistry {
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);

    function setOwner(bytes32 node, address owner) external;

    function owner(bytes32 node) external view returns (address);

    function recordExists(bytes32 node) external view returns (bool);
}