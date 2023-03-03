// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AllowList {
    error NotOnAllowList(address);

    /**
     * @notice A struct defining allow list data (for minting an allow list).
     *
     * @param merkleRoot    The merkle root for the allow list.
     * @param uri           The URI for the allow list.
     */
    struct AllowListData {
        bytes32 merkleRoot;
        string uri;
    }

    /// @notice Track the allow list merkle roots.
    mapping(bytes32 => AllowListData) private _allowListMerkleRoots;

    function verifyProof(
        bytes32 list,
        address from,
        bytes memory data,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        AllowListData memory d = _allowListMerkleRoots[list];
        if (d.merkleRoot == 0) return false;

        return MerkleProof.verify(merkleProof, d.merkleRoot, _formatLeaf(from, data));
    }

    function _formatLeaf(address from, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, data));
    }

    function _verifyProofOrRevert(
        bytes32 list,
        address from,
        bytes memory data,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        if (verifyProof(list, from, data, merkleProof) != true) {
            revert NotOnAllowList(from);
        }

        return true;
    }

    function _returnAllowList(bytes32 list) internal view returns (AllowListData memory) {
        return _allowListMerkleRoots[list];
    }

    function _updateAllowList(bytes32 id, AllowListData calldata allowListData) internal virtual {
        _allowListMerkleRoots[id] = allowListData;
    }
}