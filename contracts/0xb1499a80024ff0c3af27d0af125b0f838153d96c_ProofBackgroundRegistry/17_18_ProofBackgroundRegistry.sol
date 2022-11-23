// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";

import {MoonbirdAuthBase} from "moonbirds-inchain/MoonbirdAuth.sol";

import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Registry that allows Moonbird + PROOF holders to toggle the PROOF
 * background on their Moonbirds.
 */
contract ProofBackgroundRegistry is MoonbirdAuthBase {
    using FeaturesLib for Features;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if somebody else than the Moonbird owner tries to set its
     * background.
     */
    error OnlyMoonbirdOwner();

    /**
     * @notice Thrown if the parameters to set backgrounds for multiple
     * Moonbirds have mismatching lengths.
     */
    error ParameterLengthMismatch();

    // =========================================================================
    //                           Events
    // =========================================================================

    event ProofBackgroundSettingChanged(
        uint256 indexed tokenId,
        bool useProofBackground
    );

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Entries of the mutator registry.
     */
    struct RegistryEntry {
        // The address that set the entry.
        address proofer;
        // Toggles the PROOF background.
        bool useProofBackground;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The PROOF collective token.
     */
    IERC721 internal immutable _proof;

    /**
     * @notice The moonbird token.
     */
    IMoonbirds internal immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Stores the settings for each moonbird.
     * @dev Enabled backgrounds in the registry do not mean that they will
     * necessarily be shown in the final artwork. See also
     * `_usesProofBackground`.
     */
    mapping(uint256 => RegistryEntry) internal _entries;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(IERC721 proof_, IMoonbirds moonbirds_)
        MoonbirdAuthBase(moonbirds_, "ProofBackgroundRegistry", "1.0")
    {
        _proof = proof_;
        _moonbirds = moonbirds_;
    }

    /**
     * @notice Retrieves the settings for a specific moonbird.
     * @dev Does not check if the token exists. Returns zero as default.
     */
    function getEntry(uint256 tokenId)
        external
        view
        returns (RegistryEntry memory)
    {
        return _entries[tokenId];
    }

    // =========================================================================
    //                           Background activation
    // =========================================================================

    /**
     * @notice Returns if a given Moonbird uses the PROOF background.
     * @dev Next to the stored toggle this also depends on a few other dynamic
     * conditions (see inlined comments below).
     */
    function usesProofBackground(uint256 tokenId) public view returns (bool) {
        RegistryEntry memory entry = _entries[tokenId];
        address owner = _moonbirds.ownerOf(tokenId);

        // Don't show background if the MB was transferred to someone else
        if (owner != entry.proofer) {
            return false;
        }

        // Only show background for nested birds
        (bool nesting, , ) = _moonbirds.nestingPeriod(tokenId);
        if (!nesting) {
            return false;
        }

        // Background is exclusively for PROOF collective holders
        if (_proof.balanceOf(owner) == 0) {
            return false;
        }

        return entry.useProofBackground;
    }

    // =========================================================================
    //                           Background setting
    // =========================================================================

    /**
     * @notice Toggles the PROOF background preference for a given Moonbird.
     * @dev Enabling the background here, does not mean that it will necessarily
     * be shown in the final artwork. See also `_usesProofBackground`.
     * @dev Reverts if the caller is not the Moonbird owner.
     */
    function setProofBackground(uint256 tokenId, bool useProofBackground)
        external
    {
        _setProofBackgroundByOwner(tokenId, useProofBackground);
    }

    /**
     * @notice Convenience function to set the background for multiple moonbirds
     * in a single transaction.
     * @dev See also `setProofBackground`.
     */
    function setMultipleProofBackground(
        uint256[] calldata tokenIds,
        bool[] calldata useProofBackgrounds
    ) external {
        if (tokenIds.length != useProofBackgrounds.length) {
            revert ParameterLengthMismatch();
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _setProofBackgroundByOwner(tokenIds[i], useProofBackgrounds[i]);
        }
    }

    /**
     * @notice Toggles the PROOF background preference for a given Moonbird via
     * a delegated wallet.
     * @dev The caller has to be authorised by the moonbird owner.
     * @dev See also `setProofBackground`.
     */
    function setProofBackgroundWithSignature(
        uint256 tokenId,
        bool useProofBackground,
        bytes calldata signature
    ) external {
        _setProofBackgroundWithSignature(
            tokenId,
            useProofBackground,
            signature
        );
    }

    /**
     * @notice Convenience function to set the background for multiple moonbirds
     * in a single transaction.
     * @dev See also `setProofBackgroundWithSignature`.
     */
    function setMultipleProofBackgroundWithSignature(
        uint256[] calldata tokenIds,
        bool[] calldata useProofBackgrounds,
        bytes calldata signature
    ) external {
        if (tokenIds.length != useProofBackgrounds.length) {
            revert ParameterLengthMismatch();
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _setProofBackgroundWithSignature(
                tokenIds[i],
                useProofBackgrounds[i],
                signature
            );
        }
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    /**
     * @notice Ensures that the caller owns the moonbird before storing the
     * background settings.
     * @dev Reverts otherwise.
     */
    function _setProofBackgroundByOwner(uint256 tokenId, bool toggle) internal {
        address owner = _moonbirds.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert OnlyMoonbirdOwner();
        }

        _entries[tokenId] = RegistryEntry({
            proofer: owner,
            useProofBackground: toggle
        });

        emit ProofBackgroundSettingChanged(tokenId, toggle);
    }

    /**
     * @notice Ensures that the caller is authorised by the moonbirds owner
     * before storing the background settings.
     * @dev Reverts otherwise.
     */
    function _setProofBackgroundWithSignature(
        uint256 tokenId,
        bool toggle,
        bytes calldata signature
    ) internal onlyMoonbirdOwnerAuthorisedSender(tokenId, signature) {
        address owner = _moonbirds.ownerOf(tokenId);

        _entries[tokenId] = RegistryEntry({
            proofer: owner,
            useProofBackground: toggle
        });

        emit ProofBackgroundSettingChanged(tokenId, toggle);
    }
}