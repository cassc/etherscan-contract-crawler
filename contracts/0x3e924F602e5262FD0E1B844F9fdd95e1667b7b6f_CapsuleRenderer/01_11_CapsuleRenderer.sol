// SPDX-License-Identifier: GPL-3.0

/**
  @title CapsuleRenderer

  @author peri

  @notice Renders SVG images for Capsules tokens.
 */

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITypeface.sol";
import "./interfaces/ICapsuleRenderer.sol";
import "./interfaces/ICapsuleToken.sol";
import "./utils/Base64.sol";

struct SvgSpecs {
    // Color code for SVG fill property
    string fill;
    // ID for row elements used on top and bottom edges of svg.
    bytes edgeRowId;
    // ID for row elements placed behind text rows.
    bytes textRowId;
    // Number of non-empty lines in Capsule text. Only trailing empty lines are excluded.
    uint256 linesCount;
    // Number of characters in the longest line of text.
    uint256 charWidth;
    // Width of the text area (in dots).
    uint256 textAreaWidthDots;
    // Height of the text area (in dots).
    uint256 textAreaHeightDots;
}

contract CapsuleRenderer is ICapsuleRenderer {
    /// Address of CapsulesTypeface contract
    address public immutable capsulesTypeface;

    constructor(address _capsulesTypeface) {
        capsulesTypeface = _capsulesTypeface;
    }

    function typeface() external view returns (address) {
        return capsulesTypeface;
    }

    /// @notice Return Base64-encoded SVG for Capsule.
    /// @param capsule Capsule data to return SVG for.
    /// @return svg SVG for Capsule.
    function svgOf(Capsule memory capsule)
        external
        view
        returns (string memory)
    {
        return svgOf(capsule, false);
    }

    /// @notice Return Base64-encoded SVG for Capsule. Can optionally return a square ratio image, regardless of text content shape.
    /// @param capsule Capsule to return SVG for.
    /// @param square Fit image to square with content centered.
    /// @return base64Svg Base64-encoded SVG for Capsule.
    function svgOf(Capsule memory capsule, bool square)
        public
        view
        returns (string memory base64Svg)
    {
        uint256 dotSize = 4;

        // If text is empty or invalid, use default text
        if (_isEmptyText(capsule.text) || !isValidText(capsule.text)) {
            capsule = Capsule({
                text: _defaultTextOf(capsule.color),
                id: capsule.id,
                color: capsule.color,
                font: capsule.font,
                isPure: capsule.isPure,
                isLocked: capsule.isLocked
            });
        }

        SvgSpecs memory specs = _svgSpecsOf(capsule);

        // Define reusable <g> elements to minimize overall SVG size
        bytes memory defs;
        {
            bytes
                memory dots1x12 = '<g id="dots1x12"><circle cx="2" cy="2" r="1.5"></circle><circle cx="2" cy="6" r="1.5"></circle><circle cx="2" cy="10" r="1.5"></circle><circle cx="2" cy="14" r="1.5"></circle><circle cx="2" cy="18" r="1.5"></circle><circle cx="2" cy="22" r="1.5"></circle><circle cx="2" cy="26" r="1.5"></circle><circle cx="2" cy="30" r="1.5"></circle><circle cx="2" cy="34" r="1.5"></circle><circle cx="2" cy="38" r="1.5"></circle><circle cx="2" cy="42" r="1.5"></circle><circle cx="2" cy="46" r="1.5"></circle></g>';

            // <g> row of dots 1 dot high that spans entire canvas width
            // If Capsule is locked, trim start and end dots and translate group
            bytes memory edgeRowDots;
            edgeRowDots = abi.encodePacked('<g id="', specs.edgeRowId, '">');
            if (capsule.isLocked) {
                for (uint256 i; i < specs.textAreaWidthDots; i++) {
                    edgeRowDots = abi.encodePacked(
                        edgeRowDots,
                        '<circle cx="',
                        Strings.toString(dotSize * i + 2),
                        '" cy="2" r="1.5"></circle>'
                    );
                }
            } else {
                for (uint256 i = 1; i < specs.textAreaWidthDots - 1; i++) {
                    edgeRowDots = abi.encodePacked(
                        edgeRowDots,
                        '<circle cx="',
                        Strings.toString(dotSize * i + 2),
                        '" cy="2" r="1.5"></circle>'
                    );
                }
            }
            edgeRowDots = abi.encodePacked(edgeRowDots, "</g>");

            // <g> row of dots with text height that spans entire canvas width
            bytes memory textRowDots;
            textRowDots = abi.encodePacked('<g id="', specs.textRowId, '">');
            for (uint256 i; i < specs.textAreaWidthDots; i++) {
                textRowDots = abi.encodePacked(
                    textRowDots,
                    '<use href="#dots1x12" transform="translate(',
                    Strings.toString(dotSize * i),
                    ')"></use>'
                );
            }
            textRowDots = abi.encodePacked(textRowDots, "</g>");

            defs = abi.encodePacked(dots1x12, edgeRowDots, textRowDots);
        }

        // Define <style> for svg element
        bytes memory style;
        {
            string memory fontWeightString = Strings.toString(
                capsule.font.weight
            );
            style = abi.encodePacked(
                "<style>.capsules-",
                fontWeightString,
                "{ font-size: 40px; white-space: pre; font-family: Capsules-",
                fontWeightString,
                ' } @font-face { font-family: "Capsules-',
                fontWeightString,
                '"; src: url(data:font/truetype;charset=utf-8;base64,',
                ITypeface(capsulesTypeface).sourceOf(capsule.font),
                ') format("opentype")}</style>'
            );
        }

        // Content area group will contain dot background and text.
        bytes memory contentArea;
        {
            // Create <g> element and define color of dots and text.
            contentArea = abi.encodePacked('<g fill="', specs.fill, '"');

            // If square image, translate contentArea group to center of svg viewbox
            if (square) {
                // Square size of the entire svg (in dots) equal to longest edge, including padding of 2 dots
                uint256 squareSizeDots = 2;
                if (specs.textAreaHeightDots >= specs.textAreaWidthDots) {
                    squareSizeDots += specs.textAreaHeightDots;
                } else {
                    squareSizeDots += specs.textAreaWidthDots;
                }

                contentArea = abi.encodePacked(
                    contentArea,
                    ' transform="translate(',
                    Strings.toString(
                        ((squareSizeDots - specs.textAreaWidthDots) / 2) *
                            dotSize
                    ),
                    " ",
                    Strings.toString(
                        ((squareSizeDots - specs.textAreaHeightDots) / 2) *
                            dotSize
                    ),
                    ')"'
                );
            }

            // Add dots by tiling edge row and text row elements defined in `defs`.

            // Add top edge row element
            contentArea = abi.encodePacked(
                contentArea,
                '><g opacity="0.2"><use href="#',
                specs.edgeRowId,
                '"></use>'
            );

            // Add a text row element for each line of text
            for (uint256 i; i < specs.linesCount; i++) {
                contentArea = abi.encodePacked(
                    contentArea,
                    '<use href="#',
                    specs.textRowId,
                    '" transform="translate(0 ',
                    Strings.toString(48 * i + dotSize),
                    ')"></use>'
                );
            }

            // Add bottom edge row element and close <g> group element
            contentArea = abi.encodePacked(
                contentArea,
                '<use href="#',
                specs.edgeRowId,
                '" transform="translate(0 ',
                Strings.toString((specs.textAreaHeightDots - 1) * dotSize),
                ')"></use></g>'
            );
        }

        // Create <g> group of text elements
        bytes memory texts;
        {
            // Create <g> element for texts and position using translate
            texts = '<g transform="translate(10 44)">';

            // Add a <text> element for each line of text, excluding trailing empty lines.
            // Each <text> has its own Y position.
            // Setting class on individual <text> elements increases CSS specificity and helps ensure styles are not overwritten by external stylesheets.
            for (uint256 i; i < specs.linesCount; i++) {
                texts = abi.encodePacked(
                    texts,
                    '<text y="',
                    Strings.toString(48 * i),
                    '" class="capsules-',
                    Strings.toString(capsule.font.weight),
                    '">',
                    _toUnicodeString(capsule.text[i]),
                    "</text>"
                );
            }

            // Close <g> texts group.
            texts = abi.encodePacked(texts, "</g>");
        }

        // Add texts to content area group and close <g> group.
        contentArea = abi.encodePacked(contentArea, texts, "</g>");

        {
            string memory x;
            string memory y;
            if (square) {
                // Square size of the entire svg (in dots) equal to longest edge, including padding of 2 dots
                uint256 squareSizeDots = 2;
                if (specs.textAreaHeightDots >= specs.textAreaWidthDots) {
                    squareSizeDots += specs.textAreaHeightDots;
                } else {
                    squareSizeDots += specs.textAreaWidthDots;
                }

                // If square image, use square viewbox
                x = Strings.toString(squareSizeDots * dotSize);
                y = Strings.toString(squareSizeDots * dotSize);
            } else {
                // Else fit to text area
                x = Strings.toString(specs.textAreaWidthDots * dotSize);
                y = Strings.toString(specs.textAreaHeightDots * dotSize);
            }

            // Construct parent svg element with defs, style, and content area groups.
            bytes memory svg = abi.encodePacked(
                '<svg viewBox="0 0 ',
                x,
                " ",
                y,
                '" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg"><defs>',
                defs,
                "</defs>",
                style,
                '<rect x="0" y="0" width="100%" height="100%" fill="#000"></rect>',
                contentArea,
                "</svg>"
            );

            // Base64 encode the svg data with prefix
            base64Svg = string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
        }
    }

    /// @notice Check if text is valid.
    /// @dev Text is valid if every unicode is supported by CapsulesTypeface, or is 0x00.
    /// @param text Text to check validity of.
    /// @return true True if text is valid.
    function isValidText(bytes32[8] memory text) public view returns (bool) {
        unchecked {
            for (uint256 i; i < 8; i++) {
                bytes2[16] memory line = _bytes32ToBytes2Array(text[i]);

                for (uint256 j; j < 16; j++) {
                    bytes2 char = line[j];

                    if (
                        char != 0 &&
                        !ITypeface(capsulesTypeface).supportsCodePoint(
                            // convert to bytes3 by adding 0 byte padding to left side
                            bytes3(abi.encodePacked(bytes1(0), char))
                        )
                    ) {
                        // return false if any single character is unsupported
                        return false;
                    }
                }
            }
        }

        return true;
    }

    /// @notice Returns default text for a Capsule with specified color
    /// @param color Color of Capsule
    /// @return defaultText Default text for Capsule
    function _defaultTextOf(bytes3 color)
        internal
        pure
        returns (bytes32[8] memory defaultText)
    {
        defaultText[0] = bytes32(
            abi.encodePacked(
                bytes1(0),
                "C",
                bytes1(0),
                "A",
                bytes1(0),
                "P",
                bytes1(0),
                "S",
                bytes1(0),
                "U",
                bytes1(0),
                "L",
                bytes1(0),
                "E"
            )
        );
        bytes memory _color = bytes(_bytes3ToColorCode(color));
        defaultText[1] = bytes32(
            abi.encodePacked(
                bytes1(0),
                _color[0],
                bytes1(0),
                _color[1],
                bytes1(0),
                _color[2],
                bytes1(0),
                _color[3],
                bytes1(0),
                _color[4],
                bytes1(0),
                _color[5],
                bytes1(0),
                _color[6]
            )
        );
    }

    /// @notice Calculate specs used to build SVG for capsule. The SvgSpecs struct allows using memory more efficiently when constructing a SVG for a Capsule.
    /// @param capsule Capsule to calculate specs for
    /// @return specs SVG specs calculated for Capsule
    function _svgSpecsOf(Capsule memory capsule)
        internal
        pure
        returns (SvgSpecs memory)
    {
        // Calculate number of lines of Capsule text to render. Only trailing empty lines are excluded.
        uint256 linesCount;
        for (uint256 i = 8; i > 0; i--) {
            if (!_isEmptyLine(capsule.text[i - 1])) {
                linesCount = i;
                break;
            }
        }

        // Calculate the width of the Capsule text in characters. Equal to the number of non-empty characters in the longest line.
        uint256 charWidth;
        for (uint256 i; i < linesCount; i++) {
            // Reverse iterate over line
            bytes2[16] memory line = _bytes32ToBytes2Array(capsule.text[i]);
            for (uint256 j = 16; j > charWidth; j--) {
                if (line[j - 1] != 0) charWidth = j;
            }
        }

        // Define the id of the svg row element.
        bytes memory edgeRowId;
        if (capsule.isLocked) {
            edgeRowId = abi.encodePacked("rowL", Strings.toString(charWidth));
        } else {
            edgeRowId = abi.encodePacked("row", Strings.toString(charWidth));
        }

        // Width of the text area (in dots)
        uint256 textAreaWidthDots = charWidth * 5 + (charWidth - 1) + 6;
        // Height of the text area (in dots)
        uint256 textAreaHeightDots = linesCount * 12 + 2;

        return
            SvgSpecs({
                fill: _bytes3ToColorCode(capsule.color),
                edgeRowId: edgeRowId,
                textRowId: abi.encodePacked(
                    "textRow",
                    Strings.toString(charWidth)
                ),
                linesCount: linesCount,
                charWidth: charWidth,
                textAreaWidthDots: textAreaWidthDots,
                textAreaHeightDots: textAreaHeightDots
            });
    }

    /// @notice Check if all lines of text are empty.
    /// @dev Returns true if every line of text is empty.
    /// @param text Text to check.
    /// @return true if text is empty.
    function _isEmptyText(bytes32[8] memory text) internal pure returns (bool) {
        for (uint256 i; i < 8; i++) {
            if (!_isEmptyLine(text[i])) return false;
        }
        return true;
    }

    /// @notice Check if line is empty.
    /// @dev Returns true if every byte of text is 0x00.
    /// @param line line to check.
    /// @return true if line is empty.
    function _isEmptyLine(bytes32 line) internal pure returns (bool) {
        bytes2[16] memory _line = _bytes32ToBytes2Array(line);
        for (uint256 i; i < 16; i++) {
            if (_line[i] != 0) return false;
        }
        return true;
    }

    /// @notice Check if font is valid Capsules typeface font.
    /// @dev A font is valid if its source has been set in the CapsulesTypeface contract.
    /// @param font Font to check.
    /// @return true True if font is valid.
    function isValidFont(Font memory font) external view returns (bool) {
        return ITypeface(capsulesTypeface).hasSource(font);
    }

    /// @notice Returns text formatted as an array of readable strings.
    /// @param text Text to format.
    /// @return _stringText Text string array.
    function stringText(bytes32[8] memory text)
        external
        pure
        returns (string[8] memory _stringText)
    {
        for (uint256 i; i < 8; i++) {
            _stringText[i] = _toUnicodeString(text[i]);
        }
    }

    /// @notice Returns line of text formatted as a readable string.
    /// @dev Iterates through each byte in line of text and replaces each byte as needed to create a string that will render in html without issue. Ensures that no illegal characters or 0x00 bytes remain. Non-trailing 0x00 bytes are converted to spaces, trailing 0x00 bytes are trimmed.
    /// @param line Line of text to format.
    /// @return unicodeString Text string that can be safely rendered in html.
    function _toUnicodeString(bytes32 line)
        internal
        pure
        returns (string memory unicodeString)
    {
        bytes2[16] memory arr = _bytes32ToBytes2Array(line);

        for (uint256 i; i < 16; i++) {
            bytes2 char = arr[i];

            // 0 bytes cannot be rendered
            if (char == 0) continue;

            unicodeString = string.concat(
                unicodeString,
                _bytes2ToUnicodeString(char)
            );
        }
    }

    /// @notice Format bytes32 type as array of bytes2
    /// @param b bytes32 value to convert to array
    /// @return a Array of bytes2
    function _bytes32ToBytes2Array(bytes32 b)
        internal
        pure
        returns (bytes2[16] memory a)
    {
        for (uint256 i; i < 16; i++) {
            a[i] = bytes2(abi.encodePacked(b[i * 2], b[i * 2 + 1]));
        }
    }

    /// @notice Format bytes3 type as html hex color code.
    /// @param b bytes3 value representing hex-encoded RGB color.
    /// @return o Formatted color code string.
    function _bytes3ToColorCode(bytes3 b)
        internal
        pure
        returns (string memory o)
    {
        bytes memory hexCode = bytes(Strings.toHexString(uint24(b)));
        o = "#";
        // Trim leading 0x from hexCode
        for (uint256 i = 0; i < 6; i++) {
            o = string.concat(o, string(abi.encodePacked(hexCode[i + 2])));
        }
    }

    /// @notice Format bytes2 type as decimal unicode string for html.
    /// @param b bytes2 value representing hex unicode.
    /// @return unicode Formatted decimal unicode string.
    function _bytes2ToUnicodeString(bytes2 b)
        internal
        pure
        returns (string memory)
    {
        return string.concat("&#", Strings.toString(uint16(b)), ";");
    }
}