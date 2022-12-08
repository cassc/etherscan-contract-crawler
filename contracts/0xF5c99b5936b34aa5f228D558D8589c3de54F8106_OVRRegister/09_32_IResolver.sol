pragma solidity ^0.8.14;

/**
 * @title EnsRegistry
 * @dev Extract of the interface for ENS Registry
 */
interface IResolver {
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setContenthash(bytes32 node, bytes calldata hash) external;

    function contenthash(bytes32 node) external view returns (bytes memory);
}