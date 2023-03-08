// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "./lib/Bytecode.sol";
import "./lib/DynamicBuffer.sol";
import "./lib/HelperLib.sol";
import "./interfaces/IGame.sol";

contract BanditsRenderer is Ownable, ReentrancyGuard {
    using DynamicBuffer for bytes;
    using HelperLib for uint;

    struct Color {
        string value;
        string name;
    }

    string[] private layerNames = ["Hat","Face","Arms","Torso","Legs","Max Health","Body Color","Hat Color"];
    string[] private positions = ["-32","34","34","0","32","90"];
    string[][8] private values;
    string[] private colors = ["#e60049","#82b6b9","#b3d4ff","#00ffff","#0bb4ff","#1853ff","#35d435","#61ff75","#00bfa0","#ffa300","#fd7f6f","#d0f400","#9b19f5","#dc0ab4","#f46a9b","#bd7ebe","#fdcce5","#FCE74C","#eeeeee","#7f766d"];
    string[] private colorNames = ["UA Red","Pewter Blue","Pale Blue","Aqua","Blue Bolt","Blue RYB","Lime Green","Screamin Green","Caribbean Green","Orange","Coral Reef","Volt","Purple X11","Deep Magenta","Cyclamen","African Violet","Classic Rose","Gargoyle Gas","Bright Gray","Sonic Silver"];

    address public gameContract;

    constructor() {
        values[0] = [unicode"_=_",unicode"_¥_",unicode"_∆_","(_)","\\_/","{_}"];
        values[1] = ["O","()","{}","[]","0","@","G","*","9","Q"];
        values[2] = ["/ \\",unicode"/ √",unicode"∫ \\",unicode"∫ √",unicode"ƒ \\",unicode"ƒ √",unicode"/ ˜",unicode"∫ ˜",unicode"ƒ ˜"];
        values[3] = ["|","!",unicode"†",unicode"¥"];
        values[4] = ["/ \\",unicode"∫ \\",unicode"ƒ \\",unicode"/ †",unicode"∫ †",unicode"ƒ †"];
        values[5] = ["1","2","3","4","5"];
        values[6] = colors;
        values[7] = colors;
    }

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        return _hashToSVG(_hash, 0, true);
    }

    function hashToSVG(string memory _hash, uint tokenId)
        public
        view
        returns (string memory)
    {
        return _hashToSVG(_hash, tokenId, false);
    }

    function _hashToSVG(string memory _hash, uint tokenId, bool ignoreHealth)
        private
        view
        returns (string memory)
    {
        uint traitIndex;
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe('<svg width="800" height="800" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#121212"/><text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="32" text-anchor="middle" letter-spacing="1">');

        uint bodyColorTraitIndex = HelperLib.parseInt(
            HelperLib._substring(_hash, (6 * 3), (6 * 3) + 3)
        );
        uint hatColorTraitIndex = HelperLib.parseInt(
            HelperLib._substring(_hash, (7 * 3), (7 * 3) + 3)
        );
        string memory bodyColor = values[6][bodyColorTraitIndex];
        string memory hatColor = values[7][hatColorTraitIndex];

        for (uint i; i < 6; i++) {
            traitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            if (i < layerNames.length - 3) {
                svgBytes.appendSafe(
                    abi.encodePacked(
                        '<tspan dy="',
                        positions[i],
                        '" x="160" fill="',
                        i == 0 ? hatColor : bodyColor,
                        '">',
                        values[i][traitIndex],
                        '</tspan>'
                    )
                );
            }
            if (i == 3) {
                svgBytes.appendSafe(unicode'<tspan dy="4" dx="-44" x="160" fill="#82b6b9">¬</tspan>');
            }
            if (i == layerNames.length - 3) {
                uint maxHealth = traitIndex + 1;
                uint health = maxHealth;
                if (gameContract != address(0) && !ignoreHealth) {
                    IGame game = IGame(gameContract);
                    health = game.health(tokenId);
                }
                svgBytes.appendSafe('<tspan dy="90" x="160" fill="#d0312d">');
                for (uint hIndex; hIndex < maxHealth; hIndex++) {
                    svgBytes.appendSafe(
                        abi.encodePacked(
                            hIndex == 0 ? "" : " ",
                            hIndex < health ? unicode"♥" : unicode"♡"
                        )
                    );
                }
                svgBytes.appendSafe("</tspan>");
            }
        }

        svgBytes.appendSafe("</text></svg>");

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgBytes)
            )
        );
    }

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");
        bool afterFirstTrait;
        uint traitIndex;

        for (uint i = 0; i < layerNames.length; i++) {
            traitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            if (afterFirstTrait) {
                metadataBytes.appendSafe(",");
            }
            if (i < 6) {
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        layerNames[i],
                        '","value":"',
                        Strings.toString(traitIndex + 1),
                        '"}'
                    )
                );
            } else {
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        layerNames[i],
                        '","value":"',
                        colorNames[traitIndex],
                        '"}'
                    )
                );
            }
            if (afterFirstTrait == false) {
                afterFirstTrait = true;
            }

            if (i == layerNames.length - 1) {
                metadataBytes.appendSafe("]");
            }
        }

        return string(metadataBytes);
    }

    function setGameContract(address contractAddress) external onlyOwner {
        gameContract = contractAddress;
    }
}