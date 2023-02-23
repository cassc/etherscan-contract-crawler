// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IWeb3Registry.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Web3Registry is IWeb3Registry, Initializable {
    struct Record {
        address owner;
        address resolver;
    }

    mapping(bytes32 => Record) records;
    mapping(address => mapping(address => bool)) operators;

    modifier authorized(bytes32 node) {
        address owner = records[node].owner;
        require(owner == msg.sender || operators[owner][msg.sender], "not authorized");
        _;
    }

    function __Web3Registry_init() external initializer {
        records[0x0].owner = msg.sender;
    }

    function setRecord(
        bytes32 node,
        address owner,
        address resolver
    ) external {
        setOwner(node, owner);
        _setResolver(node, resolver);
    }

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver
    ) external {
        bytes32 subnode = setSubnodeOwner(node, label, owner);
        _setResolver(subnode, resolver);
    }

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) public authorized(node) returns (bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        records[subnode].owner = owner;
        emit NewOwner(node, label, owner);
        return subnode;
    }

    function setResolver(bytes32 node, address resolver) public authorized(node) {
        _setResolver(node, resolver);
    }

    function setOwner(bytes32 node, address owner) public authorized(node) {
        records[node].owner = owner;
        emit Transfer(node, owner);
    }

    function setApprovalForAll(address operator, bool approved) external {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function owner(bytes32 node) external view returns (address) {
        return records[node].owner;
    }

    function resolver(bytes32 node) public view returns (address) {
        return records[node].resolver;
    }

    function recordExists(bytes32 node) public view returns (bool) {
        return records[node].owner != address(0x0);
    }

    function isApprovedForAll(address owner, address operator
    ) external view returns (bool) {
        return operators[owner][operator];
    }

    function _setResolver(bytes32 node, address resolver) internal {
        records[node].resolver = resolver;
        emit NewResolver(node, resolver);
    }

    uint256[48] private __gap;
}