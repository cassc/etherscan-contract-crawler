// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "../universal/UniversalRegistrar.sol";
import "./Access.sol";

contract NameStore is Access {
    mapping(uint256 => bytes32) public tokenToExtension;

    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => address))) public reservedNames;
    mapping(bytes32 => uint256) public reservedNamesVersion;

    mapping(bytes32 => bool) public registrationsPaused;

    mapping(bytes32 => bytes) public metadata;

    event NameReserved(bytes32 indexed node, string name, address recipient);
    event ReservedNamesCleared(bytes32 indexed node);
    event RegistrationsPauseChanged(bytes32 indexed node, bool paused);
    event MetadataChanged(bytes32 indexed node);

    constructor(UniversalRegistrar _registrar) Access(_registrar) {}

    function parentOf(uint256 tokenId) external view returns (bytes32) {
        return tokenToExtension[tokenId];
    }

    function adopt(bytes32 parent, bytes32 label) external {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(parent, label)));
        tokenToExtension[tokenId] = parent;
    }

    function bulkAdopt(bytes32 parent, bytes32[] calldata labels) external {
        for (uint i = 0; i < labels.length; i++) {
            uint256 tokenId = uint256(keccak256(abi.encodePacked(parent, labels[i])));
            tokenToExtension[tokenId] = parent;
        }
    }

    function setMetadata(bytes32 node, bytes calldata _metadata) external nodeOperator(node) {
        metadata[node] = _metadata;
        emit MetadataChanged(node);
    }

    function reserved(bytes32 node, bytes32 label) external view returns (address) {
        return reservedNames[reservedNamesVersion[node]][node][label];
    }

    function available(bytes32 node, bytes32 label) external view returns (bool) {
        return reservedNames[reservedNamesVersion[node]][node][label] == address(0) && !registrationsPaused[node];
    }

    function pauseRegistrations(bytes32 node) external nodeOperator(node) {
        registrationsPaused[node] = true;
        emit RegistrationsPauseChanged(node, true);
    }

    function unpauseRegistrations(bytes32 node) external nodeOperator(node) {
        registrationsPaused[node] = false;
        emit RegistrationsPauseChanged(node, false);
    }

    // can be called by either the TLD owner or a controller authorised by the TLD owner.
    function reserve(bytes32 node, string calldata name, address recipient) external {
        require(isNodeApprovedOrOwner(node, msg.sender) ||
                isNodeOperator(node, msg.sender) ||
                registrar.controllers(node, msg.sender),
            "caller is not a controller, owner or operator");
        _reserve(node, name, recipient);
    }

    function _reserve(bytes32 node, string calldata name, address recipient) internal {
        bytes32 label = keccak256(bytes(name));
        reservedNames[reservedNamesVersion[node]][node][label] = recipient;
        emit NameReserved(node, name, recipient);
    }

    function bulkReserve(bytes32 node, string[] calldata names, address[] calldata recipients) external nodeOperator(node) {
        require(names.length == recipients.length, "names and recipients must have the same length");
        for (uint i = 0; i < names.length; i++) {
            bytes32 label = keccak256(bytes(names[i]));
            reservedNames[reservedNamesVersion[node]][node][label] = recipients[i];
            emit NameReserved(node, names[i], recipients[i]);
        }
    }

    function clearReservedNames(bytes32 node) external nodeOperator(node) {
        reservedNamesVersion[node]++;
        emit ReservedNamesCleared(node);
    }
}