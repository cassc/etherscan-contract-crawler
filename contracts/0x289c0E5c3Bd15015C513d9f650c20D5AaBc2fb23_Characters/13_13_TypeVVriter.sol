// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TypeVVriter is Ownable {
    /// @notice The SVG path definition for each character in the VV alphabet.
    mapping(string => string) public LETTERS;

    /// @notice Width in pixels for characters in the VV alphabet.
    mapping(string => uint256) public LETTER_WIDTHS;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a text as an SVG font inheriting text color and letter-spaced with 1px.
    /// @param text The text you want to write out.
    function write(string memory text) public view returns (string memory) {
        return write(text, "currentColor", 6);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a text as an SVG font with 1px space between letters.
    /// @param text The text you want to write out.
    /// @param color The SVG-compatible color code to use for the text.
    function write(string memory text, string memory color) public view returns (string memory) {
        return write(text, color, 6);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a given text as an SVG font in given `color` and letter `spacing`.
    /// @param text The text you want to write out.
    /// @param color The SVG-compatible color code to use for the text.
    /// @param spacing The space between letters in pixels.
    function write(
        string memory text,
        string memory color,
        uint256 spacing
    ) public view returns (string memory) {
        bytes memory byteText = upper(bytes(text));

        uint256 letterPos = 0;
        string memory letters = "";

        for (uint256 i = 0; i < byteText.length; i++) {
            bool overflow = byteText[i] >= 0xC0;
            bytes memory character = overflow ? new bytes(2) : new bytes(1);
            character[0] = byteText[i];
            if (overflow) {
                i += 1;
                character[1] = byteText[i];
            }
            string memory normalized = string(character);

            string memory path = LETTERS[normalized];
            if (bytes(path).length <= 0) continue;

            letters = string(abi.encodePacked(
                letters,
                '<g transform="translate(', Strings.toString(letterPos), ')">',
                    '<path d="', path, '"/>',
                '</g>'
            ));

            uint256 width = LETTER_WIDTHS[normalized] == 0
                ? LETTER_WIDTHS["DEFAULT"]
                : LETTER_WIDTHS[normalized];

            letterPos = letterPos + width + spacing;
        }

        uint256 lineWidth = letterPos - spacing;
        string memory svg = string(abi.encodePacked(
            '<svg ',
                'viewBox="0 0 ', Strings.toString(lineWidth), ' 30" ',
                'width="', Strings.toString(lineWidth), '" height="30" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg"',
            '>',
                '<g fill-rule="evenodd" clip-rule="evenodd" fill="', color, '">',
                    letters,
                '</g>',
            '</svg>'
        ));

        return svg;
    }

    /// @dev Uppercase some byte text.
    function upper(bytes memory _text) internal pure returns (bytes memory) {
        for (uint i = 0; i < _text.length; i++) {
            _text[i] = _upper(_text[i]);
        }
        return _text;
    }

    /// @dev Uppercase a single byte letter.
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /// @dev Store a Glyph on-chain
    function setGlyph(string memory glyph, string memory path) public onlyOwner {
        _setGlyph(glyph, path);
    }

    /// @dev Store multiple Glyphs on-chain
    function setGlyphs(string[] memory glyphs, string[] memory paths) public onlyOwner {
        for (uint i = 0; i < glyphs.length; i++) {
            _setGlyph(glyphs[i], paths[i]);
        }
    }

    /// @dev Store a Glyph width on-chain
    function setGlyphWidth(string memory glyph, uint256 width) public onlyOwner {
        _setGlyphWidth(glyph, width);
    }

    /// @dev Store multiple Glyph widths on-chain
    function setGlyphWidths(string[] memory glyphs, uint256[] memory widths) public onlyOwner {
        for (uint i = 0; i < glyphs.length; i++) {
            _setGlyphWidth(glyphs[i], widths[i]);
        }
    }

    /// @dev Store a Glyph on-chain
    function _setGlyph(string memory glyph, string memory path) private {
        LETTERS[glyph] = path;
    }

    /// @dev Store a Glyph width on-chain
    function _setGlyphWidth(string memory glyph, uint256 width) private {
        LETTER_WIDTHS[glyph] = width;
    }
}