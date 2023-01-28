// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTime.sol";
import "./FormattedStrings.sol";

/*
    @dev        Library to create SVG image for XENFT metadata
    @dependency depends on DataTime.sol and StringData.sol libraries
 */
library StakeSVG {
    // Type to encode all data params for SVG image generation
    struct SvgParams {
        string symbol;
        address xenAddress;
        uint256 tokenId;
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
        uint256 apy;
        uint256 rarityScore;
        uint256 rarityBits;
    }

    // Type to encode SVG gradient stop color on HSL color scale
    struct Color {
        uint256 h;
        uint256 s;
        uint256 l;
        uint256 a;
        uint256 off;
    }

    // Type to encode SVG gradient
    struct Gradient {
        Color[] colors;
        uint256 id;
        uint256[4] coords;
    }

    using DateTime for uint256;
    using Strings for uint256;
    using FormattedStrings for uint256;
    using Strings for address;

    string private constant _STYLE =
        "<style> "
        ".base {fill: #ededed;font-family:Montserrat,arial,sans-serif;font-size:30px;font-weight:400;} "
        ".series {text-transform: uppercase} "
        ".logo {font-size:200px;font-weight:100;} "
        ".meta {font-size:12px;} "
        ".small {font-size:8px;} "
        ".burn {font-weight:500;font-size:16px;} }"
        "</style>";

    string private constant _STAKE =
        "<g>"
        "<path "
        'stroke="#ededed" '
        'fill="none" '
        'transform="translate(250,379), scale(0.7)" '
        'd="m 0 5 a 5 5 0 0 1 5 -5 l 40 0 a 5 5 0 0 1 5 5 l 0 40 a 5 5 0 0 1 -5 5 l -40 0 a 5 5 0 0 1 -5 -5 l 0 -40z m 25 0 l 20 10 l -20 10 l -20 -10 l 20 -10 m 10 15 l 10 5 l -20 10 l -20 -10 l 10 -5 m 20 10 l 10 5 l -20 10 l -20 -10 l 10 -5"/>'
        "</g>";

    string private constant _LOGO =
        '<path fill="#ededed" '
        'd="M122.7,227.1 l-4.8,0l55.8,-74l0,3.2l-51.8,-69.2l5,0l48.8,65.4l-1.2,0l48.8,-65.4l4.8,0l-51.2,68.4l0,-1.6l55.2,73.2l-5,0l-52.8,-70.2l1.2,0l-52.8,70.2z" '
        'vector-effect="non-scaling-stroke" />';

    /**
        @dev internal helper to create HSL-encoded color prop for SVG tags
     */
    function colorHSL(Color memory c) internal pure returns (bytes memory) {
        return abi.encodePacked("hsl(", c.h.toString(), ", ", c.s.toString(), "%, ", c.l.toString(), "%)");
    }

    /**
        @dev internal helper to create `stop` SVG tag
     */
    function colorStop(Color memory c) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<stop stop-color="',
                colorHSL(c),
                '" stop-opacity="',
                c.a.toString(),
                '" offset="',
                c.off.toString(),
                '%"/>'
            );
    }

    /**
        @dev internal helper to encode position for `Gradient` SVG tag
     */
    function pos(uint256[4] memory coords) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                'x1="',
                coords[0].toString(),
                '%" '
                'y1="',
                coords[1].toString(),
                '%" '
                'x2="',
                coords[2].toString(),
                '%" '
                'y2="',
                coords[3].toString(),
                '%" '
            );
    }

    /**
        @dev internal helper to create `Gradient` SVG tag
     */
    function linearGradient(
        Color[] memory colors,
        uint256 id,
        uint256[4] memory coords
    ) internal pure returns (bytes memory) {
        string memory stops = "";
        for (uint256 i = 0; i < colors.length; i++) {
            if (colors[i].h != 0) {
                stops = string.concat(stops, string(colorStop(colors[i])));
            }
        }
        return
            abi.encodePacked(
                "<linearGradient  ",
                pos(coords),
                'id="g',
                id.toString(),
                '">',
                stops,
                "</linearGradient>"
            );
    }

    /**
        @dev internal helper to create `Defs` SVG tag
     */
    function defs(Gradient memory grad) internal pure returns (bytes memory) {
        return abi.encodePacked("<defs>", linearGradient(grad.colors, 0, grad.coords), "</defs>");
    }

    /**
        @dev internal helper to create `Rect` SVG tag
     */
    function rect(uint256 id) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<rect "
                'width="100%" '
                'height="100%" '
                'fill="url(#g',
                id.toString(),
                ')" '
                'rx="10px" '
                'ry="10px" '
                'stroke-linejoin="round" '
                "/>"
            );
    }

    /**
        @dev internal helper to create border `Rect` SVG tag
     */
    function border() internal pure returns (string memory) {
        return
            "<rect "
            'width="94%" '
            'height="96%" '
            'fill="transparent" '
            'rx="10px" '
            'ry="10px" '
            'stroke-linejoin="round" '
            'x="3%" '
            'y="2%" '
            'stroke-dasharray="1,6" '
            'stroke="white" '
            "/>";
    }

    /**
        @dev internal helper to create group `G` SVG tag
     */
    function g(uint256 gradientsCount) internal pure returns (bytes memory) {
        string memory background = "";
        for (uint256 i = 0; i < gradientsCount; i++) {
            background = string.concat(background, string(rect(i)));
        }
        return abi.encodePacked("<g>", background, border(), "</g>");
    }

    /**
        @dev internal helper to create XEN logo line pattern with 2 SVG `lines`
     */
    function logo() internal pure returns (bytes memory) {
        return abi.encodePacked();
    }

    /**
        @dev internal helper to create `Text` SVG tag with XEN Crypto contract data
     */
    function contractData(string memory symbol, address xenAddress) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<text "
                'x="50%" '
                'y="5%" '
                'class="base small" '
                'dominant-baseline="middle" '
                'text-anchor="middle">',
                symbol,
                unicode"・",
                xenAddress.toHexString(),
                "</text>"
            );
    }

    /**
        @dev internal helper to create 1st part of metadata section of SVG
     */
    function meta1(
        uint256 tokenId,
        uint256 amount,
        uint256 apy,
        uint256 rarityScore
    ) internal pure returns (bytes memory) {
        bytes memory part1 = abi.encodePacked(
            "<text "
            'x="50%" '
            'y="50%" '
            'class="base " '
            'dominant-baseline="middle" '
            'text-anchor="middle">'
            "XEN CRYPTO"
            "</text>"
            "<text "
            'x="50%" '
            'y="56%" '
            'class="base burn" '
            'text-anchor="middle" '
            'dominant-baseline="middle"> ',
            amount > 0 ? string.concat(amount.toFormattedString(), " X") : "",
            "</text>"
            "<text "
            'x="18%" '
            'y="62%" '
            'class="base meta" '
            'dominant-baseline="middle"> '
            "#",
            tokenId.toString(),
            "</text>"
            "<text "
            'x="82%" '
            'y="62%" '
            'class="base meta series" '
            'dominant-baseline="middle" '
            'text-anchor="end" >STAKE</text>'
        );
        bytes memory part2 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="68%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "APY: ",
            apy.toString(),
            "%"
            "</text>"
            "<text "
            'x="18%" '
            'y="72%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Rarity: ",
            rarityScore.toString(),
            "</text>"
        );
        return abi.encodePacked(part1, part2);
    }

    /**
        @dev internal helper to create 2nd part of metadata section of SVG
     */
    function meta2(uint256 term, uint256 maturityTs) internal pure returns (bytes memory) {
        bytes memory part3 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="76%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Term: ",
            term.toString(),
            " days"
            "</text>"
            "<text "
            'x="18%" '
            'y="80%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Maturity: ",
            maturityTs.asString(),
            "</text>"
        );
        return abi.encodePacked(part3);
    }

    /**
        @dev main internal helper to create SVG file representing XENFT
     */
    function image(SvgParams memory params, Gradient[] memory gradients) internal pure returns (bytes memory) {
        string memory mark = _STAKE;
        bytes memory graphics = abi.encodePacked(defs(gradients[0]), _STYLE, g(gradients.length), _LOGO, mark);
        bytes memory metadata = abi.encodePacked(
            contractData(params.symbol, params.xenAddress),
            meta1(params.tokenId, params.amount, params.apy, params.rarityScore),
            meta2(params.term, params.maturityTs)
        );
        return
            abi.encodePacked(
                "<svg "
                'xmlns="http://www.w3.org/2000/svg" '
                'preserveAspectRatio="xMinYMin meet" '
                'viewBox="0 0 350 566">',
                graphics,
                metadata,
                "</svg>"
            );
    }
}