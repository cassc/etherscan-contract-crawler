// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IGnarDescriptorV2} from "../interfaces/IGNARDescriptorV2.sol";
import {IGnarSeederV2} from "../interfaces/IGNARSeederV2.sol";
import {MultiPartRLEToSVG} from "./libs/MultiPartRLEToSVG.sol";
import {IGnarDecorator} from "../interfaces/IGnarDecorator.sol";

contract GNARDescriptorV2 is IGnarDescriptorV2, Ownable {
    using Strings for uint256;

    IGnarDecorator public decorator;

    // Whether or not new Gnar parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // Gnar Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Gnar Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Gnar Bodies (Custom RLE)
    bytes[] public override bodies;

    // Gnar Accessories (Custom RLE)
    bytes[] public override accessories;

    // Gnar Heads (Custom RLE)
    bytes[] public override heads;

    // Gnar Glasses (Custom RLE)
    bytes[] public override glasses;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, "Parts are locked");
        _;
    }

    constructor(IGnarDecorator _decorator) {
        require(address(_decorator) != address(0), "ZERO ADDRESS");

        decorator = _decorator;
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDecorator(IGnarDecorator _decorator) external override onlyOwner {
        require(address(_decorator) != address(0), "ZERO ADDRESS");

        _decorator = _decorator;

        emit DecoratorUpdated(_decorator);
    }

    /**
     * @notice Get the number of available Gnar `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available Gnar `bodies`.
     */
    function bodyCount() external view override returns (uint256) {
        return bodies.length;
    }

    /**
     * @notice Get the number of available Gnar `accessories`.
     */
    function accessoryCount() external view override returns (uint256) {
        return accessories.length;
    }

    /**
     * @notice Get the number of available Gnar `heads`.
     */
    function headCount() external view override returns (uint256) {
        return heads.length;
    }

    /**
     * @notice Get the number of available Gnar `glasses`.
     */
    function glassesCount() external view override returns (uint256) {
        return glasses.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, "Palettes can only hold 256 colors");
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add Gnar backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add Gnar bodies.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBodies(bytes[] calldata _bodies) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _bodies.length; i++) {
            _addBody(_bodies[i]);
        }
    }

    /**
     * @notice Batch add Gnar accessories.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyAccessories(bytes[] calldata _accessories) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addAccessory(_accessories[i]);
        }
    }

    /**
     * @notice Batch add Gnar heads.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHeads(bytes[] calldata _heads) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHead(_heads[i]);
        }
    }

    /**
     * @notice Batch add Gnar glasses.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyGlasses(bytes[] calldata _glasses) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _glasses.length; i++) {
            _addGlasses(_glasses[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external override onlyOwner {
        require(palettes[_paletteIndex].length <= 255, "Palettes can only hold 256 colors");
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a Gnar background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a Gnar body.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBody(bytes calldata _body) external override onlyOwner whenPartsNotLocked {
        _addBody(_body);
    }

    /**
     * @notice Add a Gnar accessory.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessory(bytes calldata _accessory) external override onlyOwner whenPartsNotLocked {
        _addAccessory(_accessory);
    }

    /**
     * @notice Add a Gnar head.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHead(bytes calldata _head) external override onlyOwner whenPartsNotLocked {
        _addHead(_head);
    }

    /**
     * @notice Add Gnar glasses.
     * @dev This function can only be called by the owner when not locked.
     */
    function addGlasses(bytes calldata _glasses) external override onlyOwner whenPartsNotLocked {
        _addGlasses(_glasses);
    }

    /**
     * @notice Lock all Gnar parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Gnars DAO Gnar.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IGnarSeederV2.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Gnars DAO Gnar.
     */
    function dataURI(uint256 tokenId, IGnarSeederV2.Seed memory seed) public view override returns (string memory) {
        string memory gnarId = tokenId.toString();
        string memory name = string(abi.encodePacked("Gnar ", gnarId));
        string memory description = string(abi.encodePacked("Gnar ", gnarId, " both skater and terrain"));

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IGnarSeederV2.Seed memory seed
    ) public view override returns (string memory) {
        string memory attributes = generateAttributesList(seed);
        string memory image = _generateSVGImage(
            MultiPartRLEToSVG.SVGParams({parts: _getPartsForSeed(seed), background: backgrounds[seed.background]})
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
													'{"name":"', name,
													'", "description":"', description,
													'", "attributes": [', attributes,
													'], "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    function generateAttributesList(IGnarSeederV2.Seed memory seed) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Background","value":"',
                    decorator.backgrounds(seed.background),
                    '"},',
                    '{"trait_type":"Body","value":"',
                    decorator.bodies(seed.body),
                    '"},',
                    '{"trait_type":"Accessory","value":"',
                    decorator.accessories(seed.accessory),
                    '"},',
                    '{"trait_type":"Head","value":"',
                    decorator.heads(seed.head),
                    '"},',
                    '{"trait_type":"Glasses","value":"',
                    decorator.glasses(seed.glasses),
                    '"}'
                )
            );
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IGnarSeederV2.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return _generateSVGImage(params);
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function _generateSVGImage(MultiPartRLEToSVG.SVGParams memory params) public view returns (string memory svg) {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a Gnar background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a Gnar body.
     */
    function _addBody(bytes calldata _body) internal {
        bodies.push(_body);
    }

    /**
     * @notice Add a Gnar accessory.
     */
    function _addAccessory(bytes calldata _accessory) internal {
        accessories.push(_accessory);
    }

    /**
     * @notice Add a Gnar head.
     */
    function _addHead(bytes calldata _head) internal {
        heads.push(_head);
    }

    /**
     * @notice Add Gnar glasses.
     */
    function _addGlasses(bytes calldata _glasses) internal {
        glasses.push(_glasses);
    }

    /**
     * @notice Get all Gnar parts for the passed `seed`.
     */
    function _getPartsForSeed(IGnarSeederV2.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](4);
        _parts[0] = bodies[seed.body];
        _parts[1] = accessories[seed.accessory];
        _parts[2] = heads[seed.head];
        _parts[3] = glasses[seed.glasses];
        return _parts;
    }
}