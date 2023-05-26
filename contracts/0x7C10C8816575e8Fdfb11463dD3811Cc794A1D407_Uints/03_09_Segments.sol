/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    . . 1 . .    . . 1 . .    . . 1 . .    . . 1 . .    ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   2         3  2         3  2         3  2         3   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░    . . 4 . .    . . 4 . .    . . 4 . .    . . 4 . .    ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   5         6  5         6  5         6  5         6   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░    . . 7 . .    . . 7 . .    . . 7 . .    . . 7 . .    ░░
░░        a            b            c            d        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Utilities.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library segments {
    // Four digits: a, b, c, d
    struct Number {
        uint a;
        uint b;
        uint c;
        uint d;
    }

    function getNumbers(uint input, uint length) internal pure returns (Number memory result) {
        if (length == 1) {
            result.d = input;
        } else if (length == 2) {
            result.c = (input / 10);
            result.d = (input % 10);
        } else if (length == 3) {
            result.b = (input / 100);
            result.c = ((input % 100) / 10);
            result.d = (input % 10);
        } else if (length == 4) {
            result.a = (input / 1000);
            result.b = ((input % 1000) / 100);
            result.c = ((input % 100) / 10);
            result.d = (input % 10);
        }
        return result;
    }

    function getBaseColorName(uint index) internal pure returns (string memory) {
        string[4] memory baseColorNames = ["White", "Red", "Green", "Blue"];
        return baseColorNames[index];
    }

    function getMetadata(uint tokenId, uint value, uint baseColor, bool burned) internal pure returns (string memory) {
        uint[3] memory rgbs = utils.getRgbs(tokenId, baseColor);
        string memory json;

        if (burned) {
            json = string(abi.encodePacked(
            '{"name": "UINTS ',
            utils.uint2str(tokenId),
            ' [BURNED]", "description": "Numbers are art, and we are artists.", "attributes":[{"trait_type": "Burned", "value": "Yes"}], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(renderSvg(value, rgbs))),
            '"}'
        ));
        } else {
            json = string(abi.encodePacked(
            '{"name": "UINTS ',
            utils.uint2str(tokenId),
            '", "description": "Numbers are art, and we are artists.", "attributes":[{"trait_type": "Number", "max_value": 9999, "value": ',
            utils.uint2str(value),
            '},{"display_type": "number", "trait_type": "Mint Phase", "value": ',
            utils.uint2str(utils.getMintPhase(tokenId)),
            '},{"trait_type": "Burned", "value": "No"},{"trait_type": "Base Color", "value": "',
            getBaseColorName(baseColor),
            '"},{"trait_type": "Color", "value": "RGB(',
            utils.uint2str(rgbs[0]),
            ",",
            utils.uint2str(rgbs[1]),
            ",",
            utils.uint2str(rgbs[2]),
            ')"}], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(renderSvg(value, rgbs))),
            '"}'
        ));
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function getNumberStyle(uint position, uint input) internal pure returns (string memory) {
        string memory p = utils.uint2str(position);
        if (input == 0) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"3,","#p",p,"5,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 1) {
            return string(abi.encodePacked(
                "#p",p,"3,","#p",p,"6 {fill-opacity:1}"
            ));
        } else if (input == 2) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"3,","#p",p,"4,","#p",p,"5,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 3) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"3,","#p",p,"4,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 4) {
            return string(abi.encodePacked(
                "#p",p,"2,","#p",p,"3,","#p",p,"4,","#p",p,"6 {fill-opacity:1}"
            ));
        } else if (input == 5) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"4,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 6) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"4,","#p",p,"5,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 7) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"3,","#p",p,"6 {fill-opacity:1}"
            ));
        } else if (input == 8) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"3,","#p",p,"4,","#p",p,"5,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 9) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"3,","#p",p,"4,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else {
            return "error";
        }
    }

    function renderSvg(uint value,uint256[3] memory rgbs) internal pure returns (string memory svg) {
        svg = '<svg viewBox="0 0 300 300" fill="none" xmlns="http://www.w3.org/2000/svg"><rect id="bg" width="300" height="300" fill="#0C0C0C"/><path id="p01" d="M100 119L103 122L100 125L80 125L77 122L80 119L100 119Z" fill="white" fill-opacity="0.05"/><path id="p02" d="M73 126L76 123L79 126V146L76 149L73 146V126Z" fill="white" fill-opacity="0.05"/><path id="p03" d="M101 126L104 123L107 126V146L104 149L101 146V126Z" fill="white" fill-opacity="0.05"/><path id="p04" d="M100 147L103 150L100 153L80 153L77 150L80 147L100 147Z" fill="white" fill-opacity="0.05"/><path id="p05" d="M73 154L76 151L79 154V174L76 177L73 174V154Z" fill="white" fill-opacity="0.05"/><path id="p06" d="M101 154L104 151L107 154V174L104 177L101 174V154Z" fill="white" fill-opacity="0.05"/><path id="p07" d="M100 175L103 178L100 181L80 181L77 178L80 175L100 175Z" fill="white" fill-opacity="0.05"/><path id="p11" d="M140 119L143 122L140 125L120 125L117 122L120 119L140 119Z" fill="white" fill-opacity="0.05"/><path id="p12" d="M113 126L116 123L119 126V146L116 149L113 146V126Z" fill="white" fill-opacity="0.05"/><path id="p13" d="M141 126L144 123L147 126V146L144 149L141 146V126Z" fill="white" fill-opacity="0.05"/><path id="p14" d="M140 147L143 150L140 153L120 153L117 150L120 147L140 147Z" fill="white" fill-opacity="0.05"/><path id="p15" d="M113 154L116 151L119 154V174L116 177L113 174V154Z" fill="white" fill-opacity="0.05"/><path id="p16" d="M141 154L144 151L147 154V174L144 177L141 174V154Z" fill="white" fill-opacity="0.05"/><path id="p17" d="M140 175L143 178L140 181L120 181L117 178L120 175L140 175Z" fill="white" fill-opacity="0.05"/><path id="p21" d="M180 119L183 122L180 125L160 125L157 122L160 119L180 119Z" fill="white" fill-opacity="0.05"/><path id="p22" d="M153 126L156 123L159 126V146L156 149L153 146V126Z" fill="white" fill-opacity="0.05"/><path id="p23" d="M181 126L184 123L187 126V146L184 149L181 146V126Z" fill="white" fill-opacity="0.05"/><path id="p24" d="M180 147L183 150L180 153L160 153L157 150L160 147L180 147Z" fill="white" fill-opacity="0.05"/><path id="p25" d="M153 154L156 151L159 154V174L156 177L153 174V154Z" fill="white" fill-opacity="0.05"/><path id="p26" d="M181 154L184 151L187 154V174L184 177L181 174V154Z" fill="white" fill-opacity="0.05"/><path id="p27" d="M180 175L183 178L180 181L160 181L157 178L160 175L180 175Z" fill="white" fill-opacity="0.05"/><path id="p31" d="M220 119L223 122L220 125L200 125L197 122L200 119L220 119Z" fill="white" fill-opacity="0.05"/><path id="p32" d="M193 126L196 123L199 126V146L196 149L193 146V126Z" fill="white" fill-opacity="0.05"/><path id="p33" d="M221 126L224 123L227 126V146L224 149L221 146V126Z" fill="white" fill-opacity="0.05"/><path id="p34" d="M220 147L223 150L220 153L200 153L197 150L200 147L220 147Z" fill="white" fill-opacity="0.05"/><path id="p35" d="M193 154L196 151L199 154V174L196 177L193 174V154Z" fill="white" fill-opacity="0.05"/><path id="p36" d="M221 154L224 151L227 154V174L224 177L221 174V154Z" fill="white" fill-opacity="0.05"/><path id="p37" d="M220 175L223 178L220 181L200 181L197 178L200 175L220 175Z" fill="white" fill-opacity="0.05"/><style>';

        string memory styles = string(
            abi.encodePacked(
                "*{fill:rgb(",
                utils.uint2str(rgbs[0]),
                ",",
                utils.uint2str(rgbs[1]),
                ",",
                utils.uint2str(rgbs[2]),
                ")}#bg{fill:#0C0C0C}"
            )
        );

        if (value == 0) {} else {
            uint length = bytes(utils.uint2str(value)).length;
            Number memory number = getNumbers(value, length);
            if (length == 1) {
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(3, number.d))
                );
            } else if (length == 2) {
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(2, number.c))
                );
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(3, number.d))
                );
            } else if (length == 3) {
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(1, number.b))
                );
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(2, number.c))
                );
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(3, number.d))
                );
            } else if (length == 4) {
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(0, number.a))
                );
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(1, number.b))
                );
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(2, number.c))
                );
                styles = string(
                    abi.encodePacked(styles, getNumberStyle(3, number.d))
                );
            }
        }
        return string(abi.encodePacked(svg, styles, "</style></svg>"));
    }
}