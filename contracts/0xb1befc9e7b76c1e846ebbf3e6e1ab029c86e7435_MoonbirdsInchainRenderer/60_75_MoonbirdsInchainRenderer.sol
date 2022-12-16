// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {Base64} from "openzeppelin-contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {DynamicBuffer} from "ethier/utils/DynamicBuffer.sol";
import {ITokenURIGenerator, IMoonbirds} from "moonbirds/Moonbirds.sol";

import {IFeaturesProvider} from "moonbirds-inchain/types/IFeaturesProvider.sol";
import {Attribute} from "moonbirds-inchain/types/Attribute.sol";
import {Mutators, IMutatorsProvider} from "moonbirds-inchain/types/IMutatorsProvider.sol";

import {BMP} from "ethier/utils/BMP.sol";
import {Image} from "ethier/utils/Image.sol";

import {Assembler} from "moonbirds-inchain/Assembler.sol";
import {BackgroundRegistry} from "moonbirds-inchain/BackgroundRegistry.sol";

import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Moonbirds in-chain renderer.
 * @dev The tokenURI falls back to the centralised one if the features of the
 * Moonbird were not yet uploaded to the on-chain registry. After the cutoff
 * date, the missing features will be filled in by PROOF - making the Moonbird
 * collection fully in-chain.
 */
