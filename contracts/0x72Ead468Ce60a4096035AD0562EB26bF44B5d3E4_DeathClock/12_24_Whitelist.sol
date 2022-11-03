// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

error AlreadyClaimed();
error InvalidProof();
error MerkleRootNotSet();

contract Whitelist {
    using BitMaps for BitMaps.BitMap;

    uint256 public activeMerkleRoot;
    mapping(uint256 => bytes32) public merkleRoots;
    mapping(bytes32 => BitMaps.BitMap) private _claimed;

    function _verifyProof(uint256 index, bytes32[] calldata proof) internal view {
        bytes32 merkleRoot = merkleRoots[activeMerkleRoot];
        if (merkleRoot == 0x0) revert MerkleRootNotSet();
        if (_claimed[merkleRoot].get(index)) revert AlreadyClaimed();
        bytes32 node = keccak256(abi.encodePacked(msg.sender, index));
        if (!MerkleProof.verify(proof, merkleRoot, node)) revert InvalidProof();
    }

    function _setActiveMerkleRoot(uint256 merkleRootIndex) internal {
        activeMerkleRoot = merkleRootIndex;
    }

    /// @notice Set merkle root at specified index.
    function _setMerkleRoot(uint256 merkleRootIndex, bytes32 merkleRoot) internal {
        merkleRoots[merkleRootIndex] = merkleRoot;
    }

    function _setClaimed(uint256 index) internal {
        _claimed[merkleRoots[activeMerkleRoot]].set(index);
    }
}