// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {LazyMintLib} from "../LazyMint/LazyMintLib.sol";
import {ERC721ALib} from "../ERC721A/ERC721ALib.sol";

error IncorrectAllowlistEntries();
error ExceededAllowlistMintLimit();

library MerkleTreeAllowlistLibV2 {
    bytes32 constant MERKLE_TREE_ALLOWLIST_STORAGE_POSITION =
        keccak256("merkle.tree.allowlist.storage.v2");

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

    function allowlistMint(
        uint256 _quantityToMint,
        uint256 _quantityAllowListEntries,
        bytes32[] calldata _merkleProof
    ) internal returns (uint256) {
        // merkle proof then lazy mint mint
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, _quantityAllowListEntries)
        );

        bool isOnAllowlist = MerkleProof.verify(
            _merkleProof,
            merkleTreeAllowlistStorage().allowlistMerkleRoot,
            leaf
        );

        if (!isOnAllowlist) {
            revert IncorrectAllowlistEntries();
        }

        uint256 numMintedSoFar = ERC721ALib._numberMinted(msg.sender);
        if ((numMintedSoFar + _quantityToMint) > _quantityAllowListEntries)
            revert ExceededAllowlistMintLimit();

        return LazyMintLib.publicMint(_quantityToMint);
    }

    function isAddressOnAllowlist(
        address _maybeAllowlistAddress,
        uint256 _quantityAllowlistEntries,
        bytes32[] calldata _merkleProof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_maybeAllowlistAddress, _quantityAllowlistEntries)
        );
        return
            MerkleProof.verify(
                _merkleProof,
                merkleTreeAllowlistStorage().allowlistMerkleRoot,
                leaf
            );
    }
}