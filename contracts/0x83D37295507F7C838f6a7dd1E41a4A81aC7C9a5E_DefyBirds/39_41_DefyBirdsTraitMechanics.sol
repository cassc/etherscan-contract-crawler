// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.18;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {ERC721ACommonBaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {NUM_COLORS, TraitSampling} from "./TraitSampling.sol";

/**
 * @notice Encodes the metadata/traits of DefyBirds tokens.
 */
struct TokenMetadata {
    uint8 color;
    uint8 body;
    bool glitch;
    bool placeholder;
}

/**
 * @notice DefyBirds module handling trait-related aspects.
 */
abstract contract DefyBirdsTraitMechanics is ERC721ACommonBaseTokenURI {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if a user attempts to burn a placeholder token.
     */
    error CannotBurnPlaceholder();

    /**
     * @notice Thrown if a users attempts to burn a glitch token.
     */
    error CannotBurnGlitch();

    /**
     * @notice Thrown if a user does not burn a token of each color trait.
     */
    error MustBurnOneOfEachColor(uint256 bitmap);

    /**
     * @notice Thrown if a user attempts to burn tokens with different body
     * traits.
     */
    error CannotBurnDifferentBodies(uint8 got, uint8 want);

    /**
     * @notice Thrown if a user attempts to burn while the feature is not
     * enabled.
     */
    error BurnDisabled();

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Flag to enable/disable the burn.
     */
    bool public burnEnabled;

    /**
     * @notice Stores manually set DefyBirds metadata.
     * @dev This will only be used for glitch DefyBirds.
     */
    mapping(uint256 => TokenMetadata) private _metadata;

    // =========================================================================
    //                   Metadata Sampling and Getters
    // =========================================================================

    /**
     * @notice Returns a random seed for a given token.
     * @dev If the seed is not available yet, this routine returns `0`.
     */
    function _seed(uint256 tokenId) internal view virtual returns (uint256);

    /**
     * @notice Returns or generates random token metadata from the token seed.
     * @dev If the seed is not available yet, placeholder metadata will be
     * returned.
     */
    function tokenMetadata(uint256 tokenId)
        public
        view
        virtual
        returns (TokenMetadata memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        TokenMetadata memory md = _metadata[tokenId];
        if (md.glitch) {
            return md;
        }

        uint256 seed = _seed(tokenId);
        if (seed == 0) {
            md.placeholder = true;
            return md;
        }

        (md.color, md.body) = TraitSampling.sampleColorAndBody(seed);
        return md;
    }

    /**
     * @notice Returns the tokenURI for a token.
     * @dev Depending on the token type, the URI follows the following patterns
     * - <baseURI>/placeholder
     * - <baseURI>/glitch/<:body>
     * - <baseURI>/regular/<:body>/<:color>
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        TokenMetadata memory md = tokenMetadata(tokenId);

        if (md.placeholder) {
            return string.concat(_baseURI(), "placeholder");
        }

        if (md.glitch) {
            return
                string.concat(_baseURI(), "glitch/", Strings.toString(md.body));
        }

        return string.concat(
            _baseURI(),
            "regular/",
            Strings.toString(md.body),
            "/",
            Strings.toString(md.color)
        );
    }

    // =========================================================================
    //                           Token Burning
    // =========================================================================

    /**
     * @notice Burns 8 tokens of same body but pairwise different color traits
     * to obtain a glitch DefyBird.
     */
    function burn(uint256[8] calldata tokenIds) external {
        if (!burnEnabled) {
            revert BurnDisabled();
        }

        uint8 body;
        uint256 colorBitmap;
        for (uint256 i; i < tokenIds.length; ++i) {
            TokenMetadata memory md = tokenMetadata(tokenIds[i]);

            if (md.glitch) {
                revert CannotBurnGlitch();
            }

            if (md.placeholder) {
                revert CannotBurnPlaceholder();
            }

            if (i == 0) {
                body = md.body;
            } else {
                if (body != md.body) {
                    revert CannotBurnDifferentBodies(md.body, body);
                }
            }

            // Setting a bit for each color to check if we got all
            colorBitmap |= 1 << md.color;

            _burn(tokenIds[i], true);
        }

        // Least-significant 8 bits are set iff all colors were supplied.
        if (colorBitmap != (1 << NUM_COLORS) - 1) {
            revert MustBurnOneOfEachColor(colorBitmap);
        }

        _metadata[_nextTokenId()] = TokenMetadata({
            color: 0,
            body: body,
            glitch: true,
            placeholder: false
        });
        _mint(msg.sender, 1);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Toggles the burn feature.
     */
    function toggleBurn(bool toggle) external onlyRole(DEFAULT_STEERING_ROLE) {
        burnEnabled = toggle;
    }
}