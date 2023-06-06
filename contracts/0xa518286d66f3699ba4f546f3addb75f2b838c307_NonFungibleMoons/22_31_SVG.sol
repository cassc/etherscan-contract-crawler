// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from "../utils/Utils.sol";

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
// Props to w1nt3r.eth for creating the core of this SVG utility library.
library svg {
    string internal constant NULL = "";

    /* MAIN ELEMENTS */
    function svgTag(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("svg", _props, _children);
    }

    function defs(string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("defs", NULL, _children);
    }

    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, NULL);
    }

    function mask(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("mask", _props, _children);
    }

    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function stop(string memory _props) internal pure returns (string memory) {
        return el("stop", _props, NULL);
    }

    function ellipse(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("ellipse", _props, NULL);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props, NULL);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function feSpecularLighting(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("feSpecularLighting", _props, _children);
    }

    function fePointLight(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("fePointLight", _props, NULL);
    }

    function feComposite(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feComposite", _props, NULL);
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '="', _val, '" ');
    }

    function prop(string memory _key, uint256 _val)
        internal
        pure
        returns (string memory)
    {
        return prop(_key, Utils.uint2str(_val));
    }
}