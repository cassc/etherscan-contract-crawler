// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

// pared down version of import @ensdomains/ens-contracts/contracts/registry/ENS.sol

interface IENS {
    function setRecord(
        bytes32 node,
        address _owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address _owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address _owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address _owner) external;

    function owner(bytes32 node) external view returns (address);
}