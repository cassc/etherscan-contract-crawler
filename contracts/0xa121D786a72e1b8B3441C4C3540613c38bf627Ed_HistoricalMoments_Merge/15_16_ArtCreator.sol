// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

abstract contract ArtCreator {
    using Strings for string;

    struct colorHSL {
        uint8 h;
        uint8 s;
        uint8 l;
    }

    struct iconStyle {
        string fillTl;
        string fillTr;
        string fillMl;
        string fillMr;
        string fillBl;
        string fillBr;
        string stroke;
        uint8 strokeWidth;
    }

    struct svgStyle {
        colorHSL baseColor;
        colorHSL textColorStart;
        colorHSL textColorEnd;
        bool motion;
        iconStyle iconstyle;
    }

    /***************
     * Main Methods *
     ***************/

    function generateMetadata(uint256 tokenId, uint256 MAX_TOKENS) internal view virtual returns (string memory) {
        svgStyle memory style = getStyles(tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Historical Moments: The Merge - Token',
                                " #",
                                Strings.toString(tokenId),
                                '", "description":"',
                                "The Merge has been activated! This generative art project, inspired by others, is entirely generated on chain.",
                                '", "attributes":[',
                                getTraitsString(style),
                                '], "image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(bytes(generateSVG(tokenId, MAX_TOKENS, style))),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVG(
        uint256 tokenId,
        uint256 MAX_TOKENS,
        svgStyle memory style
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" ',
                    ' style="background:linear-gradient(to bottom, ',
                    hslToString(style.baseColor),
                    ", ",
                    hslToString(style.baseColor),
                    ')" ',
                    ' id="Layer_1" x="0px" y="0px" viewBox="0 0 500 500" width="500" height="500" ',
                    ' xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    "<defs>",
                    '    <linearGradient id="textGrad" x1="0" y1="0" x2="0" y2="100%">',
                    '        <stop offset="0%" stop-color="',
                    hslToString(style.textColorStart),
                    '" />',
                    '        <stop offset="100%" stop-color="',
                    hslToString(style.textColorEnd),
                    '" />',
                    "    </linearGradient>",
                    "</defs>",
                    generateTextDifficulty(),
                    style.motion ? generateEthIconAnimated(style) : generateEthIconStill(style),
                    generateTextOneOf(tokenId, MAX_TOKENS),
                    "</svg>"
                )
            );
    }

    function generateEthIconAnimated(svgStyle memory style) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g transform="matrix(.74 0 0 0.74 154 93)" opacity=".5" stroke="',
                    style.iconstyle.stroke,
                    '" stroke-width="',
                    Strings.toString(style.iconstyle.strokeWidth),
                    '">',
                    '  <animate attributeName="opacity" from="0.5" to="0.95" begin="0s" dur="10s" fill="freeze" />',
                    '  <polygon points="127,0 125,9.5 125,285 127,287 255,212" fill="',
                    style.iconstyle.fillTr,
                    '">',
                    '    <animateTransform id="tr" attributeName="transform" type="translate" from="200 -50" to="0 0" begin="0s;tr.end+5s" dur="5s" />',
                    "  </polygon>",
                    '  <polygon points="127,0 0,212 127,287 127,154" fill="',
                    style.iconstyle.fillTl,
                    '">',
                    '    <animateTransform id="tl" attributeName="transform" type="translate" from="-140 -100" to="0 0" begin="0s;tl.end+5s" dur="5s" />',
                    "  </polygon>",
                    '  <polygon points="127,287 255,212 127,154" fill="',
                    style.iconstyle.fillMr,
                    '">',
                    '    <animateTransform id="mr" attributeName="transform" type="translate" from="100 50" to="0 0" begin="0s;mr.end+5s" dur="5s" />',
                    "  </polygon>",
                    '  <polygon points="0,212 127,287 127,154" fill="',
                    style.iconstyle.fillMl,
                    '">',
                    '    <animateTransform id="ml" attributeName="transform" type="translate" from="-120 60" to="0 0" begin="0s;ml.end+5s" dur="5s" />',
                    "  </polygon>",
                    '  <polygon points="127,312 126,314 126,412 127,416 255,236" fill="',
                    style.iconstyle.fillBr,
                    '">',
                    '    <animateTransform id="br" attributeName="transform" type="translate" from="150 150" to="0 0" begin="0s;br.end+5s" dur="5s" />',
                    "  </polygon>",
                    '  <polygon points="127,416 127,312 0,236" fill="',
                    style.iconstyle.fillBl,
                    '">',
                    '    <animateTransform id="bl" attributeName="transform" type="translate" from="-150 120" to="0 0" begin="0s;bl.end+5s" dur="5s"  />',
                    "  </polygon>",
                    "</g>"
                )
            );
    }

    function generateEthIconStill(svgStyle memory style) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g transform="matrix(.74 0 0 0.74 154 93)" opacity=".95" stroke="',
                    style.iconstyle.stroke,
                    '" stroke-width="',
                    Strings.toString(style.iconstyle.strokeWidth),
                    '">',
                    '  <polygon points="127,0 125,9.5 125,285 127,287 255,212" fill="',
                    style.iconstyle.fillTr,
                    '">',
                    "  </polygon>",
                    '  <polygon points="127,0 0,212 127,287 127,154" fill="',
                    style.iconstyle.fillTl,
                    '">',
                    "  </polygon>",
                    '  <polygon points="127,287 255,212 127,154" fill="',
                    style.iconstyle.fillMr,
                    '">',
                    "  </polygon>",
                    '  <polygon points="0,212 127,287 127,154" fill="',
                    style.iconstyle.fillMl,
                    '">',
                    "  </polygon>",
                    '  <polygon points="127,312 126,314 126,412 127,416 255,236" fill="',
                    style.iconstyle.fillBr,
                    '">',
                    "  </polygon>",
                    '  <polygon points="127,416 127,312 0,236" fill="',
                    style.iconstyle.fillBl,
                    '">',
                    "  </polygon>",
                    "</g>"
                )
            );
    }

    function generateTextDifficulty() internal pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text fill="url(#textGrad)" ',
                    ' fill-opacity="0.8" font-size="100" letter-spacing="10" transform="translate(75 139)">',
                    '    <tspan y="0">587500</tspan>',
                    '    <tspan x="0" y="100">000000</tspan>',
                    '    <tspan x="0" y="200">000000</tspan>',
                    '    <tspan x="30" y="300">00000</tspan>',
                    "</text>"
                )
            );
    }

    function generateTextOneOf(uint256 tokenId, uint256 MAX_TOKENS) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text dx="0" dy="0" font-size="12" dominant-baseline="middle" text-anchor="middle" transform="translate(250 480)" fill="#fff" stroke-width="0" opacity=".6">',
                    "  <![CDATA[#",
                    Strings.toString(tokenId),
                    " / ",
                    Strings.toString(MAX_TOKENS),
                    " ]]>",
                    "</text>"
                )
            );
    }

    /***************
     * Helpers *
     ***************/

    function getTraitsString(svgStyle memory style) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Base Color", "value": "',
                    getColorNameFromHsl(style.baseColor),
                    '"},',
                    '{"trait_type": "ETH Icon Color", "value": "',
                    (keccak256(bytes(style.iconstyle.fillTl)) == keccak256(bytes("#FFE94D")) ? "Rainbow" : "Grey"),
                    '"},',
                    '{"trait_type": "Motion", "value": "',
                    style.motion ? "Yes" : "No",
                    '"},',
                    '{"trait_type": "Gradient", "value": "',
                    (style.textColorStart.h != style.textColorEnd.h) ? "Yes" : "No",
                    '"}'
                )
            );
    }

    function getStyles(uint256 seed) internal view virtual returns (svgStyle memory) {
        uint8 baseH = uint8(randNum(6, 360, seed++));
        uint8 baseS = uint8(randNum(20, 85, seed++));
        uint8 baseL = uint8(randNum(45, 95, seed++));
        iconStyle memory iconstyle;

        colorHSL memory baseColor = colorHSL(baseH, baseS, baseL);
        colorHSL memory textColorStart = colorHSL(baseH, baseS, 30);
        colorHSL memory textColorEnd = colorHSL(baseH, baseS, ((baseL <= 35) ? 50 : 30));
        // iconStyle memory iconStyleBlack = iconStyle("#000", "#000", "#000", "#000", "#000", "#000", "#000", 1);
        // iconStyle memory iconStyleGrey = iconStyle('#8C8C8C', '#333333', '#383838', '#141414', '#8C8C8C', '#333333', "#000", 1);
        if (baseH % 10 == 1) {
            // rainbow - 10%
            iconstyle = iconStyle("#FFE94D", "#FF9C92", "#88D848", "#CC71C2", "#53D3E0", "#5A9DED", "#000", 1);
        } else {
            // grey
            iconstyle = iconStyle("#8C8C8C", "#333333", "#383838", "#141414", "#8C8C8C", "#333333", "#000", 1);
        }
        bool motion = (baseH <= 231); // ~65% get motion

        svgStyle memory style = svgStyle(baseColor, textColorStart, textColorEnd, motion, iconstyle);
        return style;
    }

    function getColorNameFromHsl(colorHSL memory hsl) private pure returns (string memory) {
        if (hsl.h >= 170 && hsl.h <= 190 && hsl.s >= 75 && hsl.s <= 85 && hsl.l >= 80 && hsl.l <= 95) {
            return "Alien Blue";
        } else if (
            (hsl.h >= 80 && hsl.h <= 85 && hsl.s >= 25 && hsl.s <= 35 && hsl.l >= 40 && hsl.l <= 50) ||
            (hsl.h >= 100 && hsl.h <= 105 && hsl.s >= 40 && hsl.s <= 50 && hsl.l >= 58 && hsl.l <= 63)
        ) {
            return "Zombie Green";
        } else if (hsl.h >= 36 && hsl.h <= 38 && hsl.s >= 65 && hsl.s <= 80 && hsl.l >= 45 && hsl.l <= 48) {
            return "Ape Brown";
        } else if (hsl.s <= 10 && hsl.l >= 90) {
            return "White";
        } else if (hsl.l <= 15) {
            return "Black";
        } else if ((hsl.s <= 10 && hsl.l <= 70) || hsl.s == 0) {
            return "Gray";
        } else if ((hsl.h >= 0 && hsl.h <= 16) || hsl.h >= 346) {
            return "Red";
        } else if (hsl.h >= 17 && hsl.h <= 35) {
            if (hsl.s < 40) {
                return "Brown";
            } else {
                return "Orange";
            }
        } else if (hsl.h >= 36 && hsl.h <= 63) {
            if (hsl.s <= 50) {
                return "Brown";
            } else {
                return "Yellow";
            }
        } else if (hsl.h >= 55 && hsl.h <= 165) {
            return "Green";
        } else if (hsl.h >= 166 && hsl.h <= 260) {
            if (hsl.s >= 29) {
                return "Blue";
            } else {
                return "Purple";
            }
        } else if (hsl.h >= 250 && hsl.h <= 290) {
            return "Purple";
        } else if (hsl.h >= 291 && hsl.h <= 345) {
            return "Pink";
        } else {
            return "Unknown";
        }
    }

    function hslToString(colorHSL memory hsl) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "hsl(",
                    Strings.toString(hsl.h),
                    ", ",
                    Strings.toString(hsl.s),
                    "%, ",
                    Strings.toString(hsl.l),
                    "%)"
                )
            );
    }

    function randNum(
        uint256 min,
        uint256 max,
        uint256 seed
    ) private pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(seed))) % (max - min)) + min;
    }
}