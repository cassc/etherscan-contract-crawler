// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";

library SVG {
    /*//////////////////////////////////////////////////////////////
                                 ELEMENT
    //////////////////////////////////////////////////////////////*/

    function element(string memory _type, string memory _attributes) internal pure returns (string memory) {
        return string.concat("<", _type, " ", _attributes, "/>");
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _children
    ) internal pure returns (string memory) {
        return string.concat("<", _type, " ", _attributes, ">", _children, "</", _type, ">");
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5, _child6));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6,
        string memory _child7
    ) internal pure returns (string memory) {
        return
            element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5, _child6, _child7));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6,
        string memory _child7,
        string memory _child8
    ) internal pure returns (string memory) {
        return
            element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5, _child6, _child7, _child8));
    }

    /*//////////////////////////////////////////////////////////////
                               ATTRIBUTES
    //////////////////////////////////////////////////////////////*/

    function svgAttributes() internal pure returns (string memory) {
        return
            string.concat(
                'xmlns="http://www.w3.org/2000/svg" '
                'xmlns:xlink="http://www.w3.org/1999/xlink" '
                'width="100%" '
                'height="100%" '
                'viewBox="0 0 511 619" ',
                'preserveAspectRatio="xMidYMid meet" ',
                'fill="none" '
            );
    }

    function textAttributes(
        string[2] memory _coords,
        string memory _fontSize,
        string memory _fontFamily,
        string memory _fill,
        string memory _attributes
    ) internal pure returns (string memory) {
        return
            string.concat(
                "x=",
                Util.quote(_coords[0]),
                "y=",
                Util.quote(_coords[1]),
                "font-size=",
                Util.quote(string.concat(_fontSize, "px")),
                "font-family=",
                Util.quote(_fontFamily),
                "fill=",
                Util.quote(_fill),
                " ",
                _attributes,
                " "
            );
    }

    function rectAttributes(
        string memory _width,
        string memory _height,
        string memory _fill,
        string memory _attributes
    ) internal pure returns (string memory) {
        return
            string.concat(
                "width=",
                Util.quote(_width),
                "height=",
                Util.quote(_height),
                "fill=",
                Util.quote(_fill),
                " ",
                _attributes,
                " "
            );
    }

    function filterAttribute(string memory _id) internal pure returns (string memory) {
        return string.concat("filter=", '"', "url(#", _id, ")", '" ');
    }
}