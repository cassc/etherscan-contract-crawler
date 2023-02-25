// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {INounsSeeder} from "./interfaces/INounsSeeder.sol";
import {MultiPartRLEToSVG} from "./libs/MultiPartRLEToSVG.sol";
import {NounsDescriptorV2} from "./NounsDescriptorV2.sol";
import {ISVGRenderer} from "./interfaces/ISVGRenderer.sol";
import {NFTDescriptorV2} from "./libs/NFTDescriptorV2.sol";

contract NounishBlockies is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    INounsSeeder public immutable seeder = INounsSeeder(0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515);
    NounsDescriptorV2 public immutable descriptor = NounsDescriptorV2(0x6229c811D04501523C6058bfAAc29c91bb586268);

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => INounsSeeder.Seed) public seeds;

    error NoOwner(uint256 tokenId);

    constructor() ERC721("NounishBlockies", "NoBS") {}

    function mint(address _to) public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(_to, tokenId);
        seeds[tokenId] = getSeed(tokenId);
    }

    // Palette Index, Bounds [Top (Y), Right (X), Bottom (Y), Left (X)] (4 Bytes),
    // [Pixel Length (1 Byte), Color Index (1 Byte)][]
    function getHeadImage(address _a) public pure returns (bytes memory) {
        uint8[256] memory imagedata = createImageData(getAddressRandomness(_a));

        bytes memory headImage;

        headImage = bytes.concat(
            abi.encodePacked(uint8(0)), // palette
            abi.encodePacked(uint8(5)), // top
            abi.encodePacked(uint8(24)), // right
            abi.encodePacked(uint8(20)), // bottom
            abi.encodePacked(uint8(8)) // left
        );

        uint8[3] memory colors = createColors(getAddressRandomness(_a));

        for (uint256 i = 0; i < 256; i++) {
            headImage = bytes.concat(headImage, abi.encodePacked(uint8(1)), abi.encodePacked(colors[imagedata[i]]));
        }
        return headImage;
    }

    function renderNounishBlockie(address _a, INounsSeeder.Seed memory _seed) public view returns (string memory) {
        ISVGRenderer.Part[] memory parts;
        string memory background;
        (parts, background) = buildNounishBlockie(_a, _seed);
        ISVGRenderer.SVGParams memory params = ISVGRenderer.SVGParams({parts: parts, background: background});

        string memory image = NFTDescriptorV2.generateSVGImage(descriptor.renderer(), params);
        return string(abi.encodePacked("data:image/svg+xml;base64,", image));
    }

    function buildNounishBlockie(address _a, INounsSeeder.Seed memory seed)
        internal
        view
        returns (ISVGRenderer.Part[] memory, string memory)
    {
        ISVGRenderer.Part[] memory parts = getPartsForSeed(seed);
        bytes memory headImage = getHeadImage(_a);
        parts[2] = ISVGRenderer.Part({image: headImage, palette: descriptor.palettes(uint8(0))});
        return (parts, descriptor.backgrounds(seed.background));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        INounsSeeder.Seed memory seed = seeds[_tokenId];
        address addressToRender = this.ownerOf(_tokenId);

        if (addressToRender == address(0)) {
            revert NoOwner(_tokenId);
        }

        ISVGRenderer.Part[] memory parts;
        string memory background;

        (parts, background) = buildNounishBlockie(addressToRender, seed);
        string memory nounId = _tokenId.toString();
        string memory name = string(abi.encodePacked("Nounish Blockie ", nounId));
        string memory description = string(abi.encodePacked("Noun ", nounId, " is a member of the Nouns Community"));

        NFTDescriptorV2.TokenURIParams memory params =
            NFTDescriptorV2.TokenURIParams({name: name, description: description, parts: parts, background: background});
        return NFTDescriptorV2.constructTokenURI(descriptor.renderer(), params);
    }

    function getHeadSvg(address _a) external view returns (string memory) {
        string memory _SVG_START_TAG =
            '<svg width="160" height="160" viewBox="80 50 160 160" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
        string memory _SVG_END_TAG = "</svg>";

        ISVGRenderer renderer = ISVGRenderer(descriptor.renderer());
        bytes memory headImage = getHeadImage(_a);
        ISVGRenderer.Part memory head = ISVGRenderer.Part({image: headImage, palette: descriptor.palettes(uint8(0))});
        string memory headString = renderer.generateSVGPart(head);

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(abi.encodePacked(_SVG_START_TAG, headString, _SVG_END_TAG)))
            )
        );
    }

    function createColors(bytes32 randomNum) public pure returns (uint8[3] memory) {
        uint8 a;
        uint8 b;
        uint8 c;
        (randomNum, a) = getColor(randomNum);
        (randomNum, b) = getColor(randomNum);
        // naively avoid same colors
        if (a == b) {
            (randomNum, b) = getColor(randomNum);
        }
        (randomNum, c) = getColor(randomNum);
        // naively avoid same colors
        if (a == c || b == c) {
            (randomNum, c) = getColor(randomNum);
        }
        return [a, b, c];
    }

    function getColor(bytes32 randomNum) internal pure returns (bytes32, uint8) {
        randomNum = moreRandom(randomNum);
        // palette length is 239 colors
        return (randomNum, uint8(uint256(randomNum) % 237) + 2); // avoid clear and black
    }

    function createImageData(bytes32 randomNum) internal pure returns (uint8[256] memory) {
        uint8[256] memory data;
        for (uint8 y = 0; y < 16; y++) {
            uint8[8] memory row;
            for (uint8 x = 0; x < 8; x++) {
                // this makes foreground and background color to have a 43% (1/2.3) probability
                // spot color has 13% chance
                randomNum = moreRandom(randomNum);
                uint8 value = uint8(uint256(randomNum) % 100 * 23 / 1000);
                row[x] = value;
                data[y * 16 + x] = value;
            }
            uint8[8] memory r = reverseArray(row);
            for (uint8 i; i < 8; i++) {
                data[y * 16 + i + 8] = r[i];
            }
        }

        return data;
    }

    function reverseArray(uint8[8] memory _array) public pure returns (uint8[8] memory) {
        uint8[8] memory reversedArray;
        uint256 j = 0;
        for (uint8 i = 8; i >= 1; i--) {
            reversedArray[j] = _array[i - 1];
            j++;
        }
        return reversedArray;
    }

    function getSeed(uint256 _num) internal view returns (INounsSeeder.Seed memory) {
        return seeder.generateSeed(_num, descriptor);
    }

    function getPartsForSeed(INounsSeeder.Seed memory seed) internal view returns (ISVGRenderer.Part[] memory) {
        return descriptor.getPartsForSeed(seed);
    }

    function getAddressRandomness(address _a) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_a));
    }

    function moreRandom(bytes32 randomNum) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(randomNum));
    }

    function withdraw() external {
        payable(0xc11996d18998bEB0281DBd52a860214d9d869697).transfer(address(this).balance);
    }

    fallback() external payable {}
    receive() external payable {}
}