contract MoonbirdsInchainRenderer is
    ITokenURIGenerator,
    Ownable,
    IFeaturesProvider
{
    using FeaturesLib for Features;
    using DynamicBuffer for bytes;
    using Strings for uint256;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the features of a given Moonbird are not registered
     * on-chain yet.
     */
    error NotInchainYet(uint256);

    /**
     * @notice Thrown if a given on-chain scaleup factor is not supported.
     */
    error UnsupportedScalingFactor();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The native resolution of Moonbird images (42x42).
     */
    uint32 internal constant _NATIVE_MB_RES = 42;

    /**
     * @notice Length of the BMP URI prefix (`data:image/bmp;base64,`).
     */
    uint256 internal constant _BMP_URI_PREFIX_LENGTH = 22;

    /**
     * @notice The moonbird token.
     */
    IMoonbirds internal immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The in-chain data assembler.
     */
    Assembler public assembler;

    /**
     * @notice The registry allowing users to store their Moonbird features.
     */
    IFeaturesProvider public userRegistry;

    /**
     * @notice The registry allowing proofers to activate their special
     * background.
     */
    BackgroundRegistry public backgroundRegistry;

    /**
     * @notice The features registry suppplied by PROOF filling in the remaining
     * missing features.
     * @dev This will point to nothing until after the cutoff date.
     */
    IFeaturesProvider public proofRegistry;

    /**
     * @notice The base URL for external links in the metadata (pointing to the
     * nesting site).
     */
    string internal _externalLinkBaseURL;

    /**
     * @notice The fallback base URI pointing to the off-chain renderer.
     * @dev This will no longer be used after the all features are stored on
     * chain.
     */
    string internal _offchainBaseURI;

    /**
     * @notice Factor by which the final image data will be scaled.
     * @dev Although all information is already contained in the image at the
     * native resolution, we scale the images for better appearance on larger
     * screens.
     */
    uint32 internal _bmpScale;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        IMoonbirds moonbirds_,
        IFeaturesProvider userRegistry_,
        BackgroundRegistry backgroundRegistry_,
        Assembler assembler_,
        string memory offchainBaseURI_
    ) {
        _moonbirds = moonbirds_;
        userRegistry = userRegistry_;
        backgroundRegistry = backgroundRegistry_;
        assembler = assembler_;
        _offchainBaseURI = offchainBaseURI_;

        _bmpScale = 22;
        _externalLinkBaseURL = "https://proof.xyz/moonbirds/";
    }

    // =========================================================================
    //                           IFeaturesProvider
    // =========================================================================

    /**
     * @notice Checks if the features for a given Moonbird can be found in any
     * registry.
     */
    function hasFeatures(uint256 tokenId) public view returns (bool) {
        if (
            address(userRegistry) != address(0) &&
            userRegistry.hasFeatures(tokenId)
        ) {
            return true;
        }

        if (
            address(proofRegistry) != address(0) &&
            proofRegistry.hasFeatures(tokenId)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @notice Returns the Moonbird features from one of the registries.
     * @dev Reverts if the token is not found in any registry.
     */
    function getFeatures(uint256 tokenId)
        public
        view
        returns (Features memory)
    {
        if (userRegistry.hasFeatures(tokenId)) {
            return userRegistry.getFeatures(tokenId);
        }

        if (address(proofRegistry) != address(0)) {
            return proofRegistry.getFeatures(tokenId);
        }

        revert NotInchainYet(tokenId);
    }

    // =========================================================================
    //                           IMutatorsProvider
    // =========================================================================

    /**
     * @notice Checks if the registry has mutators for a given Moonbird.
     * @dev Always true since the renderer can always return something.
     */
    function hasMutators(uint256) public pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns the mutator for a given Moonbird.
     * @dev Never throws because we can always return zero (i.e. no mutation).
     */
    function getMutators(uint256 tokenId)
        public
        view
        returns (Mutators memory)
    {
        if (address(backgroundRegistry) == address(0)) {
            return Mutators({backgroundId: 0});
        }

        return
            Mutators({
                backgroundId: backgroundRegistry.getActiveBackground(tokenId)
            });
    }

    // =========================================================================
    //                           Token Metadata
    // =========================================================================

    /**
     * @notice Returns the completely on-chain tokenURI if the features of the
     * associated birb have been set in any registy.
     * @dev Falls back to the off-chain tokenURI if no features are set.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (!hasFeatures(tokenId)) {
            return _offchainTokenURI(tokenId);
        }

        Features memory features = getFeatures(tokenId);
        Mutators memory mutators = getMutators(tokenId);

        bytes memory artwork = assembler.assembleArtwork(features, mutators);
        Attribute[] memory attrs = assembler.assembleAttributes(features);

        return _wrapMetadata(tokenId, artwork, attrs);
    }

    // =========================================================================
    //                           Composability
    // =========================================================================

    /**
     * @notice Returns the attributes of a given Moonbird.
     * @dev Intended to be consumed by other contracts for derivatives.
     * @dev Reverts if the Moonbird features cannot be found in any registry.
     */
    function attributes(uint256 tokenId)
        external
        view
        returns (Attribute[] memory)
    {
        Features memory features = getFeatures(tokenId);
        return assembler.assembleAttributes(features);
    }

    /**
     * @notice Returns the raw pixel data of a given Moonbird on the native
     * 42x42 resolution.
     * @dev Intended to be consumed by other contracts for derivatives.
     * @dev Row-major, BGR pixel encoding. The row ordering has been inverted
     * such that the data is directly compatible with the BMP format.
     * @dev Reverts if the Moonbird features cannot be found in any registry.
     */
    function artworkPixels(uint256 tokenId) public view returns (bytes memory) {
        Features memory features = getFeatures(tokenId);
        Mutators memory mutators = getMutators(tokenId);

        return assembler.assembleArtwork(features, mutators);
    }

    /**
     * @notice Returns the BMP data of a given Moonbird on the native
     * 42x42 resolution.
     * @dev Intended to be consumed by other contracts for derivatives.
     * @dev Reverts if the Moonbird features cannot be found in any registry.
     */
    function artworkBMP(uint256 tokenId) external view returns (bytes memory) {
        return BMP.bmp(artworkPixels(tokenId), _NATIVE_MB_RES, _NATIVE_MB_RES);
    }

    /**
     * @notice Computes arbitrary MB artwork based on input features and
     * mutators, scales it by a given factor and returns it wrapped as a
     * base64-encoded BMP dataURI.
     * @dev The final resolution is 42 * scaleupFactor.
     */
    function artworkURI(
        Features memory features,
        Mutators memory mutators,
        uint32 scaleupFactor
    ) public view returns (string memory) {
        bytes memory artwork = assembler.assembleArtwork(features, mutators);

        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_MB_RES * scaleupFactor,
            _NATIVE_MB_RES * scaleupFactor
        );

        bytes memory uri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3
        );

        _appendArtworkURI(uri, artwork, scaleupFactor);
        return string(uri);
    }

    /**
     * @notice Computes the MB artwork based on its features and arbitrary
     * mutators, scales it by a given factor and returns it wrapped as a
     * base64-encoded BMP dataURI.
     * @dev The final resolution is 42 * scaleupFactor.
     */
    function artworkURI(
        uint256 tokenId,
        Mutators memory mutators,
        uint32 scaleupFactor
    ) public view returns (string memory) {
        Features memory features = getFeatures(tokenId);
        return artworkURI(features, mutators, scaleupFactor);
    }

    /**
     * @notice Computes the MB artwork based on its features and the stored
     * mutators, scales it by a given factor and returns it wrapped as a
     * base64-encoded BMP dataURI.
     * @dev The final resolution is 42 * scaleupFactor.
     */
    function artworkURI(uint256 tokenId, uint32 scaleupFactor)
        public
        view
        returns (string memory)
    {
        Mutators memory mutators = getMutators(tokenId);
        return artworkURI(tokenId, mutators, scaleupFactor);
    }

    // =========================================================================
    //                            Steering
    // =========================================================================

    /**
     * @notice Sets the in-chain Moonbird assembler.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setAssembler(Assembler assembler_) external onlyOwner {
        assembler = assembler_;
    }

    /**
     * @notice Sets the Moonbird features registry where holders will store the
     * features of their moonbirds
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setUserRegistry(IFeaturesProvider userRegistry_)
        external
        onlyOwner
    {
        userRegistry = userRegistry_;
    }

    /**
     * @notice Sets the PROOF registry for Moonbird features covering the ones
     * that have not been set by the holders.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setProofRegistry(IFeaturesProvider proofRegistry_)
        external
        onlyOwner
    {
        proofRegistry = proofRegistry_;
    }

    /**
     * @notice Sets the PROOF background registry.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setBackgroundRegistry(BackgroundRegistry backgroundRegistry_)
        external
        onlyOwner
    {
        backgroundRegistry = backgroundRegistry_;
    }

    /**
     * @notice Sets the base URL for external links in the metadata.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setExternalLinkBaseURL(string memory externalLinkBaseURL_)
        external
        onlyOwner
    {
        _externalLinkBaseURL = externalLinkBaseURL_;
    }

    /**
     * @notice Sets the base URI for the off-chain tokenURI fallback.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setOffchainBaseURI(string memory offchainBaseURI_)
        external
        onlyOwner
    {
        _offchainBaseURI = offchainBaseURI_;
    }

    /**
     * @notice Sets the BMP scaleup factor used by the renderer.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setBmpScale(uint32 bmpScale_) external onlyOwner {
        _bmpScale = bmpScale_;
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    /**
     * @notice Wraps the metadata into a Marketplace-conforming JSON dataURI.
     */
    // solhint-disable quotes
    function _wrapMetadata(
        uint256 tokenId,
        bytes memory artwork,
        Attribute[] memory attrs
    ) internal view returns (string memory) {
        string memory tokenIdStr = tokenId.toString();

        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_MB_RES * _bmpScale,
            _NATIVE_MB_RES * _bmpScale
        );

        bytes memory uri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3 +
                1024
        );

        (bool nesting, , ) = _moonbirds.nestingPeriod(tokenId);

        uri.appendSafe('data:application/json;utf-8,{"name":"');
        uri.appendSafe(
            bytes(string.concat("#", tokenIdStr, nesting ? unicode" 🪺" : ""))
        );

        uri.appendSafe('","external_url":"');
        uri.appendSafe(bytes(string.concat(_externalLinkBaseURL, tokenIdStr)));

        uri.appendSafe('","image":"');
        _appendArtworkURI(uri, artwork, _bmpScale);

        uri.appendSafe('","attributes":[');
        uint256 len = attrs.length;
        for (uint256 i; i < len; ++i) {
            if (i != 0) {
                uri.appendSafe('"},');
            }
            uri.appendSafe('{"trait_type": "');
            uri.appendSafe(bytes(attrs[i].name));
            uri.appendSafe('", "value":"');
            uri.appendSafe(bytes(attrs[i].value));
        }
        uri.appendSafe('"}]}');
        return string(uri);
    }

    /**
     * @notice Scales the artwork and appends it as base64-encoded, BMP URI to
     * a given buffer.
     */
    function _appendArtworkURI(
        bytes memory uri,
        bytes memory artwork,
        uint32 scaleupFactor
    ) internal pure {
        uri.appendSafe("data:image/bmp;base64,");

        if (scaleupFactor == 1) {
            // Don't perform any scaling, just write data as-is.
            uri.appendSafeBase64(
                BMP.bmp(artwork, _NATIVE_MB_RES, _NATIVE_MB_RES),
                false,
                false
            );
            return;
        }

        uint256 scaledImageStride = _NATIVE_MB_RES * 3 * scaleupFactor;
        if (scaledImageStride % 4 > 0) {
            // The following is the cleanest and safest way to append the
            // rescaled and Base64-encoded BMP data to the URI buffer.
            // However, this has the downside that we need to keep an
            // additional copy of the resized data in memory for encoding.
            // Since memory related gas costs scale quadratically in allocated
            // size, this can be quite wasteful.
            uri.appendSafeBase64(
                BMP.bmp(
                    Image.scale(artwork, _NATIVE_MB_RES, 3, scaleupFactor),
                    _NATIVE_MB_RES * scaleupFactor,
                    _NATIVE_MB_RES * scaleupFactor
                ),
                false,
                false
            );
        } else {
            // We optimise this by Base64-encoding the pixel data first and
            // apply the rescaling to that instead. This allows us to write the
            // rescaled data directly to the buffer, thus getting rid of the
            // unnecessary intermediate copy of the scaled dataset.
            // This only works if the rescaled image stride is divisible by 4
            // which will therefore not cause any issues with BMP data padding.
            // Further, both the BMP header and the pixel data length needs to
            // be divisible by 3 (always given in our case). This impliess that
            // the Base64-encoding will not be padded, allowing us to
            // concatenate both base64 strings directly.
            uri.appendSafeBase64(
                BMP.header(
                    _NATIVE_MB_RES * scaleupFactor,
                    _NATIVE_MB_RES * scaleupFactor
                ),
                false,
                false
            );
            Image.appendSafeScaled(
                uri,
                bytes(Base64.encode(artwork)),
                _NATIVE_MB_RES,
                4,
                scaleupFactor
            );
        }
    }

    // solhint-enable quotes

    /**
     * @notice Creates the URL of the off-chain renderer for a given Moonbird.
     */
    function _offchainTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return string.concat(_offchainBaseURI, tokenId.toString());
    }
}