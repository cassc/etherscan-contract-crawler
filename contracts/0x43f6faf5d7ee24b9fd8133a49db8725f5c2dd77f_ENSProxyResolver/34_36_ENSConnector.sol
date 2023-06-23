// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";

contract ENSConnector {
    ENSRegistry ens;

    mapping(bytes32 => bytes32) public bridges;
    mapping(bytes32 => address) public ownerOf;
    event NewBridge(bytes32 indexed bridge, bytes32 externalNode, address indexed owner, address resolver);
    event BridgeDestroyed(bytes32 indexed bridge);

    constructor(ENSRegistry _ens) {
        ens = _ens;
    }

    /**
     * @dev Creates a bridge from ENS to other naming systems.
     * Note: this contract must be authorized to manage the ENS node.
     *
     * @param bridge The ENS node e.g. namehash("forever.eth").
     * @param externalNode The external node to connect to e.g. namehash("forever").
     * @param owner The address authorised to create sub nodes.
     * @param resolver The resolver to use for the bridge.
     */
    function create(bytes32 bridge, bytes32 externalNode, address owner, address resolver) external {
        require(ens.owner(bridge) == msg.sender, "Must own ENS node");

        // Will fail if this contract is not authorized to manage the bridge
        ens.setRecord(bridge, address(this), resolver, 0);

        bridges[bridge] = externalNode;
        ownerOf[bridge] = owner;
        emit NewBridge(bridge, externalNode, owner, resolver);
    }

    // Destroys a bridge if this contract is no longer the owner.
    function destroy(bytes32 bridge) external {
        require(ens.owner(bridge) != address(this), "No bridge exists");

        bridges[bridge] = bytes32(0);
        ownerOf[bridge] = address(0);
        emit BridgeDestroyed(bridge);
    }

    function setSubnodeOwner(bytes32 bridge, bytes32 label, address owner) external {
        require(ownerOf[bridge] == msg.sender, "Must be owner of bridge");
        ens.setSubnodeOwner(bridge, label, owner);
    }

    function setSubnodeRecord(bytes32 bridge, bytes32 label, address owner, address resolver, uint64 ttl) external {
        require(ownerOf[bridge] == msg.sender, "Must be owner of bridge");
        ens.setSubnodeRecord(bridge, label, owner, resolver, ttl);
    }

    function setResolver(bytes32 bridge, address resolver) external {
        require(ownerOf[bridge] == msg.sender, "Must be owner of bridge");
        ens.setResolver(bridge, resolver);
    }
}