// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OnChainTraits} from '../traits/OnChainTraits.sol';
import {svg} from '../SVG.sol';
import {json} from '../lib/JSON.sol';
import {Layerable} from './Layerable.sol';
import {IImageLayerable} from './IImageLayerable.sol';
import {InvalidInitialization} from '../interface/Errors.sol';
import {Attribute} from '../interface/Structs.sol';
import {DisplayType} from '../interface/Enums.sol';
import {Base64} from 'solady/utils/Base64.sol';
import {LibString} from 'solady/utils/LibString.sol';

contract ImageLayerable is Layerable, IImageLayerable {
    // TODO: different strings impl?
    using LibString for uint256;

    string defaultURI;
    string baseLayerURI;

    uint256 width;
    uint256 height;

    string externalUrl;
    string description;

    // TODO: add baseLayerURI
    constructor(
        address _owner,
        string memory _defaultURI,
        uint256 _width,
        uint256 _height,
        string memory _externalUrl,
        string memory _description
    ) Layerable(_owner) {
        _initialize(_defaultURI, _width, _height, _externalUrl, _description);
    }

    function initialize(
        address _owner,
        string memory _defaultURI,
        uint256 _width,
        uint256 _height,
        string memory _externalUrl,
        string memory _description
    ) public virtual {
        super._initialize(_owner);
        _initialize(_defaultURI, _width, _height, _externalUrl, _description);
    }

    function _initialize(
        string memory _defaultURI,
        uint256 _width,
        uint256 _height,
        string memory _externalUrl,
        string memory _description
    ) internal virtual {
        if (address(this).code.length > 0) {
            revert InvalidInitialization();
        }
        defaultURI = _defaultURI;
        width = _width;
        height = _height;
        externalUrl = _externalUrl;
        description = _description;
    }

    function setWidth(uint256 _width) external onlyOwner {
        width = _width;
    }

    function setHeight(uint256 _height) external onlyOwner {
        height = _height;
    }

    /// @notice set the default URI for unrevealed tokens
    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    /// @notice set the base URI for layers
    function setBaseLayerURI(string memory _baseLayerURI) public onlyOwner {
        baseLayerURI = _baseLayerURI;
    }

    /// @notice set the external URL for all tokens
    function setExternalUrl(string memory _externalUrl) public onlyOwner {
        externalUrl = _externalUrl;
    }

    /// @notice set the description for all tokens
    function setDescription(string memory _description) public onlyOwner {
        description = _description;
    }

    /**
     * @notice get the raw URI of a set of token traits, not encoded as a data uri
     * @param layerId the layerId of the base token
     * @param bindings the bitmap of bound traits
     * @param activeLayers packed array of active layerIds as bytes
     * @param layerSeed the random seed for random generation of traits, used to determine if layers have been revealed
     * @return the complete URI of the token, including image and all attributes
     */
    function _getRawTokenJson(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) internal view virtual override returns (string memory) {
        string memory name = _getName(tokenId, layerId, bindings);
        string memory _externalUrl = _getExternalUrl(tokenId, layerId);
        string memory _description = _getDescription(tokenId, layerId);
        // return default uri
        if (layerSeed == 0) {
            return
                _constructJson(
                    name,
                    _externalUrl,
                    _description,
                    getDefaultImageURI(layerId),
                    ''
                );
        }
        // if no bindings, format metadata as an individual NFT
        // check if bindings == 0 or 1; bindable layers will be treated differently
        else if (bindings == 0 || bindings == 1) {
            return _getRawLayerJson(name, _externalUrl, _description, layerId);
        } else {
            return
                _constructJson(
                    name,
                    _externalUrl,
                    _description,
                    getLayeredTokenImageURI(activeLayers),
                    getBoundAndActiveLayerTraits(bindings, activeLayers)
                );
        }
    }

    function _getRawLayerJson(
        string memory name,
        string memory _externalUrl,
        string memory _description,
        uint256 layerId
    ) internal view virtual override returns (string memory) {
        Attribute memory layerTypeAttribute = traitAttributes[layerId];
        layerTypeAttribute.value = layerTypeAttribute.traitType;
        layerTypeAttribute.traitType = 'Layer Type';
        layerTypeAttribute.displayType = DisplayType.String;
        return
            _constructJson(
                name,
                _externalUrl,
                _description,
                getLayerImageURI(layerId),
                json.array(
                    json._commaJoin(
                        _getAttributeJson(layerTypeAttribute),
                        getLayerTraitJson(layerId)
                    )
                )
            );
    }

    function _getName(
        uint256 tokenId,
        uint256,
        uint256
    ) internal view virtual override returns (string memory) {
        return tokenId.toString();
    }

    function _getExternalUrl(uint256, uint256)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return externalUrl;
    }

    function _getDescription(uint256, uint256)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return description;
    }

    /// @notice get the complete SVG for a set of activeLayers
    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory layerImages = '';
        for (uint256 i; i < activeLayers.length; ++i) {
            string memory layerUri = getLayerImageURI(activeLayers[i]);
            layerImages = string.concat(
                layerImages,
                svg.image(
                    layerUri,
                    string.concat(
                        svg.prop('height', '100%'),
                        ' ',
                        svg.prop('width', '100%')
                    )
                )
            );
        }

        return
            string.concat(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            '<svg xmlns="http://www.w3.org/2000/svg" ',
                            svg.prop('height', height.toString()),
                            ' ',
                            svg.prop('width', width.toString()),
                            '>',
                            layerImages,
                            '</svg>'
                        )
                    )
                )
            );
    }

    /// @notice get the image URI for a layerId
    function getLayerImageURI(uint256 layerId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string.concat(baseLayerURI, layerId.toString());
    }

    /// @notice get the default URI for a layerId
    function getDefaultImageURI(uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return defaultURI;
    }

    /// @dev helper to wrap imageURI and optional attributes into a JSON object string
    function _constructJson(
        string memory name,
        string memory _externalUrl,
        string memory _description,
        string memory imageURI,
        string memory attributes
    ) internal pure returns (string memory) {
        string[] memory properties;
        string memory nameProperty = json.property('name', name);
        string memory externalUrlProperty = json.property(
            'external_url',
            _externalUrl
        );
        string memory descriptionProperty = json.property(
            'description',
            _description
        );
        if (bytes(attributes).length > 0) {
            properties = new string[](5);
            properties[0] = nameProperty;
            properties[1] = externalUrlProperty;
            properties[2] = descriptionProperty;
            properties[3] = json.property('image', imageURI);
            // attributes should be a JSON array, no need to wrap it in quotes
            properties[4] = json.rawProperty('attributes', attributes);
        } else {
            properties = new string[](4);
            properties[0] = nameProperty;
            properties[1] = externalUrlProperty;
            properties[2] = descriptionProperty;
            properties[3] = json.property('image', imageURI);
        }
        return json.objectOf(properties);
    }
}