//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el('rect', _props);
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
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<', _tag, ' ', _props, '/>');
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }
}