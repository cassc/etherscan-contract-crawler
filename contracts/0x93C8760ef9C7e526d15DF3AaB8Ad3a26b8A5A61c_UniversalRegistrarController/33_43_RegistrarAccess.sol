// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../root/Root.sol";

contract RegistrarAccess {
    event NodeOwnerChanged(bytes32 node, address indexed oldOwner, address indexed newOwner);
    event RegistryControllersChanged(address indexed controller, bool approved);
    event RegistryNodeControllersChanged(bytes32 node, address indexed controller, bool approved);

    Root public root;

    constructor(Root _root) {
        root = _root;
    }

    // A map of top level domains and their authorised owner
    mapping(bytes32 => address) private nodeOwners;

    // A map specifying which controller addresses TLD owners are allowed to use.
    mapping(address => bool) private registryControllers;

    // A map specifying which controller addresses a specific TLD owner is allowed to use.
    mapping(bytes32 => mapping(address => bool)) private registryNodeControllers;

    modifier onlyNodeOwner(bytes32 node) {
        require(nodeOwners[node] == msg.sender);
        _;
    }

    modifier onlyRegistry {
        require(root.controllers(msg.sender), "Sender not Controller!");
        _;
    }

    modifier onlyRegistryControllers(bytes32 node, address controller) {
        require(registryNodeControllers[node][controller] ||
            registryControllers[controller], "controller not approved by registry");
        _;
    }

    // Transfers ownership of a TLD to a new owner
    // can only be called by existing node owner.
    function transferNodeOwnership(bytes32 node, address newOwner) public onlyNodeOwner(node) {
        require(newOwner != address(0));
        emit NodeOwnerChanged(node, nodeOwners[node], newOwner);
        nodeOwners[node] = newOwner;
    }

    // Gives up ownership of a TLD to a burn address. All functionality marked with onlyNodeOwner
    // will be disabled for the specified TLD. It will also affect any contracts
    // that rely on {ownerOfNode}. Use with extreme caution.
    function renounceNodeOwnership(bytes32 node) public onlyNodeOwner(node) {
        emit NodeOwnerChanged(node, nodeOwners[node], address(0));
        nodeOwners[node] = address(0);
    }

    function ownerOfNode(bytes32 node) public view returns (address) {
        return nodeOwners[node];
    }

    // Sets ownership of a name in the registrar. If the name
    // is locked, only the owner can transfer ownership by
    // calling transferNodeOwnership.
    function setSubnodeOwner(bytes32 label, address owner) public onlyRegistry returns(bytes32) {
        require(!root.locked(label), "name locked");
        bytes32 node = keccak256(abi.encodePacked(bytes32(0), label));
        emit NodeOwnerChanged(node, nodeOwners[node], owner);
        nodeOwners[node] = owner;
        return node;
    }

    // Whitelists a controller address to be used by the specified node.
    function approveControllerForNode(bytes32 node, address controller, bool approved) external onlyRegistry {
        registryNodeControllers[node][controller] = approved;
        emit RegistryNodeControllersChanged(node, controller, approved);
    }

    // Whitelists a controller address to be used by any node.
    function approveController(address controller, bool approved) public onlyRegistry {
        registryControllers[controller] = approved;
        emit RegistryControllersChanged(controller, approved);
    }
}