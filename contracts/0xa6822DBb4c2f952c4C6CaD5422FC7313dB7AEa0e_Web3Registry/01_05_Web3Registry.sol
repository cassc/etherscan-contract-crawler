// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IWeb3Registry.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

contract Web3Registry is IWeb3Registry, Initializable {
    struct Record {
        address owner;
        address resolver;
    }
    bytes32 constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    mapping(bytes32 => Record) records;
    mapping(address => mapping(address => bool)) operators;
    ENS public ens;
    bytes32 public ensBaseNode;
    // node => ensNode
    mapping(bytes32 => bytes32) public ensNodeMap;
    // ensNode => node
    mapping(bytes32 => bytes32) public nodeMap;

    modifier authorized(bytes32 node) {
        address _owner = records[node].owner;
        require(
            _owner == msg.sender || operators[_owner][msg.sender],
            "not authorized"
        );
        _;
    }

    function __Web3Registry_init() external initializer {
        records[0x0].owner = msg.sender;
    }

    function setENS(ENS _ens, bytes32 _ensBaseNode) external authorized(0x0) {
        ens = _ens;
        ensBaseNode = _ensBaseNode;
    }

    function setRecord(
        bytes32 node,
        address _owner,
        address _resolver
    ) external {
        setOwner(node, _owner);
        _setResolver(node, _resolver);
    }

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address _owner,
        address _resolver
    ) external {
        bytes32 subnode = setSubnodeOwner(node, label, _owner);
        _setResolver(subnode, _resolver);
    }

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address _owner
    ) public authorized(node) returns (bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        records[subnode].owner = _owner;
        emit NewOwner(node, label, _owner);
        // check if it's an addr reverse node
        if (node != ADDR_REVERSE_NODE) {
            // ens, set owner to this contract
            bytes32 ensSubnode = ens.setSubnodeOwner(
                ensBaseNode,
                label,
                address(this)
            );
            // record node mapping
            ensNodeMap[subnode] = ensSubnode;
            nodeMap[ensSubnode] = subnode;
        }
        return subnode;
    }

    function setResolver(
        bytes32 node,
        address _resolver
    ) public authorized(node) {
        _setResolver(node, _resolver);
    }

    function setOwner(bytes32 node, address _owner) public authorized(node) {
        records[node].owner = _owner;
        emit Transfer(node, _owner);
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

    function isApprovedForAll(
        address _owner,
        address operator
    ) external view returns (bool) {
        return operators[_owner][operator];
    }

    function _setResolver(bytes32 node, address _resolver) internal {
        records[node].resolver = _resolver;
        emit NewResolver(node, _resolver);
        // ens
        if (ensNodeMap[node] != bytes32(0x0)) {
            ens.setResolver(ensNodeMap[node], _resolver);
        }
    }

    uint256[44] private __gap;
}