// SPDX-License-Identifier: GPL-3.0

/// @title The Nomo Nouns NFT descriptor. A modified version of the original Nouns descriptor
/// with overrides for the background colors

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity 0.8.15;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {INounsDescriptorV2} from '../nouns-contracts/NounsDescriptorV2/contracts/interfaces/INounsDescriptorV2.sol';
import {INomoNounsSeeder} from './interfaces/INomoNounsSeeder.sol';
import {NomoNFTDescriptor} from "./NomoNFTDescriptor.sol";
import {ISVGRenderer} from '../nouns-contracts/NounsDescriptorV2/contracts/interfaces/ISVGRenderer.sol';
import {INounsArt} from '../nouns-contracts/NounsDescriptorV2/contracts/interfaces/INounsArt.sol';
import {IInflator} from '../nouns-contracts/NounsDescriptorV2/contracts/interfaces/IInflator.sol';
import {INomoNounsDescriptor} from "./interfaces/INomoNounsDescriptor.sol";
import {INomoToNounMapper} from "./interfaces/INomoToNounMapper.sol";

contract NomoNounsDescriptorV2 is INomoNounsDescriptor, Ownable {
    using Strings for uint256;
    using Strings for uint40;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    /// @notice The contract responsible for holding compressed Noun art
    INounsArt public art;

    /// @notice The contract responsible for constructing SVGs
    ISVGRenderer public renderer;

    /// @notice The contract with the mapping of the nounId of each Nomo token
    INomoToNounMapper public nomoToNounMapper;

    /// @notice Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    /// @notice Base URI, used when isDataURIEnabled is false
    string public override baseURI;

    /// @notice Mapping of overrides for background colors
    mapping(uint256 => string) public  backgroundOverrides;

    constructor(INounsArt _art, ISVGRenderer _renderer, INomoToNounMapper _nomoToNounMapper) {
        art = _art;
        renderer = _renderer;
        nomoToNounMapper = _nomoToNounMapper;
    }

    /**
     * @notice Set the Noun's art contract.
     * @dev Only callable by the owner when not locked.
     */
    function setArt(INounsArt _art) external onlyOwner {
        art = _art;

        emit ArtUpdated(_art);
    }

    /**
     * @notice Set the SVG renderer.
     * @dev Only callable by the owner.
     */
    function setRenderer(ISVGRenderer _renderer) external onlyOwner {
        renderer = _renderer;

        emit RendererUpdated(_renderer);
    }

    function setBackgroundOverride(uint256 _index, string calldata _color) external onlyOwner {
        backgroundOverrides[_index] = _color;
    }

    function unsetBackgroundOverride(uint256 _index) external onlyOwner {
        delete backgroundOverrides[_index];
    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return art.backgroundsCount();
    }

    /**
     * @notice Get the number of available Noun `bodies`.
     */
    function bodyCount() external view override returns (uint256) {
        return art.getBodiesTrait().storedImagesCount;
    }

    /**
     * @notice Get the number of available Noun `accessories`.
     */
    function accessoryCount() external view override returns (uint256) {
        return art.getAccessoriesTrait().storedImagesCount;
    }

    /**
     * @notice Get the number of available Noun `heads`.
     */
    function headCount() external view override returns (uint256) {
        return art.getHeadsTrait().storedImagesCount;
    }

    /**
     * @notice Get the number of available Noun `glasses`.
     */
    function glassesCount() external view override returns (uint256) {
        return art.getGlassesTrait().storedImagesCount;
    }

    /**
     * @notice Get a background color by ID.
     * @param index the index of the background.
     * @return string the RGB hex value of the background.
     */
    function backgrounds(uint256 index) public view override returns (string memory) {
        return bytes(backgroundOverrides[index]).length != 0 ? backgroundOverrides[index] : art.backgrounds(index);
    }

    /**
     * @notice Get a head image by ID.
     * @param index the index of the head.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function heads(uint256 index) public view override returns (bytes memory) {
        return art.heads(index);
    }

    /**
     * @notice Get a body image by ID.
     * @param index the index of the body.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function bodies(uint256 index) public view override returns (bytes memory) {
        return art.bodies(index);
    }

    /**
     * @notice Get an accessory image by ID.
     * @param index the index of the accessory.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function accessories(uint256 index) public view override returns (bytes memory) {
        return art.accessories(index);
    }

    /**
     * @notice Get a glasses image by ID.
     * @param index the index of the glasses.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function glasses(uint256 index) public view override returns (bytes memory) {
        return art.glasses(index);
    }

    /**
     * @notice Get a color palette by ID.
     * @param index the index of the palette.
     * @return bytes the palette bytes, where every 3 consecutive bytes represent a color in RGB format.
     */
    function palettes(uint8 index) public view override returns (bytes memory) {
        return art.palettes(index);
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
     * @notice Given a token ID and seed, construct a token URI for an official Nouns DAO noun.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, INomoNounsSeeder.Seed memory seed) external view returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Nouns DAO noun.
     */
    function dataURI(uint256 tokenId, INomoNounsSeeder.Seed memory seed) public view returns (string memory) {

        uint40 nounId = seed.nounId;
        uint256 nomoSerialNumber = getNomoSerialNumber(tokenId, uint256(nounId));
        string memory name = string.concat('Nomo edition ', nounId.toString(), ' #', nomoSerialNumber.toString());
        string memory description = string(abi.encodePacked("They wanted to become a Noun, but now they are No' Mo'"));

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        INomoNounsSeeder.Seed memory seed
    ) public view returns (string memory) {
        NomoNFTDescriptor.TokenURIParams memory params = NomoNFTDescriptor.TokenURIParams({
        name : name,
        nounId : seed.nounId.toString(),
        description : description,
        parts : getPartsForSeed(seed),
        background : backgrounds(seed.background)
        });
        return NomoNFTDescriptor.constructTokenURI(renderer, params);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(INomoNounsSeeder.Seed memory seed) external view returns (string memory) {
        ISVGRenderer.SVGParams memory params = ISVGRenderer.SVGParams({
        parts : getPartsForSeed(seed),
        background : backgrounds(seed.background)
        });
        return NomoNFTDescriptor.generateSVGImage(renderer, params);
    }

    /**
     * @notice Get all Noun parts for the passed `seed`.
     */
    function getPartsForSeed(INomoNounsSeeder.Seed memory seed) public view returns (ISVGRenderer.Part[] memory) {
        bytes memory body = art.bodies(seed.body);
        bytes memory accessory = art.accessories(seed.accessory);
        bytes memory head = art.heads(seed.head);
        bytes memory glasses_ = art.glasses(seed.glasses);

        ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](4);
        parts[0] = ISVGRenderer.Part({image : body, palette : _getPalette(body)});
        parts[1] = ISVGRenderer.Part({image : accessory, palette : _getPalette(accessory)});
        parts[2] = ISVGRenderer.Part({image : head, palette : _getPalette(head)});
        parts[3] = ISVGRenderer.Part({image : glasses_, palette : _getPalette(glasses_)});
        return parts;
    }

    /**
     * @notice Get the color palette pointer for the passed part.
     */
    function _getPalette(bytes memory part) private view returns (bytes memory) {
        return art.palettes(uint8(part[0]));
    }

    /**
     * @notice Get the serial number of a Nomo token.
     */
    function getNomoSerialNumber(uint256 tokenId, uint256 tokenNounId) public view returns (uint256) {
        uint256 count = 1;
        while (nomoToNounMapper.getNounId(tokenId - count) == tokenNounId) {
            count++;
        }

        return count;
    }
}