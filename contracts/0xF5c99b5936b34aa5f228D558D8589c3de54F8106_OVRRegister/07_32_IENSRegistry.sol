pragma solidity ^0.8.14;

/**
 * @title EnsRegistry
 * @dev Extract of the interface for ENS Registry
*/
interface IENSRegistry {
    function setOwner(bytes32 node, address owner) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
}