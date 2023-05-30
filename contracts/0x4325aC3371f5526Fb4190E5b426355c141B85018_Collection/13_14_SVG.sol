//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.

// modified from original to take away functions that I'm not using

library svg {
    /* MAIN ELEMENTS */

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    
    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
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
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
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