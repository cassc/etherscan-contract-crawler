// SPDX-License-Identifier: AGPL-3.0-or-later

// render.sol -- DSSToken render module

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.15;

import {svg} from "hot-chain-svg/SVG.sol";
import {utils} from "hot-chain-svg/Utils.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Inc} from "./token.sol";

library DataURI {
    function toDataURI(string memory data, string memory mimeType)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            "data:", mimeType, ";base64,", Base64.encode(abi.encodePacked(data))
        );
    }
}

library Render {
    function json(uint256 _tokenId, string memory _svg, Inc memory _count)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"name": "CounterDAO',
            " #",
            utils.uint2str(_tokenId),
            '", "description": "I frobbed an inc and all I got was this lousy dss-token", "image": "',
            _svg,
            '", "attributes": ',
            attributes(_count),
            '}'
        );
    }

    function attributes(Inc memory inc) internal pure returns (string memory) {
        return string.concat(
            "[",
            attribute("net", inc.net),
            ",",
            attribute("tab", inc.tab),
            ",",
            attribute("tax", inc.tax),
            ",",
            attribute("num", inc.num),
            ",",
            attribute("hop", inc.hop),
            "]"
        );
    }

    function attribute(string memory name, uint256 value)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"trait_type": "',
            name,
            '", "value": "',
            utils.uint2str(value),
            '", "display_type": "number"}'
        );
    }

    function image(
        uint256 _tokenId,
        uint256 _supply,
        Inc memory _count,
        Inc memory _price
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300" style="background:#7CC3B3;font-family:Helvetica Neue, Helvetica, Arial, sans-serif;">',
            svg.el(
                "path",
                string.concat(
                    svg.prop("id", "top"),
                    svg.prop(
                        "d",
                        "M 10 10 H 280 a10,10 0 0 1 10,10 V 280 a10,10 0 0 1 -10,10 H 20 a10,10 0 0 1 -10,-10 V 10 z"
                    ),
                    svg.prop("fill", "#7CC3B3")
                ),
                ""
            ),
            svg.el(
                "path",
                string.concat(
                    svg.prop("id", "bottom"),
                    svg.prop(
                        "d",
                        "M 290 290 H 20 a10,10 0 0 1 -10,-10 V 20 a10,10 0 0 1 10,-10 H 280 a10,10 0 0 1 10,10 V 290 z"
                    ),
                    svg.prop("fill", "#7CC3B3")
                ),
                ""
            ),
            svg.text(
                string.concat(
                    svg.prop("dominant-baseline", "middle"),
                    svg.prop("font-family", "Menlo, monospace"),
                    svg.prop("font-size", "9"),
                    svg.prop("fill", "white")
                ),
                string.concat(
                    svg.el(
                        "textPath",
                        string.concat(svg.prop("href", "#top")),
                        string.concat(
                            formatInc(_count),
                            svg.el(
                                "animate",
                                string.concat(
                                    svg.prop("attributeName", "startOffset"),
                                    svg.prop("from", "0%"),
                                    svg.prop("to", "100%"),
                                    svg.prop("dur", "120s"),
                                    svg.prop("begin", "0s"),
                                    svg.prop("repeatCount", "indefinite")
                                ),
                                ""
                            )
                        )
                    )
                )
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "50%"),
                    svg.prop("y", "45%"),
                    svg.prop("text-anchor", "middle"),
                    svg.prop("dominant-baseline", "middle"),
                    svg.prop("font-size", "150"),
                    svg.prop("font-weight", "bold"),
                    svg.prop("fill", "white")
                ),
                string.concat(svg.cdata("++"))
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "50%"),
                    svg.prop("y", "70%"),
                    svg.prop("text-anchor", "middle"),
                    svg.prop("font-size", "20"),
                    svg.prop("fill", "white")
                ),
                string.concat(utils.uint2str(_tokenId), " / ", utils.uint2str(_supply))
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "50%"),
                    svg.prop("y", "80%"),
                    svg.prop("text-anchor", "middle"),
                    svg.prop("font-size", "20"),
                    svg.prop("fill", "white")
                ),
                utils.uint2str(_count.net)
            ),
            svg.text(
                string.concat(
                    svg.prop("dominant-baseline", "middle"),
                    svg.prop("font-family", "Menlo, monospace"),
                    svg.prop("font-size", "9"),
                    svg.prop("fill", "white")
                ),
                string.concat(
                    svg.el(
                        "textPath",
                        string.concat(svg.prop("href", "#bottom")),
                        string.concat(
                            formatInc(_price),
                            svg.el(
                                "animate",
                                string.concat(
                                    svg.prop("attributeName", "startOffset"),
                                    svg.prop("from", "0%"),
                                    svg.prop("to", "100%"),
                                    svg.prop("dur", "120s"),
                                    svg.prop("begin", "0s"),
                                    svg.prop("repeatCount", "indefinite")
                                ),
                                ""
                            )
                        )
                    )
                )
            ),
            "</svg>"
        );
    }

    function formatInc(Inc memory inc) internal pure returns (string memory) {
        return svg.cdata(
            string.concat(
                "Inc ",
                Strings.toHexString(uint160(inc.guy), 20),
                " | net: ",
                utils.uint2str(inc.net),
                " | tab: ",
                utils.uint2str(inc.tab),
                " | tax: ",
                utils.uint2str(inc.tax),
                " | num: ",
                utils.uint2str(inc.num),
                " | hop: ",
                utils.uint2str(inc.hop)
            )
        );
    }
}