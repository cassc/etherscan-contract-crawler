// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../root/SimpleHNSOracle.sol";
import "../root/Root.sol";
import "../universal/UniversalRegistrar.sol";
import "../common/SinglePriceOracle.sol";
import "./ImperviousRoot.sol";

contract UniversalRootControllerV2 is Ownable {
    ImperviousRoot public rootWrapper;
    Root public root;
    UniversalRegistrar public registrar;
    SimpleHNSOracle public oracle;
    SinglePriceOracle public priceOracle;

    event NewClaim(string name, address indexed registrar, address indexed controller);

    constructor(ImperviousRoot _wrapper, SimpleHNSOracle _oracle, SinglePriceOracle _priceOracle) {
        rootWrapper = _wrapper;
        root = _wrapper.root();
        registrar = _wrapper.registrar();
        oracle = _oracle;
        priceOracle = _priceOracle;
    }

    function approveRegistrarController(address registrarController, bool approved) public onlyOwner {
        registrar.approveController(registrarController, approved);
    }

    function approveRegistrarControllerForNode(bytes32 node, address registrarController, bool approved) public onlyOwner {
        registrar.approveControllerForNode(node, registrarController, approved);
    }

    /**
     * @param name the top level name.
     * @param locked whether the TLD is locked on Handshake
     * @param expire signature expire time
     * @param signature oracle proof
     * @param controller the controller address (must be approved by registry)
     */
    function claim(string calldata name, bool locked, uint256 expire, bytes memory signature, address controller) external payable {
        uint256 cost = priceOracle.price();
        require(msg.value >= cost, "insufficient funds");

        bytes32 label = keccak256(bytes(name));
        require(oracle.verify(label, address(root.ens()), msg.sender, locked, expire, signature), "bad claim");

        // Add TLD to registrar temporarily setting |this| as the owner
        bytes32 node = registrar.setSubnodeOwner(label, address(this));

        // Only owner of the node can add a controller
        // Since we own the node temporarily we can add a
        // controller.
        registrar.addController(node, controller);

        // Add the registrar contract as the owner of this TLD in the ENS registry
        root.setSubnodeOwner(label, address(registrar));

        // If TLD is provably locked, mint the NFT
        if (locked) {
            root.lock(label);

            // Prove to ImperviousRoot |this| owns the TLD
            rootWrapper.claimOwnership(node);

            // Give ownership to ImperviousRoot
            registrar.transferNodeOwnership(node, address(rootWrapper));

            // Mint NFT TLD to msg.sender
            rootWrapper.mint(msg.sender, name);
        } else {
            // Give ownership of TLD in the registrar back to sender
            registrar.transferNodeOwnership(node, msg.sender);
        }

        emit NewClaim(name, address(registrar), address(controller));

        // Refund any extra payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    // Registry can change ownership of non-locked TLDs
    function setSubnodeOwner(bytes32 label, address owner) external onlyOwner
    {
        root.setSubnodeOwner(label, owner);
    }

    // Permanently lock a name in the ENS registry with an oracle proof
    function lockWithProof(bytes32 label, address claim, uint256 expire, bytes memory signature) external {
        require(!root.locked(label), "name already locked");
        require(oracle.verify(label, address(root.ens()), claim, true, expire, signature), "bad proof");
        bytes32 node = keccak256(abi.encodePacked(bytes32(0), label));
        require(registrar.ownerOfNode(node) == msg.sender, "sender is not owner of node");
        root.lock(label);
        rootWrapper.claimOwnership(node);
    }

    // Permanently lock a name in the ENS registry
    function lock(bytes32 label) external onlyOwner
    {
        root.lock(label);
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }
}