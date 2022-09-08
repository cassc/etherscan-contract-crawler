// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OnChainTraits} from '../traits/OnChainTraits.sol';
import {svg, utils} from '../SVG.sol';
import {RandomTraits} from '../traits/RandomTraits.sol';
import {json} from '../lib/JSON.sol';
import {BitMapUtility} from '../lib/BitMapUtility.sol';
import {PackedByteUtility} from '../lib/PackedByteUtility.sol';
import {ILayerable} from './ILayerable.sol';
import {InvalidInitialization} from '../interface/Errors.sol';

import {Base64} from 'solady/utils/Base64.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {Attribute} from '../interface/Structs.sol';
import {DisplayType} from '../interface/Enums.sol';

abstract contract Layerable is ILayerable, OnChainTraits {
    using BitMapUtility for uint256;
    using LibString for uint256;

    constructor(address _owner) {
        _initialize(_owner);
    }

    function initialize(address _owner) external virtual {
        _initialize(_owner);
    }

    function _initialize(address _owner) internal virtual {
        if (address(this).code.length > 0) {
            revert InvalidInitialization();
        }
        _transferOwnership(_owner);
    }

    /**
     * @notice get the complete URI of a set of token traits, encoded as a data-uri
     * @param layerId the layerId of the base token
     * @param bindings the bitmap of bound traits
     * @param activeLayers packed array of active layerIds as bytes
     * @param layerSeed the random seed for random generation of traits, used to determine if layers have been revealed
     * @return the complete data URI of the token, including image and all attributes
     */
    function getTokenURI(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) public view virtual returns (string memory) {
        // TODO: maybe don't base64 encode? just base64 encode svg?
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        _getRawTokenJson(
                            tokenId,
                            layerId,
                            bindings,
                            activeLayers,
                            layerSeed
                        )
                    )
                )
            );
    }

    function getTokenJson(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) public view virtual returns (string memory) {
        return
            _getRawTokenJson(
                tokenId,
                layerId,
                bindings,
                activeLayers,
                layerSeed
            );
    }

    function getLayerJson(uint256 layerId)
        public
        view
        virtual
        returns (string memory)
    {
        return
            _getRawLayerJson(
                _getName(layerId, layerId, 0),
                _getExternalUrl(layerId, layerId),
                _getDescription(layerId, layerId),
                layerId
            );
    }

    function _getRawTokenJson(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) internal view virtual returns (string memory);

    function _getRawLayerJson(
        string memory name,
        string memory _externalUrl,
        string memory description,
        uint256 layerId
    ) internal view virtual returns (string memory);

    function _getName(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings
    ) internal view virtual returns (string memory);

    function _getExternalUrl(uint256 tokenId, uint256 layerId)
        internal
        view
        virtual
        returns (string memory);

    function _getDescription(uint256 tokenId, uint256 layerId)
        internal
        view
        virtual
        returns (string memory);

    /// @notice get the complete SVG for a set of activeLayers
    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        public
        view
        virtual
        returns (string memory);

    /// @notice get the image URI for a layerId
    function getLayerImageURI(uint256 layerId)
        public
        view
        virtual
        returns (string memory);

    /// @notice get stringified JSON array of bound layer traits
    function getBoundLayerTraits(uint256 bindings)
        public
        view
        returns (string memory)
    {
        return json.arrayOf(_getBoundLayerTraits(bindings & ~uint256(0)));
    }

    /// @notice get stringified JSON array of active layer traits
    function getActiveLayerTraits(uint256[] calldata activeLayers)
        public
        view
        returns (string memory)
    {
        return json.arrayOf(_getActiveLayerTraits(activeLayers));
    }

    /// @notice get stringified JSON array of combined bound and active layer traits
    function getBoundAndActiveLayerTraits(
        uint256 bindings,
        uint256[] calldata activeLayers
    ) public view returns (string memory) {
        string[] memory layerTraits = _getBoundLayerTraits(bindings);
        string[] memory activeLayerTraits = _getActiveLayerTraits(activeLayers);
        return json.arrayOf(layerTraits, activeLayerTraits);
    }

    /// @dev get array of stringified trait json for bindings
    function _getBoundLayerTraits(uint256 bindings)
        internal
        view
        returns (string[] memory layerTraits)
    {
        uint256[] memory boundLayers = BitMapUtility.unpackBitMap(bindings);

        layerTraits = new string[](boundLayers.length + 1);
        for (uint256 i; i < boundLayers.length; ++i) {
            layerTraits[i] = getLayerTraitJson(boundLayers[i]);
        }
        Attribute memory layerCount = Attribute(
            'Layer Count',
            boundLayers.length.toString(),
            DisplayType.Number
        );

        layerTraits[boundLayers.length] = _getAttributeJson(layerCount);
    }

    /// @dev get array of stringified trait json for active layers. Prepends "Active" to trait title.
    // eg 'Background' -> 'Active Background'
    function _getActiveLayerTraits(uint256[] calldata activeLayers)
        internal
        view
        returns (string[] memory activeLayerTraits)
    {
        activeLayerTraits = new string[](activeLayers.length);
        for (uint256 i; i < activeLayers.length; ++i) {
            activeLayerTraits[i] = getLayerTraitJson(activeLayers[i], 'Active');
        }
    }
}