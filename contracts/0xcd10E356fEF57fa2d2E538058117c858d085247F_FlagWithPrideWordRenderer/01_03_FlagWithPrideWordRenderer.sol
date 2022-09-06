//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Base64.sol';

import './IRenderer.sol';

contract FlagWithPrideWordRenderer is IRenderer {
    function description() external pure returns (string memory) {
        return
            'The original 8-stripe rainbow flag with the word PRIDE written on it in 20 languages, automatically changing every 1969 blocks.';
    }

    function render(bytes32)
        external
        view
        override
        returns (string memory imageURI, string memory animationURI)
    {
        imageURI = Base64.toB64SVG(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 800">'
                '<path fill="#8e008e" d="M0 0h1280v800H0z"/>'
                '<path fill="#400098" d="M0 0h1280v700H0z"/>'
                '<path fill="#00c0c0" d="M0 0h1280v600H0z"/>'
                '<path fill="#008e00" d="M0 0h1280v500H0z"/>'
                '<path fill="#ffff00" d="M0 0h1280v400H0z"/>'
                '<path fill="#ff8e00" d="M0 0h1280v300H0z"/>'
                '<path fill="#ff0000" d="M0 0h1280v200H0z"/>'
                '<path fill="#ff69b4" d="M0 0h1280v100H0z"/>'
                '<text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="150px"'
                ' font-weight="bold" fill="#fff" font-family="sans-serif" style="text-shadow:2px 2px 7px #000;text-transform:uppercase;">',
                _pickWord(),
                '</text></svg>'
            )
        );

        animationURI = '';
    }

    function _pickWord() internal view returns (string memory) {
        string[20] memory words = [
            'pride',
            unicode'fierté',
            'stolz',
            'orgullo',
            unicode'qürur',
            'orgoglio',
            'stolt',
            unicode'ความภาคภูมิใจ',
            'lepnums',
            'duma',
            unicode'mândrie',
            'orgulho',
            'ponos',
            'stolthet',
            'sharaf',
            unicode'自豪',
            'fahari',
            'kareueus',
            'kburija',
            'ylpeys'
        ];

        return words[(block.number / 1969) % words.length];
    }
}