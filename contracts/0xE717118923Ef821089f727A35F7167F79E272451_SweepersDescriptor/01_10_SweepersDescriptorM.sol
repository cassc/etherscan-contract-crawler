// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { ISweepersSeeder } from './interfaces/ISweepersSeeder.sol';
import { ISweepersDescriptor } from './interfaces/ISweepersDescriptor.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { MultiPartRLEToSVG } from './libs/MultiPartRLEToSVG.sol';

contract SweepersDescriptor is Ownable {
    using Strings for uint256;

    ISweepersDescriptor private D = ISweepersDescriptor(0x798654cCbdC18b66eEaE893362135A121236D640);

    // Base URI
    string public baseURI = 'https://ipfs.io/ipfs/QmQU2TznaU6yCAKPNS6rVUiqb87ZhgecH9UqSGubSyf5qz';

    // Sweeper Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public palettes;
    bool synced;

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 264, 'Palettes can only hold 265 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    function syncColorsToPalette() external onlyOwner {
        require(!synced);
        for (uint8 i = 0; i <= 255; i++) {
            string memory _color = D.palettes(0, i);
            _addColorToPalette(0, _color);
        }
        for (uint8 i = 0; i <= 36; i++) {
            string memory _color = D.palettes(1, i);
            _addColorToPalette(1, _color);
        }
        for (uint8 i = 0; i <= 36; i++) {
            string memory _color = D.palettes(2, i);
            _addColorToPalette(2, _color);
        }
        for (uint8 i = 0; i <= 37; i++) {
            string memory _color = D.palettes(3, i);
            _addColorToPalette(3, _color);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string memory _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory) {
        return string(abi.encodePacked(baseURI));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Sweepers Treasury sweeper.
     */
    function dataURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) public view returns (string memory) {
        string memory sweeperId = tokenId.toString();
        string memory name = string(abi.encodePacked('Sweeper ', sweeperId));
        string memory description = string(abi.encodePacked('Sweeper ', sweeperId, ' is a member of the Sweepers Treasury'));

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        ISweepersSeeder.Seed memory seed
    ) public view returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            background: D.bgColors(seed.background),
            names: _getAttributesForSeed(seed),
            bgPaletteAdj: D.bgPalette(seed.background)
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Get all Sweeper parts for the passed `seed`.
     */
    function _getPartsForSeed(ISweepersSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](6);
        _parts[0] = D.backgrounds(seed.background);
        _parts[1] = D.bodies(seed.body);
        _parts[2] = D.heads(seed.head);
        _parts[3] = D.accessories(seed.accessory);
        _parts[4] = D.eyes(seed.eyes);
        _parts[5] = D.mouths(seed.mouth);
        return _parts;
    }

    /**
     * @notice Get all Sweeper attributes for the passed `seed`.
     */
    function _getAttributesForSeed(ISweepersSeeder.Seed memory seed) internal view returns (string[] memory) {
        string[] memory _attributes = new string[](6);
        _attributes[0] = D.backgroundNames(seed.background);
        _attributes[1] = D.bodyNames(seed.body);
        _attributes[2] = D.headNames(seed.head);
        _attributes[3] = D.accessoryNames(seed.accessory);
        _attributes[4] = D.eyesNames(seed.eyes);
        _attributes[5] = D.mouthNames(seed.mouth);
        return _attributes;
    }
}