// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props, NULL);
    }

    function path(string memory _props) internal pure returns (string memory) {
        return el("path", _props, NULL);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function feGaussianBlur(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feGaussianBlur", _props, NULL);
    }

    function feMerge(string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("feMerge", NULL, _children);
    }

    function feMergeNode(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feMergeNode", _props, NULL);
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
}