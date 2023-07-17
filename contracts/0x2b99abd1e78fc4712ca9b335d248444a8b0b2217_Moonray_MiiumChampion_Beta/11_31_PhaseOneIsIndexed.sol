// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/utility/AuxHelper32.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

error IndexedProofInvalid_PhaseOne();

/**
 * @title PhaseOneIsIndexed
 */
abstract contract PhaseOneIsIndexed is MerkleLeaves, AuxHelper32 {
    using MerkleClaimList for MerkleClaimList.Root;

    MerkleClaimList.Root private _phaseOneRoot;

    constructor() {}

    /**
     * @dev Set the root of this merkle tree.
     */
    function _setPhaseOneRoot(bytes32 __root) internal {
        _phaseOneRoot._setRoot(__root);
    }

    function checkProof_PhaseOne(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextEntryIndex_PhaseOne(address wallet) external view returns (uint256) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseOnePurchases;
    }

    function getTokensPurchased_PhaseOne(address wallet) external view returns (uint32) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseOnePurchases;
    }

    function _getPackedPurchasesAs64(address wallet) internal view virtual returns (uint64);

    function _proofMintTokens_PhaseOne(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseOne();
        }

        _internalMintTokens(minter, count);
    }

    function _internalMintTokens(address minter, uint256 count) internal virtual;

    function _proofMintTokensOfFlavor_PhaseOne(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 flavorId
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseOne();
        }

        _internalMintTokens(minter, count, flavorId);
    }

    function _internalMintTokens(
        address minter,
        uint256 count,
        uint256 flavorId
    ) internal virtual;
}