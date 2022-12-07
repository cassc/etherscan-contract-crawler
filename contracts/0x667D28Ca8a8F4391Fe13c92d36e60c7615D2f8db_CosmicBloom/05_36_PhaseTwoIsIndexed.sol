// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/utility/AuxHelper32.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

error IndexedProofInvalid_PhaseTwo();

/**
 * @title PhaseTwoIsIndexed
 * @author @NiftyMike, NFT Culture
 * @dev Indexed Merkle Tree mint functionality for Phase Two of a mint.
 */
abstract contract PhaseTwoIsIndexed is MerkleLeaves, AuxHelper32 {
    using MerkleClaimList for MerkleClaimList.Root;

    MerkleClaimList.Root private _phaseTwoRoot;

    constructor() {}

    function _setPhaseTwoRoot(bytes32 __root) internal {
        _phaseTwoRoot._setRoot(__root);
    }

    function checkProof_PhaseTwo(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextEntryIndex_PhaseTwo(address wallet) external view returns (uint256) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseTwoPurchases;
    }

    function getTokensPurchased_PhaseTwo(address wallet) external view returns (uint32) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseTwoPurchases;
    }

    function _getPackedPurchasesAs64(address wallet) internal view virtual returns (uint64);

    function _proofMintTokens_PhaseTwo(
        address claimant,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        address destination
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(claimant, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseTwo();
        }

        _internalMintTokens(destination, count);
    }

    function _proofMintTokensOfFlavor_PhaseTwo(
        address claimant,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 flavorId,
        address destination
    ) internal {
        // Verify proof matches expected target total number of indexed mints.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(claimant, newBalance - 1))) {
            //Zero-based index.
            revert IndexedProofInvalid_PhaseTwo();
        }

        _internalMintTokens(destination, count, flavorId);
    }

    function _internalMintTokens(address destination, uint256 count) internal virtual;

    function _internalMintTokens(
        address destination,
        uint256 count,
        uint256 flavorId
    ) internal virtual;
}