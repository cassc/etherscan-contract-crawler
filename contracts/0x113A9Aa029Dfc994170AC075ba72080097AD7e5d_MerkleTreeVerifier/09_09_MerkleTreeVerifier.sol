// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "AccessControl.sol";
import {MerkleProof} from "MerkleProof.sol";
import {IMerkleTreeVerifier} from "IMerkleTreeVerifier.sol";

contract MerkleTreeVerifier is AccessControl, IMerkleTreeVerifier {
    mapping(uint256 => bytes32) public roots;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event RootSet(uint256 index, bytes32 root);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _setRoot(uint256 index, bytes32 root) private {
        roots[index] = root;
        emit RootSet(index, root);
    }

    function setRoots(uint256[] calldata indexes, bytes32[] calldata _roots) external onlyRole(MANAGER_ROLE) {
        for (uint256 i; i < indexes.length; i++) {
            _setRoot(indexes[i], _roots[i]);
        }
    }

    function verify(
        uint256 index,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external view returns (bool) {
        return MerkleProof.verify(proof, roots[index], leaf);
    }
}