// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Trigonometry} from "./Trigonometry.sol";
import {IRenderer} from "./IRenderer.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract Renderer is IRenderer {
    using Strings for uint256;
    using Strings for int256;
    using Strings for uint8;

    constructor() {}

    function generateSpiroData(
        uint256 seed
    ) internal pure returns (IRenderer.SpiroData memory) {
        uint8 points = uint8((seed >> 2) % 100) + 50;
        uint8 wheelSize1 = uint8((seed >> 10) % 100) + 10;
        uint8 wheelRate1 = uint8((seed >> 18) % 100) + 10;
        uint8 wheelSize2 = uint8((seed >> 26) % 100) + 10;
        uint8 wheelRate2 = uint8((seed >> 34) % 100) + 10;
        uint8 colorId = uint8((seed >> 42) % 21);
        (string memory colorName, string memory colorValue) = getColor(colorId);

        return
            IRenderer.SpiroData({
                points: points,
                wheelSize1: wheelSize1,
                wheelRate1: wheelRate1,
                wheelSize2: wheelSize2,
                wheelRate2: wheelRate2,
                colorName: colorName,
                colorValue: colorValue
            });
    }

    function tokenURI(
        uint256 tokenId,
        uint256 seed
    ) external pure returns (string memory) {
        SpiroData memory spiroData = generateSpiroData(seed);
        string memory imageSvg = renderSpiro(spiroData);

        string memory name = string.concat("Spirax #", tokenId.toString());
        string memory attributes = string.concat(
            '[{"trait_type":"Points","value":"',
            spiroData.points.toString(),
            '"},',
            '{"trait_type":"Color","value":"',
            spiroData.colorName,
            '"},',
            '{"trait_type":"Wheel Size 1","value":"',
            spiroData.wheelSize1.toString(),
            '"},',
            '{"trait_type":"Wheel Size 2","value":"',
            spiroData.wheelSize2.toString(),
            '"},',
            '{"trait_type":"Wheel Rate 1","value":"',
            spiroData.wheelRate1.toString(),
            '"},',
            '{"trait_type":"Wheel Rate 2","value":"',
            spiroData.wheelRate2.toString(),
            '"}]'
        );

        string memory meta = string.concat(
            '{"name":"',
            name,
            '",',
            '"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(abi.encodePacked(imageSvg))),
            '",',
            '"attributes":',
            attributes,
            "}"
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked(meta)))
            );
    }

    function getColor(
        uint8 colorId
    ) public pure returns (string memory, string memory) {
        string[21] memory colorNames = [
            "Sunrise",
            "Lagoon",
            "Lilac",
            "Scarlet",
            "Glacier",
            "Butterfly",
            "Emerald",
            "Opal",
            "Zest",
            "Tangerine",
            "Raspberry",
            "White",
            "Peach",
            "Firefly",
            "Azure",
            "Rose",
            "Tidal",
            "Pumpkin",
            "Lavender",
            "Pistachio",
            "Cherry"
        ];

        string[21] memory colorValues = [
            "#FF4500",
            "#48D1CC",
            "#C8A2C8",
            "#DC143C",
            "#AFEEEE",
            "#9966CC",
            "#3CB371",
            "#FF6FFF",
            "#FFF44F",
            "#FF4500",
            "#E30B5D",
            "#fff",
            "#FFDAB9",
            "#EEDD82",
            "#007FFF",
            "#FF0090",
            "#008080",
            "#FF7518",
            "#B57EDC",
            "#93C572",
            "#FFB7C5"
        ];

        return (colorNames[colorId], colorValues[colorId]);
    }

    function renderSpiro(
        SpiroData memory spiroData
    ) public pure returns (string memory) {
        string memory imagePolygon = renderPolygons(spiroData);
        string memory imageSvg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="500" height="500" viewBox="-250,-250,500,500"><rect x="-250" y="-250" width="500" height="500" fill="black" />',
            imagePolygon,
            "</svg>"
        );
        return imageSvg;
    }

    function renderPolygons(
        SpiroData memory spiroData
    ) internal pure returns (string memory) {
        string memory svg = "";
        int256 size1 = int256(uint256(spiroData.wheelSize1));
        int256 size2 = int256(uint256(spiroData.wheelSize2));

        int256 wheelSizeSum = size1 + size2;
        int256 factor = (1e18 / wheelSizeSum) * 200;
        uint256 k = Trigonometry.TWO_PI / spiroData.points;
        for (uint8 i = 0; i < spiroData.points; i++) {
            uint256 a = i * k;
            uint256 a2 = a * spiroData.wheelRate1;
            uint256 a3 = a * spiroData.wheelRate2;
            int256 x = size1 * Trigonometry.sin(a2) + size2 * Trigonometry.sin(a3);
            int256 y = size1 * Trigonometry.cos(a2) + size2 * Trigonometry.cos(a3);
            x = x * factor / 1e36;
            y = y * factor / 1e36;
            svg = string.concat(svg, x.toString(), ",", y.toString(), " ");
        }

        string memory image = string.concat(
            '<polygon points="',
            svg,
            '" style="stroke-width:1; fill:none; stroke:',
            spiroData.colorValue,
            ';" />'
        );
        return image;
    }
}