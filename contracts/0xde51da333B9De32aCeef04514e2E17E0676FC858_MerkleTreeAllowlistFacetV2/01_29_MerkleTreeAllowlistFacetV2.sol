// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {SaleStateModifiers} from "../BaseNFTModifiers.sol";
import {PausableModifiers} from "../Pausable/PausableModifiers.sol";
import {MerkleTreeAllowlistLibV2} from "./MerkleTreeAllowlistLibV2.sol";

contract MerkleTreeAllowlistFacetV2 is
    AccessControlModifiers,
    SaleStateModifiers,
    PausableModifiers
{
    function setAllowlistMerkleRootV2(bytes32 _allowlistMerkleRoot)
        public
        onlyOperator
        whenNotPaused
    {
        MerkleTreeAllowlistLibV2.setAllowlistMerkleRoot(_allowlistMerkleRoot);
    }

    function allowlistMintV2(
        uint256 _quantityToMint,
        uint256 _quantityAllowlistEntries,
        bytes32[] calldata _merkleProof
    ) public payable whenNotPaused onlyAtSaleState(2) returns (uint256) {
        return
            MerkleTreeAllowlistLibV2.allowlistMint(
                _quantityToMint,
                _quantityAllowlistEntries,
                _merkleProof
            );
    }

    function isAddressOnAllowlistV2(
        address _maybeAllowlistAddress,
        uint256 _quantityAllowlistEntries,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        return
            MerkleTreeAllowlistLibV2.isAddressOnAllowlist(
                _maybeAllowlistAddress,
                _quantityAllowlistEntries,
                _merkleProof
            );
    }

    function getAllowlistMerkleRootV2() public view returns (bytes32) {
        return
            MerkleTreeAllowlistLibV2
                .merkleTreeAllowlistStorage()
                .allowlistMerkleRoot;
    }
}