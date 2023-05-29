// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {MoonbirdAuthBase} from "moonbirds-inchain/MoonbirdAuth.sol";
import {IFeaturesProvider} from "moonbirds-inchain/types/IFeaturesProvider.sol";

import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

contract MoonbirdFeaturesRegistry is
    IFeaturesProvider,
    Ownable,
    MoonbirdAuthBase
{
    using FeaturesLib for Features;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown when trying to retrieve the features of a not yet stored
     * Moonbird.
     */
    error MoonbirdNotSet();

    /**
     * @notice Thrown when trying to set Moonbird features twice.
     */
    error MoonbirdAlreadySet();

    /**
     * @notice Thrown if a Merkle proof has incorrect length.
     */
    error MalformedProof();

    /**
     * @notice Thrown if the features of a Moonbird have been manipulated.
     * @dev I.e. if the Merkle proof is invalid.
     */
    error IncorrectProof();

    /**
     * @notice Thrown if the caller is not the Moonbird owner.
     */
    error OnlyMoonbirdOwner();

    /**
     * @notice Thrown if a holder tries to register their Moonbird after the
     * deadline.
     */
    error RegistryClosed();

    /**
     * @notice Thrown if the parameters to register multiple Moonbirds have
     * mismatching lengths.
     */
    error ParameterLengthMismatch();

    // =========================================================================
    //                           Events
    // =========================================================================

    event MoonbirdLandedInchain(
        uint256 indexed tokenId,
        address indexed setter
    );

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Entries of the mutator registry.
     */
    struct RegistryEntry {
        // The address that set the entry.
        address settooor;
        // The Moonbird features
        Features features;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The moonbird token.
     */
    IERC721 internal immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    mapping(uint256 => RegistryEntry) internal _entries;

    /**
     * @notice Toggle to allow holders to store the features of their Moonbirds.
     */
    bool public isOpen;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(IERC721 moonbirds_)
        MoonbirdAuthBase(moonbirds_, "MoonbirdFeaturesRegistry", "1.0")
    {
        _moonbirds = moonbirds_;
    }

    /**
     * @notice Returns the address that set the registry entry for a given
     * Moonbird.
     */
    function getSettooor(uint256 tokenId) external view returns (address) {
        if (!hasFeatures(tokenId)) {
            revert MoonbirdNotSet();
        }

        return _entries[tokenId].settooor;
    }

    // =========================================================================
    //                           IFeaturesProvider
    // =========================================================================

    /**
     * @notice Checks if the registry has features for a given Moonbird.
     */
    function hasFeatures(uint256 tokenId) public view returns (bool) {
        return _entries[tokenId].settooor != address(0);
    }

    /**
     * @notice Returns the features of a given moonbird.
     * @dev Reverts if the token is not found in the registry.
     */
    function getFeatures(uint256 tokenId)
        external
        view
        returns (Features memory)
    {
        if (!hasFeatures(tokenId)) {
            revert MoonbirdNotSet();
        }

        return _entries[tokenId].features;
    }

    // =========================================================================
    //                           Feature registration
    // =========================================================================

    /**
     * @notice Allows holders to set the features of their moonbird.
     * @dev Can only be called by the owner of the respective moonbird.
     * @param tokenId The moonbird to be stored on-chain
     * @param features The features of the moonbird
     * @param proof A merkle proof ensuring that the features have not been
     * tampered with.
     */
    function setFeatures(
        uint256 tokenId,
        Features calldata features,
        bytes32[] calldata proof
    ) public onlyIfOpen {
        _setFeaturesOwner(tokenId, features, proof);
    }

    /**
     * @notice Convenience function to set the features of multiple moonbirds
     * in a single tx.
     * @dev See also `setMultipleFeatures`.
     */
    function setMultipleFeatures(
        uint256[] calldata tokenIds,
        Features[] calldata featuress,
        bytes32[][] calldata proofs
    ) external onlyIfOpen {
        if (
            tokenIds.length != featuress.length ||
            tokenIds.length != proofs.length
        ) {
            revert ParameterLengthMismatch();
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _setFeaturesOwner(tokenIds[i], featuress[i], proofs[i]);
        }
    }

    /**
     * @notice Allows holders to set the features of their moonbird via a
     * delegated wallet.
     * @dev Can only be called with a valid authorisation.
     * @param tokenId The moonbird to be stored on-chain
     * @param features The features of the moonbird
     * @param proof A merkle proof ensuring that the features have not been
     * tampered with.
     * @param signature The EIP712 signature proving the the caller is
     * authorised for this action.
     */
    function setFeaturesWithSignature(
        uint256 tokenId,
        Features calldata features,
        bytes32[] calldata proof,
        bytes calldata signature
    ) public onlyIfOpen {
        _setFeaturesWithSignature(tokenId, features, proof, signature);
    }

    /**
     * @notice Convenience function to set the features of multiple moonbirds
     * in a single tx.
     * @dev See also `setFeaturesWithSignature`.
     */
    function setMultipleFeaturesWithSignature(
        uint256[] calldata tokenIds,
        Features[] calldata featuress,
        bytes32[][] calldata proofs,
        bytes calldata signature
    ) public onlyIfOpen {
        if (
            tokenIds.length != featuress.length ||
            tokenIds.length != proofs.length
        ) {
            revert ParameterLengthMismatch();
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _setFeaturesWithSignature(
                tokenIds[i],
                featuress[i],
                proofs[i],
                signature
            );
        }
    }

    // =========================================================================
    //                            Steering
    // =========================================================================

    function setOpen(bool open) external onlyOwner {
        isOpen = open;
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    modifier onlyIfOpen() {
        if (!isOpen) {
            revert RegistryClosed();
        }
        _;
    }

    /**
     * @notice Stores the features for a given moonbird.
     * @dev Reverts if the caller is not the moonbird owner.
     * @dev Reverts if the Merkle proof is invalid.
     */
    function _setFeatures(
        uint256 tokenId,
        Features calldata features,
        bytes32[] calldata proof
    ) internal {
        if (hasFeatures(tokenId)) {
            revert MoonbirdAlreadySet();
        }

        if (proof.length != 14) {
            revert MalformedProof();
        }

        features.validate();

        if (
            !MerkleProof.verifyCalldata(
                proof,
                FeaturesLib.FEATURES_ROOT,
                features.hash(tokenId)
            )
        ) {
            revert IncorrectProof();
        }

        _entries[tokenId] = RegistryEntry({
            settooor: _moonbirds.ownerOf(tokenId),
            features: features
        });

        emit MoonbirdLandedInchain(tokenId, msg.sender);
    }

    /**
     * @notice Ensures that the caller owns the moonbird before storing the
     * features.
     * @dev Reverts otherwise.
     */
    function _setFeaturesOwner(
        uint256 tokenId,
        Features calldata features,
        bytes32[] calldata proof
    ) internal {
        if (_moonbirds.ownerOf(tokenId) != msg.sender) {
            revert OnlyMoonbirdOwner();
        }
        _setFeatures(tokenId, features, proof);
    }

    /**
     * @notice Ensures that the caller is authorised by moonbird owener before
     * storing the features.
     * @dev Reverts otherwise.
     */
    function _setFeaturesWithSignature(
        uint256 tokenId,
        Features calldata features,
        bytes32[] calldata proof,
        bytes calldata signature
    ) internal onlyMoonbirdOwnerAuthorisedSender(tokenId, signature) {
        _setFeatures(tokenId, features, proof);
    }
}