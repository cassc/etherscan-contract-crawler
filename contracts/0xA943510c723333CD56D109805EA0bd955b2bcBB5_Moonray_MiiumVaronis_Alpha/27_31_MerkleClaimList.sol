// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {MerkleRoot} from './MerkleRoot.sol';

/**
 * @title MerkleClaimList
 * @author @NiftyMike, NFT Culture
 * @dev Basic functionality for a MerkleTree that will be used as a "Claimlist"
 *
 * "Claimlist" - an approach for validating callers that is backed by a Merkle Tree.
 * Cheap to set the master claim, not that expensive to check the claim. Requires
 * off-chain generation of the Merkle Tree.
 *
 * This library allows you to declare a member variable like:
 * MerkleClaimList.Root private _claimRoot;
 *
 * The benefit of packaging this as a library, is that if you need multiple merkle trees in your
 * contract, you can declare multiple member variables using this library, and use them in similar fashion.
 *
 * see also: NFTC Labs' MerkleLeaves.sol, which is a companion abstract contract which contains helper
 * methods for generating leaves for the Merkle Tree.
 */
library MerkleClaimList {
    using MerkleRoot for bytes32;

    struct Root {
        // This variable should never be directly accessed by users of the library. See OZ comments in other libraries for more info.
        bytes32 _root;
    }

    /**
     * @dev Validate that a leaf is part of this merkle tree.
     */
    function _checkLeaf(
        Root storage root,
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal view returns (bool) {
        return root._root.check(proof, leaf);
    }

    /**
     * @dev Set the root of this merkle tree.
     */
    function _setRoot(Root storage root, bytes32 __root) internal {
        root._root = __root;
    }
}