// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {LazyMintLib} from "../LazyMint/LazyMintLib.sol";

error NotOnAllowlist();

library MerkleTreeAllowlistLib {
    bytes32 constant MERKLE_TREE_ALLOWLIST_STORAGE_POSITION =
        keccak256("merkle.tree.allowlist.storage");

    struct MerkleTreeAllowlistStorage {
        bytes32 allowlistMerkleRoot;
    }

    function merkleTreeAllowlistStorage()
        internal
        pure
        returns (MerkleTreeAllowlistStorage storage s)
    {
        bytes32 position = MERKLE_TREE_ALLOWLIST_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) internal {
        merkleTreeAllowlistStorage().allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function allowlistMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        internal
        returns (uint256)
    {
        // merkle proof then lazy mint mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isOnAllowlist = MerkleProof.verify(
            _merkleProof,
            merkleTreeAllowlistStorage().allowlistMerkleRoot,
            leaf
        );

        if (!isOnAllowlist) {
            revert NotOnAllowlist();
        }

        return LazyMintLib.publicMint(_quantity);
    }

    function isAddressOnAllowlist(
        address _maybeAllowlistAddress,
        bytes32[] calldata _merkleProof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_maybeAllowlistAddress));
        return
            MerkleProof.verify(
                _merkleProof,
                merkleTreeAllowlistStorage().allowlistMerkleRoot,
                leaf
            );
    }
}