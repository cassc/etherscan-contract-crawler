// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../root/Root.sol";
import "./UniversalRegistrar.sol";

contract UniversalRootController is Ownable {
    Root public root;
    UniversalRegistrar public registrar;

    event NewClaim(string name, address indexed registrar, address indexed controller);

    constructor(Root _root, UniversalRegistrar _registrar) {
        root = _root;
        registrar = _registrar;
    }

    function approveRegistrarController(address registrarController, bool approved) public onlyOwner {
        registrar.approveController(registrarController, approved);
    }

    function approveRegistrarControllerForNode(bytes32 node, address registrarController, bool approved) public onlyOwner {
        registrar.approveControllerForNode(node, registrarController, approved);
    }

    /**
     * @param name the top level name.
     * @param controller the controller address (must be approved by registry)
     */
    function claim(string memory name, address controller) external onlyOwner {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = keccak256(abi.encodePacked(bytes32(0), label));

        require(root.ens().owner(node) == address(0), "TLD already claimed");

        // Add TLD to registrar temporarily setting |this| as the owner
        node = registrar.setSubnodeOwner(label, address(this));

        // Only owner of the node can add a controller
        // Since we own the node temporarily we can add a
        // controller.
        registrar.addController(node, controller);

        // Give ownership of TLD in the registrar back to sender
        registrar.transferNodeOwnership(node, msg.sender);

       // Add the registrar contract as the owner of this TLD in the ENS registry
        root.setSubnodeOwner(label, address(registrar));

        emit NewClaim(name, address(registrar), address(controller));
    }

    // Registry can change ownership of non-locked TLDs
    function setSubnodeOwner(bytes32 label, address owner) external onlyOwner
    {
        root.setSubnodeOwner(label, owner);
    }

    // Permanently lock a name in the ENS registry
    function lock(bytes32 label) external onlyOwner
    {
        root.lock(label);
    }
}