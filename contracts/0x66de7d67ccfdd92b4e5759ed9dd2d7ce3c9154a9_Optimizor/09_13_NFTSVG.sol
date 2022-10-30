// This file is derived from https://github.com/Uniswap/v3-periphery/blob/b771ff9a20a0fd7c3233df0eb70d4fa084766cde/contracts/libraries/NFTSVG.sol

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {Base64} from "src/Base64.sol";
import {HexString} from "src/HexString.sol";

import {LibString} from "solmate/utils/LibString.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    struct SVGParams {
        string projectName;
        string challengeName;
        string solverAddr;
        string challengeAddr;
        uint256 gasUsed;
        uint256 gasOpti;
        uint256 tokenId;
        uint32 rank;
        uint32 participants;
        string color;
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
        uint256 x3;
        uint256 y3;
    }

    function generateSVG(SVGParams memory params, string memory challengeSVG)
        internal
        pure
        returns (string memory svg)
    {
        return string.concat(
            generateSVGDefs(params),
            generateSVGBorderText(params.projectName, params.challengeName, params.solverAddr, params.challengeAddr),
            generateSVGCardMantle(params.challengeName, params.rank, params.participants),
            generateRankBorder(params.rank),
            generateSvgCurve(challengeSVG),
            generateSVGPositionDataAndLocationCurve(LibString.toString(params.tokenId), params.gasUsed, params.gasOpti),
            generateOptimizorIcon(),
            "</svg>"
        );
    }

    function generateSVGDefs(SVGParams memory params) private pure returns (string memory svg) {
        svg = string.concat(
            '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
            "<defs>"
            '<filter id="icon"><feImage result="icon" xlink:href="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTY2LjU5NyIgaGVpZ2h0PSIxMjguOTQxIiB2aWV3Qm94PSIwIDAgNDQuMDc5IDM0LjExNiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMjAuNzkzIDEzLjMyMWgtLjYyM1YxMi43aC02LjIyNXYuNjIyaC42MjJ2LjYyM2gtLjYyMnYuNjIyaC0uNjIzdi0uNjIySDEyLjd2Ni4yMjVoLjYyMnYuNjIzaC42MjN2LjYyMmg2LjIyNXYtLjYyMmguNjIzdi0uNjIzaC42MjJ2LTYuMjI1aC0uNjIyem0tMy43MzUgNS42MDN2LTQuMzU4aDEuODY3djQuMzU4em0xMy42OTgtNi4yMjVoLTYuODQ4di42MjJoLjYyM3YuNjIzaC0uNjIzdi42MjJoLS42MjJ2LS42MjJoLS42MjN2Ni4yMjVoLjYyM3YuNjIzaC42MjJ2LjYyMmg2Ljg0OHYtLjYyMmguNjIydi0xLjI0NWgtLjYyMnYtLjYyM0gyNy4wMnYtNC4zNThoMy43MzV2LS42MjJoLjYyMnYtLjYyM2gtLjYyMnoiIHN0eWxlPSJmaWxsOiM2NjYiLz48L3N2Zz4="/></filter>'
            '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290' height='500' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                        LibString.toString(params.x1),
                        "' cy='",
                        LibString.toString(params.y1),
                        "' r='120' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                        LibString.toString(params.x2),
                        "' cy='",
                        LibString.toString(params.y2),
                        "' r='120' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '" />',
            '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                        LibString.toString(params.x3),
                        "' cy='",
                        LibString.toString(params.y3),
                        "' r='100' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '"/><feBlend mode="overlay" in="p0" in2="p1"/><feBlend mode="exclusion" in2="p2"/><feBlend mode="overlay" in2="p3" result="blendOut"/><feGaussianBlur '
            'in="blendOut" stdDeviation="42"/></filter><clipPath id="corners"><rect width="290" height="500" rx="42" ry="42"/></clipPath>'
            '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z"/>'
            '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463"/>'
            '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24"/></filter>'
            '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="#fff" stop-opacity="1"/>'
            '<stop offset=".9" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="#fff" stop-opacity="1"/><stop offset="0.9" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)"/></mask>'
            '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)"/></mask>'
            '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="#fff"/></mask>'
            '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="#fff" stop-opacity="1"/><stop offset=".95" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290" height="200" fill="url(#grad-symbol)"/></mask></defs>'
            '<g clip-path="url(#corners)">' '<rect fill="',
            params.color,
            '" x="0" y="0" width="290" height="500"/>'
            '<rect style="filter: url(#f1)" x="0" y="0" width="290" height="500"/>'
            '<g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">'
            '<rect fill="none" x="0" y="0" width="290" height="500"/>'
            '<ellipse cx="50%" cy="0" rx="180" ry="120" fill="#000" opacity="0.85"/></g>'
            '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"/></g>'
        );
    }

    function generateSVGBorderText(
        string memory projectName,
        string memory challengeName,
        string memory solverAddr,
        string memory challengeAddr
    ) private pure returns (string memory svg) {
        svg = string.concat(
            '<text text-rendering="optimizeSpeed">'
            '<textPath startOffset="-100%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            challengeName,
            unicode" • ",
            challengeAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>'
            '</textPath> <textPath startOffset="0%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            challengeName,
            unicode" • ",
            challengeAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>'
            '<textPath startOffset="50%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            projectName,
            unicode" • ",
            solverAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"'
            ' repeatCount="indefinite"/></textPath><textPath startOffset="-50%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            projectName,
            unicode" • ",
            solverAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>'
        );
    }

    function generateSVGCardMantle(string memory challengeName, uint32 rank, uint32 participants)
        private
        pure
        returns (string memory svg)
    {
        svg = string.concat(
            '<g mask="url(#fade-symbol)"><rect fill="none" x="0" y="0" width="290" height="200"/><text y="70" x="32" fill="#fff" font-family="\'Courier New\', monospace" font-weight="200" font-size="28px">',
            challengeName,
            '</text><text y="115" x="32" fill="#fff" font-family="\'Courier New\', monospace" font-weight="200" font-size="20px">'
            "Rank ",
            LibString.toString(rank),
            " of ",
            LibString.toString(participants),
            "</text></g>"
        );
    }

    function generateRankBorder(uint32 rank) private pure returns (string memory svg) {
        string memory color;
        if (rank == 1) {
            // Golden accent.
            color = "rgba(255,215,0,1.0)";
        } else if (rank == 2) {
            // Silver accent.
            color = "rgba(255,255,255,1.0)";
        } else if (rank == 3) {
            // Bronze accent.
            color = "rgba(205,127,50,1.0)";
        } else {
            // Default (grey) accent. Assuming rank 0 is invalid, this case is for rank > 3.
            color = "rgba(255,255,255,0.2)";
        }
        svg = string.concat(
            '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="', color, '"/>'
        );
    }

    function generateSvgCurve(string memory challengeSVG) private pure returns (string memory svg) {
        svg = string.concat('<g mask="url(#none)"', ' style="transform:translate(30px,130px)">', challengeSVG, "</g>");
    }

    function generateSVGPositionDataAndLocationCurve(string memory tokenId, uint256 gasUsed, uint256 gasOpti)
        private
        pure
        returns (string memory svg)
    {
        string memory gasUsedStr = LibString.toString(gasUsed);
        string memory gasOptiStr = LibString.toString(gasOpti);
        uint256 str1length = bytes(tokenId).length + 4;
        uint256 str2length = bytes(gasUsedStr).length + 10;
        uint256 str3length = bytes(gasOptiStr).length + 14;
        svg = string.concat(
            '<g font-family="\'Courier New\', monospace" font-size="12" fill="#fff">'
            '<g style="transform:translate(29px, 384px)">' '<rect width="',
            LibString.toString(uint256(7 * (str1length + 4))),
            '" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)"/>' '<text x="12" y="17"><tspan fill="#999">ID: </tspan>',
            tokenId,
            "</text></g>" '<g style="transform:translate(29px, 414px)">' '<rect width="',
            LibString.toString(uint256(7 * (str2length + 4))),
            '" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)"/>'
            '<text x="12" y="17"><tspan fill="#999">Gas used: </tspan>',
            gasUsedStr,
            "</text></g>" '<g style="transform:translate(29px, 444px)">' '<rect width="',
            LibString.toString(uint256(7 * (str3length + 4))),
            '" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)"/>'
            '<text x="12" y="17"><tspan fill="#999">Improvement: </tspan>',
            gasOptiStr,
            "%" "</text></g></g>"
        );
    }

    function generateOptimizorIcon() private pure returns (string memory svg) {
        return
        '<g style="transform:translate(180px, 365px)"><rect style="filter: url(#icon)" x="0" y="0" width="83" height="64"/></g>';
    }

    // This picks a "random number" out of a tokenAddress/offset/tokenId tuple.
    // Assumes offset <= 158.
    function getCircleCoord(address tokenAddress, uint256 offset, uint256 tokenId) internal pure returns (uint8) {
        unchecked {
            // This can wrap around by design.
            return uint8((((uint256(uint160(tokenAddress)) >> offset) & 0xFF) * tokenId) % 255);
        }
    }
}