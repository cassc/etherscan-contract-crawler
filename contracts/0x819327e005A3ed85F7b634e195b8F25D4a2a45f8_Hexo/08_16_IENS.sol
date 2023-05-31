// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IENS {
    function setOwner(bytes32 _node, address _owner) external;

    function setResolver(bytes32 _node, address _resolver) external;

    function setSubnodeRecord(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external;

    function setSubnodeOwner(
        bytes32 _node,
        bytes32 _label,
        address _owner
    ) external returns (bytes32);

    function owner(bytes32 _node) external view returns (address);

    function resolver(bytes32 _node) external view returns (address);
}