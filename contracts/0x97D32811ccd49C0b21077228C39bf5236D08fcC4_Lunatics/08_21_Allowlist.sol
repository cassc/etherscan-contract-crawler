// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Allowlist {
    bytes32 private _merkleRoot;
    string private _uri;

    /// @notice mapping of address to if they have claimed
    mapping(address => bool) private _claimed;

    function allowlist() internal view returns (bytes32, string memory) {
        return (_merkleRoot, _uri);
    }

    function claimed(address from) public view returns (bool) {
        return _claimed[from];
    }

    function verifyProof(address from, bytes32[] calldata proof) public view returns (bool) {
        if (_merkleRoot == 0) return false;
        return MerkleProof.verify(proof, _merkleRoot, _formatLeaf(from));
    }

    function _formatLeaf(address from) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(from));
    }

    function _verifyProofOrRevert(address from, bytes32[] calldata proof) internal {
        if (_claimed[from] == true) revert AlreadyClaimed(from);
        if (verifyProof(from, proof) != true) revert NotOnAllowlist(from);
        _claimed[from] = true;
    }

    function _updateAllowList(bytes32 merkleRoot, string calldata uri) internal virtual {
        _merkleRoot = merkleRoot;
        _uri = uri;
    }
}

error NotOnAllowlist(address);
error AlreadyClaimed(address);