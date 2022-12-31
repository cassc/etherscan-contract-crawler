// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library NFTSVG {
    using Strings for uint256;

    struct coordinate {
        uint256 x;
        uint256 xdecimal;
        uint256 y;
    }

    function getBlock(
        coordinate memory co,
        uint8 blockLevel,
        string memory fillcolor
    ) public pure returns (string memory svg) {
        string memory blockbg = ' class="b1"';
        if (bytes(fillcolor).length > 0) {
            blockbg = string(
                abi.encodePacked(' style="fill:', fillcolor, ';"')
            );
        }
        svg = string(
            abi.encodePacked(
                '<use width="46.188" height="40" transform="translate(',
                co.x.toString(),
                ".",
                co.xdecimal.toString(),
                " ",
                co.y.toString(),
                ')"',
                blockbg,
                ' xlink:href="#Block"/>',
                getLevelItem(blockLevel, co.x, co.y)
            )
        );
    }

    function getLevelItem(
        uint8 level,
        uint256 x,
        uint256 y
    ) public pure returns (string memory) {
        bytes memory svgbytes = abi.encodePacked('<use width="');
        if (level == 1 || level == 2 || level == 11) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '20.5" height="20.5" transform="translate(',
                Strings.toString(x + 13),
                " ",
                Strings.toString(y + 10)
            );
        } else if (level == 3 || level == 6 || level == 12) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '21.6349" height="18.7503" transform="translate(',
                Strings.toString(x + 12),
                " ",
                Strings.toString(y + 10)
            );
        } else if (level == 4 || level == 5 || level == 7 || level == 8) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '18.5" height="18.5" transform="translate(',
                Strings.toString(x + 14),
                " ",
                Strings.toString(y + 11)
            );
        } else if (level == 9) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '6.3999" height="5.4" transform="translate(',
                Strings.toString(x + 20),
                " ",
                Strings.toString(y + 18)
            );
        } else if (level == 10) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '8" height="8" transform="translate(',
                Strings.toString(x + 19),
                " ",
                Strings.toString(y + 16)
            );
        }
        return
            string(
                abi.encodePacked(
                    svgbytes,
                    ')" xlink:href="#Lv',
                    uint256(level).toString(),
                    '" />'
                )
            );
    }

    function getImage(
        string memory defs,
        string memory background,
        string memory blocks
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" ',
                    'xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500">',
                    defs,
                    background,
                    blocks,
                    "</svg>"
                )
            );
    }

    function generateDefs(
        bytes memory ringbordercolor,
        bytes memory ringbgcolor
    ) public pure returns (string memory svg) {
        svg = string(
            bytes.concat(
                abi.encodePacked(
                    "<defs><style>.c1 {font-size: 24px;}.c1,.c2 {font-family: ArialMT, Arial;isolation: isolate;}",
                    ".c2 {font-size: 14px;}.c3 {stroke-width: 0.25px;}.c3,.c4 {stroke: #000;stroke-miterlimit: 10;}",
                    ".c4 {fill: none;stroke-width: 0.5px;}.c5 {fill: ",
                    ringbordercolor,
                    ";}.c6 {fill: url(#background);}.b1 {fill: #fff;}</style>",
                    '<symbol id="Block" viewBox="0 0 46.188 40"><polygon class="c3" points="34.5688 .125 11.6192 .125 .1443 20 11.6192 39.875 34.5688 39.875 46.0437 20 34.5688 .125"/></symbol>',
                    '<symbol id="Lv1" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/></symbol>',
                    '<symbol id="Lv2" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/><circle class="c4" cx="10.25" cy="10.25" r="4"/></symbol>',
                    '<symbol id="Lv3" viewBox="0 0 21.6349 18.7503"><polygon class="c4" points="10.9588 .5003 .4357 18.5003 21.205 18.5003 10.9588 .5003" /></symbol>',
                    '<symbol id="Lv4" viewBox="0 0 18.5 18.5"><rect class="c4" x=".25" y=".25" width="18" height="18" /></symbol>'
                ),
                abi.encodePacked(
                    '<symbol id="Lv5" viewBox="0 0 18.5 18.5"><rect class="c4" x=".25" y=".25" width="18" height="18" /><circle class="c4" cx="9.25" cy="9.25" r="4" /></symbol>',
                    '<symbol id="Lv6" viewBox="0 0 21.6349 18.7503"><polygon class="c4" points="10.8146 9.0862 7.6146 14.4862 14.0146 14.4862 10.8146 9.0862" /><polygon class="c4" points="10.6761 .5003 .43 18.5003 21.1992 18.5003 10.6761 .5003" /></symbol>',
                    '<symbol id="Lv7" viewBox="0 0 18.5 18.5"><rect class="c4" x=".25" y=".25" width="18" height="18" /><polygon class="c4" points="9.25 6.55 6.05 11.95 12.45 11.95 9.25 6.55" /></symbol>',
                    '<symbol id="Lv8" viewBox="0 0 18.5 18.5"><rect class="c4" x="5.65" y="5.65" width="7.2" height="7.2" /><rect class="c4" x=".25" y=".25" width="18" height="18" /></symbol>',
                    '<symbol id="Lv9" viewBox="0 0 6.3999 5.4"><polygon points="3.3032 0 0 5.4 6.3999 5.4 3.3032 0" /></symbol>',
                    '<symbol id="Lv10" viewBox="0 0 8 8"><circle cx="4" cy="4" r="4" /></symbol>',
                    '<symbol id="Lv11" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/>',
                    '<g><circle cx="10.25" cy="10.25" r="4" /><animate attributeName="opacity" values="1;0;1" dur="3.85s" begin="0s" repeatCount="indefinite"/></g></symbol>',
                    '<symbol id="Lv12" viewBox="0 0 21.6349 18.7503"><g><polygon points="10.9236 9.3759 7.6204 14.7759 14.0204 14.7759 10.9236 9.3759" /><animate attributeName="opacity" values="1;0;1" dur="3.85s" begin="0s" repeatCount="indefinite"/></g>',
                    '<polygon class="c4" points="10.9588 .5003 .4357 18.5003 21.205 18.5003 10.9588 .5003" /></symbol>'
                ),
                abi.encodePacked(
                    '<linearGradient id="background" x1="391.1842" y1="434.6524" x2="107.8509" y2="-56.0954" gradientTransform="translate(0 440.1141) scale(1 -1)" gradientUnits="userSpaceOnUse">',
                    '<stop offset=".03" stop-color="',
                    ringbgcolor,
                    '" stop-opacity=".6" /><stop offset=".5" stop-color="',
                    ringbgcolor,
                    '" /><stop offset=".96" stop-color="',
                    ringbgcolor,
                    '" stop-opacity=".2" /></linearGradient></defs>'
                )
            )
        );
    }

    function generateBackground(
        uint256 id,
        string memory coordinateStr
    ) public pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g><rect class="c6" width="500" height="500" /><path class="c5" d="M490,10V490H10V10H490m10-10H0V500H500V0h0Z" />',
                '<text class="c1" transform="translate(30 46.4014)"><tspan>MOPN PASS</tspan></text>',
                '<text class="c1" transform="translate(470 46.4014)" text-anchor="end"><tspan>#',
                id.toString(),
                '</tspan></text><text class="c2" transform="translate(30 475.4541)"><tspan>$ENERGY 0</tspan>',
                '</text><text class="c2" transform="translate(470 475.4542)" text-anchor="end"><tspan>',
                coordinateStr,
                "</tspan></text></g>"
            )
        );
    }

    function generateBlocks(
        uint8[] memory blockLevels
    ) public pure returns (string memory svg) {
        bytes memory output;
        uint256 ringNum = 0;
        uint256 ringPos = 1;
        uint256 cx = 226;
        uint256 cxdecimal = 906;
        uint256 cy = 230;
        coordinate memory co = coordinate(226, 906, 230);

        for (uint256 i = 0; i < blockLevels.length; i++) {
            output = abi.encodePacked(output, getBlock(co, blockLevels[i], ""));

            if (ringPos >= ringNum * 6) {
                ringPos = 1;
                ringNum++;
                if (ringNum > 5) {
                    break;
                }
                co.x = cx;
                co.xdecimal = cxdecimal;
                co.y = cy - 40 * ringNum;
            } else {
                uint256 side = Math.ceilDiv(ringPos, ringNum);
                if (side == 1) {
                    co.xdecimal += 641;
                    if (co.xdecimal > 1000) {
                        co.x += 35;
                        co.xdecimal -= 1000;
                    } else {
                        co.x += 34;
                    }
                    co.y += 20;
                } else if (side == 2) {
                    co.y += 40;
                } else if (side == 3) {
                    if (co.xdecimal < 641) {
                        co.xdecimal += 359;
                        co.x -= 35;
                    } else {
                        co.xdecimal -= 641;
                        co.x -= 34;
                    }
                    co.y += 20;
                } else if (side == 4) {
                    if (co.xdecimal < 641) {
                        co.xdecimal += 359;
                        co.x -= 35;
                    } else {
                        co.xdecimal -= 641;
                        co.x -= 34;
                    }
                    co.y -= 20;
                } else if (side == 5) {
                    co.y -= 40;
                } else if (side == 6) {
                    co.xdecimal += 641;
                    if (co.xdecimal > 1000) {
                        co.x += 35;
                        co.xdecimal -= 1000;
                    } else {
                        co.x += 34;
                    }
                    co.y -= 20;
                }
                ringPos++;
            }
        }

        svg = string(abi.encodePacked("<g>", output, "</g>"));
    }
}