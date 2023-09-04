//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library CourageSvgs {
    using Strings for uint8;
    using Strings for uint16;

    struct CircleProps {
        uint16 cx;
        uint16 cy;
        uint8 r;
        string fill;
    }

    function generateSvg(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg width="350" height="350" viewbox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">\n'
                    '  <filter id="neon">\n'
                    '    <feFlood flood-color="#FFD54F" flood-opacity="0.5" in="SourceGraphic" />\n'
                    '    <feComposite operator="in" in2="SourceGraphic" />\n'
                    '    <feGaussianBlur stdDeviation="5" />\n'
                    '    <feComponentTransfer result="glow1">\n'
                    '      <feFuncA type="linear" slope="4" intercept="0" />\n'
                    "    </feComponentTransfer>\n"
                    "    <feMerge>\n"
                    '      <feMergeNode in="glow1" />\n'
                    '      <feMergeNode in="SourceGraphic" />\n'
                    "    </feMerge>\n"
                    "  </filter>\n"
                    '  <rect width="100%" height="100%" fill="#182026" />\n',
                    generateCircles(tokenId),
                    "</svg>\n"
                )
            );
    }

    function generateCircles(uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        CircleProps[8] memory circles;
        for (uint8 i = 0; i < 8; i++) {
            circles[i] = readCircleProps(tokenId, i);
        }
        // Use separate functions for under- and overlay to dodge "stack too
        // deep" error.
        return
            string(
                abi.encodePacked(
                    generateUnderlayCircles(circles),
                    generateOverlayCircles(circles)
                )
            );
    }

    function generateUnderlayCircles(CircleProps[8] memory circles)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    generateCircle(circles[0], false),
                    generateCircle(circles[1], false),
                    generateCircle(circles[2], false),
                    generateCircle(circles[3], false),
                    generateCircle(circles[4], false),
                    generateCircle(circles[5], false),
                    generateCircle(circles[6], false),
                    generateCircle(circles[7], false)
                )
            );
    }

    function generateOverlayCircles(CircleProps[8] memory circles)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    generateCircle(circles[7], true),
                    generateCircle(circles[6], true),
                    generateCircle(circles[5], true),
                    generateCircle(circles[4], true),
                    generateCircle(circles[3], true),
                    generateCircle(circles[2], true),
                    generateCircle(circles[1], true),
                    generateCircle(circles[0], true)
                )
            );
    }

    function generateCircle(CircleProps memory circle, bool isOverlay)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '  <circle cx="',
                    circle.cx.toString(),
                    '" cy="',
                    circle.cy.toString(),
                    '" r="',
                    circle.r.toString(),
                    '" fill="',
                    circle.fill,
                    '" ',
                    isOverlay ? 'filter="url(#neon)" opacity="0.5" ' : "",
                    "/>\n"
                )
            );
    }

    function readCircleProps(uint256 tokenId, uint8 circleIndex)
        private
        pure
        returns (CircleProps memory)
    {
        uint8 start = 20 * circleIndex;
        // Nudges based on circleIndex ensure all images are distinct: we won't
        // get duplicates by reordering circles.
        uint8 cxNudge = circleIndex & 3;
        uint8 cyNudge = circleIndex >> 1;
        return
            CircleProps({
                cx: readPosition(tokenId, start) + cxNudge,
                cy: readPosition(tokenId, start + 6) + cyNudge,
                r: readRadius(tokenId, start),
                fill: readFill(tokenId, start)
            });
    }

    function readPosition(uint256 tokenId, uint8 start)
        private
        pure
        returns (uint16)
    {
        return 15 + 5 * uint16(readBits(tokenId, start, 6));
    }

    function readRadius(uint256 tokenId, uint8 circleStart)
        private
        pure
        returns (uint8)
    {
        uint8 index = uint8(readBits(tokenId, circleStart + 12, 4));
        if (index < 8) {
            // 30,31,...,37
            return 30 + index;
        } else if (index < 14) {
            // 60,63,...,75
            return 36 + 3 * index;
        } else if (index == 14) {
            return 120;
        } else {
            return 150;
        }
    }

    function readFill(uint256 tokenId, uint8 circleStart)
        private
        pure
        returns (string memory)
    {
        uint256 index = readBits(tokenId, circleStart + 16, 4);
        if (index == 0) {
            return "#D32F2F";
        } else if (index == 1) {
            return "#D81B60";
        } else if (index == 2) {
            return "#AB47BC";
        } else if (index == 3) {
            return "#7B1FA2";
        } else if (index == 4) {
            return "#7E57C2";
        } else if (index == 5) {
            return "#512DA8";
        } else if (index == 6) {
            return "#5C6BC0";
        } else if (index == 7) {
            return "#303F9F";
        } else if (index == 8) {
            return "#1976D2";
        } else if (index == 9) {
            return "#0277BD";
        } else if (index == 10) {
            return "#006064";
        } else if (index == 11) {
            return "#00796B";
        } else if (index == 12) {
            return "#2E7D32";
        } else if (index == 13) {
            return "#33691E";
        } else if (index == 14) {
            return "#BF360C";
        } else {
            return "#8D6E63";
        }
    }

    function readBits(
        uint256 tokenId,
        uint8 offset,
        uint8 length
    ) private pure returns (uint256) {
        uint256 shift = 160 - offset - length;
        uint256 mask = ((1 << length) - 1) << shift;
        return (tokenId & mask) >> shift;
    }
}