//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {INounsSeeder} from "./interfaces/INounsSeeder.sol";
import {INounsDescriptor} from "./interfaces/INounsDescriptor.sol";

contract FarCarte is ERC721Enumerable {
    struct Profile {
        string l1;
        string l2;
        string l3;
        string name;
        string location;
        string externalURL;
    }

    // The Nouns token seeder
    INounsSeeder public seeder;

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // User -> Token lookup
    mapping(address => uint256) public tokenOf;

    // True if metadata is stored on-chain
    mapping(uint256 => bool) public onChain;

    mapping(uint256 => Profile) public data;

    // Id for minted token
    uint256 public nextTokenId = 1;

    constructor(INounsSeeder _seeder, INounsDescriptor _descriptor)
        ERC721("FarCarte", "FC")
    {
        seeder = _seeder;
        descriptor = _descriptor;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (onChain[tokenId]) {
            Profile memory p = data[tokenId];
            string memory json = Base64.encode(
                abi.encodePacked(
                    '{"name":"',
                    p.name,
                    '", "external_url":"',
                    p.externalURL,
                    '", "image": "data:image/svg+xml;base64,',
                    getImage(tokenId, p.location, p.l1, p.l2, p.l3),
                    '", "attributes": [{"trait_type": "location", "value": "',
                    p.location,
                    '"}]}'
                )
            );
            return
                string(abi.encodePacked("data:application/json;base64,", json));
        } else {
            return
                string(
                    abi.encodePacked(
                        "https://farcarte.xyz/nfts/",
                        Strings.toString(tokenId)
                    )
                );
        }
    }

    function setOnChainData(Profile memory p) public {
        uint256 tokenId = tokenOf[msg.sender];
        require(tokenId != 0, "No token.");
        data[tokenId] = p;
    }

    function setOnChainState(bool isOnChain) public {
        uint256 tokenId = tokenOf[msg.sender];
        require(tokenId != 0, "No token.");
        onChain[tokenId] = isOnChain;
    }

    function notify() public {
        uint256 tokenId = tokenOf[msg.sender];
        require(tokenId != 0, "No token.");
        emit Transfer(address(0), msg.sender, tokenId);
    }

    function mint() public {
        require(tokenOf[msg.sender] == 0, "Already minted.");
        _safeMint(msg.sender, nextTokenId);
        tokenOf[msg.sender] = nextTokenId;
        seeds[nextTokenId] = seeder.generateSeed(nextTokenId, descriptor);
        nextTokenId += 1;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 /*tokenId*/
    ) internal pure override {
        // allows mints + burns
        // from == 0 -> mint
        // to == 0 -> burn
        assert(from == address(0) || to == address(0));
    }

    function getImage(
        uint256 tokenId,
        string memory location,
        string memory l1,
        string memory l2,
        string memory l3
    ) public view returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg"><style>.t {font: 40px futura} .l {font: italic  60px futura} svg {background-color: #E6E6E6}</style>',
                    '<text x="50%" y="33%" class="l" dominant-baseline="middle" text-anchor="middle">',
                    unicode"📍",
                    location,
                    '</text><image x="0" y="400" height="400" width="400" href="data:image/svg+xml;base64,',
                    getNoun(tokenId),
                    '"/>',
                    getBubble(),
                    '<text x="440" y="560" class="t">',
                    l1,
                    "</text>",
                    '<text x="440" y="620" class="t">',
                    l2,
                    "</text>",
                    '<text x="440" y="680" class="t">',
                    l3,
                    "</text></svg>"
                )
            );
    }

    function getNoun(uint256 tokenId) public view returns (string memory) {
        return dropSvgBackground(descriptor.generateSVGImage(seeds[tokenId]));
    }

    function dropSvgBackground(string memory b64Svg)
        public
        pure
        returns (string memory)
    {
        bytes memory svgRaw = Base64.decode(b64Svg);
        bytes memory svgTransparent = new bytes(svgRaw.length - 166);
        for (uint256 i = 166; i < svgRaw.length; i++) {
            svgTransparent[i - 166] = svgRaw[i];
        }
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                    string(svgTransparent)
                )
            );
    }

    function getBubble() public pure returns (string memory) {
        return
            '<rect width="15" height="15" x="415" y="495" fill="#000"></rect><rect width="15" height="15" x="760" y="495" fill="#000"></rect><rect width="15" height="210" x="400" y="510" fill="#000"></rect><rect width="15" height="210" x="775" y="510" fill="#000"></rect><rect width="15" height="30" x="415" y="720" fill="#000"></rect><rect width="15" height="30" x="475" y="720" fill="#000"></rect><rect width="15" height="15" x="760" y="705" fill="#000"></rect><rect width="15" height="30" x="400" y="750" fill="#000"></rect><rect width="30" height="15" x="445" y="750" fill="#000"></rect><rect width="30" height="15" x="415" y="765" fill="#000"></rect><rect width="300" height="15" x="475" y="720" fill="#000"></rect><rect width="330" height="15" x="430" y="480" fill="#000"></rect><rect width="330" height="30" x="430" y="495" fill="#fff"></rect><rect width="360" height="210" x="415" y="510" fill="#fff"></rect><rect width="45" height="50" x="430" y="700" fill="#fff"></rect><rect width="30" height="15" x="415" y="750" fill="#fff"></rect>';
    }
}