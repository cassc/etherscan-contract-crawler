// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract PosersMeta is Ownable {

    using BytesLib for bytes;

    uint constant private TRAIT_COUNT = 9;
    uint constant private MAX_ASSETS = 44;
    uint32 private EULER = 31;
    string[TRAIT_COUNT] private TRAIT_ORDER = ['type', 'skin', 'outfit', 'eyes', 'hats', 'mouth', 'bg', 'hairstyle', 'accessories'];
    uint8[TRAIT_COUNT] private DRAW_ORDER = [6, 1, 0, 5, 7, 2, 3, 4, 8];

    struct TraitValue {
        string name;
        uint32 weight;
        uint32 tags;
        uint32 antitags;
        uint32 euler;
    }

    struct Trait {
        uint count;
        mapping(uint => TraitValue) items;
    }

    mapping(string => Trait) public traits;
    mapping(string => mapping(string => bytes)) public layers;
    bytes[] public palette;

    function random(uint seed, uint salt) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed, salt)));
    }

    // add colors to palette
    function addPaletteColors(bytes[] calldata _palette) external onlyOwner {
        for (uint i = 0; i < _palette.length; i++) {
            palette.push(_palette[i]);
        }
    }

    // reset palette
    function resetPalette() external onlyOwner {
        delete palette;
    }

    // configure traits svg data
    function setTraitLayers(string calldata trait, string[] calldata traitValues, bytes[] calldata svgData) external onlyOwner {
        require(traitValues.length == svgData.length, "length mismatch");
        for (uint i = 0; i < traitValues.length; i++) {
            layers[trait][traitValues[i]] = svgData[i];
        }
    }

    // set trait value names and on-chain generator settings
    function configureTrait(string calldata trait, string[] calldata names, uint32[] calldata values) external onlyOwner {
        traits[trait].count = names.length;
        uint s = 0;
        for (uint i = 0; i < names.length; i++) {
            TraitValue storage traitValue = traits[trait].items[i];
            traitValue.name = names[i];
            traitValue.weight = values[s++];
            traitValue.tags = values[s++];
            traitValue.antitags = values[s++];
            traitValue.euler = values[s++];
        }
    }

    // base64 encoded meta
    function tokenMeta(uint tokenId, uint tokenSeed) public view returns (string memory){
        bool generated = false;
        string[TRAIT_COUNT] memory traitValues;
        do {
            (generated, traitValues) = selectTraits(tokenSeed);
            tokenSeed = uint(keccak256(abi.encode("Generation retry salt", tokenSeed)));
        }
        while (!generated);

        bytes memory name = abi.encodePacked("poser #", Strings.toString(tokenId));
        bytes memory meta = abi.encodePacked(
            '{"name":"',
            name,
            '", "attributes":',
            attributesToJson(traitValues),
            ',"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(drawSVG(traitValues))),
            '"}'
        );
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(meta)));
    }

    // try to select traits
    function selectTraits(uint seed) internal view returns (bool, string[TRAIT_COUNT] memory) {
        TraitValue memory filter = TraitValue("", 0, 0, 0, EULER);
        string[TRAIT_COUNT] memory character;
        TraitValue[MAX_ASSETS] memory selectedItems;
        TraitValue memory item;

        uint salt = 0;
        for (uint i = 0; i < TRAIT_COUNT; i++) {
            string memory trait = TRAIT_ORDER[i];
            uint selectedCount = 0;
            uint weight = 0;
            for (uint j = 0; j < traits[trait].count; j++) {
                item = traits[trait].items[j];
                if (filter.tags & item.antitags == 0
                    && filter.antitags & item.tags == 0
                    && filter.euler & item.euler != 0
                ) {
                    selectedItems[selectedCount++] = item;
                    weight += item.weight;
                }
            }
            if (selectedCount == 0) {
                return (false, character);
            }

            uint r = random(seed, salt++) % weight;
            selectedCount = 0;
            while (r >= selectedItems[selectedCount].weight) {
                r -= selectedItems[selectedCount++].weight;
            }
            item = selectedItems[selectedCount];
            character[i] = item.name;
            if (i < TRAIT_COUNT - 1) {
                filter.tags |= item.tags;
                filter.antitags |= item.antitags;
                filter.euler &= item.euler;
            }
        }
        return (true, character);
    }

    // delete aux prefix to get correct names
    function withoutAuxiliaryPrefix(bytes memory traitValue) internal pure returns (bytes memory) {
        if (traitValue.length > 2 && traitValue[0] == "_") {
            return traitValue.slice(2, traitValue.length - 2);
        }
        return traitValue;
    }

    // attributes to json array
    function attributesToJson(string[TRAIT_COUNT] memory traitValues) internal view returns (bytes memory) {
        bytes memory buf = "";
        for (uint i = 0; i < TRAIT_COUNT; i++) {
            if (keccak256(bytes(traitValues[i])) == keccak256(bytes("none"))) {
                continue;
            }

            if (i != 0) {
                buf = abi.encodePacked(buf, ',');
            }

            buf = abi.encodePacked(
                buf,
                '{"trait_type":"', TRAIT_ORDER[i], '",',
                '"value":"', withoutAuxiliaryPrefix(bytes(traitValues[i])), '"}'
            );
        }
        return abi.encodePacked("[", buf, "]");
    }

    // get svg image for selectedtrait values
    function drawSVG(string[TRAIT_COUNT] memory traitValues) internal view returns (bytes memory) {
        string memory header = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" preserveAspectRatio="xMinYMin meet">';
        bytes memory buf = "";
        for (uint i = 0; i < TRAIT_COUNT; i++) {
            uint index = DRAW_ORDER[i];
            string memory traitValue = traitValues[index];
            bytes storage traitData = layers[TRAIT_ORDER[index]][traitValue];
            bytes memory svgElem;
            if (i == 0) {
                svgElem = renderGradient(traitData);
            } else {
                svgElem = renderPaths(traitData);
            }
            buf = abi.encodePacked(buf, svgElem);
        }
        return abi.encodePacked(header, buf, "</svg>");
    }

    // render gradient bg
    function renderGradient(bytes storage data) internal view returns (bytes memory) {
        return abi.encodePacked(
            '<defs><radialGradient id="g"><stop offset="5%" stop-color="#',
            palette[uint8(data[0])],
            '"/><stop offset="70%" stop-color="#',
            palette[uint8(data[1])],
            '"/></radialGradient></defs><circle fill="url(#g)" r="24" cx="12" cy="12"/>'
        );
    }

    // render paths
    function renderPaths(bytes storage svgData) internal view returns (bytes memory) {
        uint8 pathsCount = uint8(svgData[0]);
        if (pathsCount == 0) {
            return "";
        }
        bytes memory renderedPath;
        uint i = 1;
        for (uint8 path = 0; path < pathsCount; path++) {
            bytes memory renderedPathPoints;
            uint8 blockCount = uint8(svgData[i++]);
            for (uint8 blokk = 0; blokk < blockCount; blokk++) {
                renderedPathPoints = abi.encodePacked(
                    renderedPathPoints,
                    (blokk == 0) ? "M" : "zM",
                    Strings.toString(uint8(svgData[i++])),
                    " ",
                    Strings.toString(uint8(svgData[i++]))
                );
                uint8 pointCount = uint8(svgData[i++]);
                bool isVertical = uint8(svgData[i++]) == 1;
                for (uint8 point = 0; point < pointCount; point++) {
                    renderedPathPoints = abi.encodePacked(
                        renderedPathPoints,
                        (isVertical) ? "V" : "H",
                        Strings.toString(uint8(svgData[i++]))
                    );
                    isVertical = !isVertical;
                }
            }
            renderedPath = abi.encodePacked(
                renderedPath,
                '<path fill="#', palette[uint8(svgData[i++])],
                '" d="', renderedPathPoints, '"/>'
            );
        }
        return renderedPath;
    }

}