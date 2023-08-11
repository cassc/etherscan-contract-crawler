// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./InfiniteBags.sol";
import "./Utilities.sol";

/**
@title  InfiniteArt
@author VisualizeValue
@notice Renders the Infinity visuals.
*/
library InfiniteArt {

    /// @dev Generate the SVG code for an Infinity token.
    function renderSVG(Token memory data) public pure returns (string memory) {
        return string.concat(
            '<svg viewBox="0 0 800 800" fill="none" xmlns="http://www.w3.org/2000/svg">',
                renderStyle(data),
                renderDefs(),
                '<rect width="800" height="800" fill="var(--bg)" />',
                '<g transform="scale(0.95)" transform-origin="center">',
                    renderGrid(),
                '</g>',
                renderNoise(data),
                '<g transform="scale(0.95)" transform-origin="center">',
                    renderSymbols(data),
                '</g>',
            '</svg>'
        );
    }

    /// @dev Render CSS variables.
    function renderStyle(Token memory data) public pure returns (string memory) {
        return string.concat(
            '<style>',
                ':root {',
                    '--bg: ', data.background, ';',
                    '--gr: ', data.gridColor, ';',
                '}',
            '</style>'
        );
    }

    /// @dev Render SVG meta defenitions.
    function renderDefs() public pure returns (string memory) {
        return string.concat(
            '<defs>',
                '<rect id="box" width="100" height="100" stroke="var(--gr)" stroke-width="3" style="paint-order: stroke;" />'
                '<g id="row">', renderGridRow(), '</g>',
                '<mask id="mask"><rect width="800" height="800" fill="white"/></mask>',
                '<path id="loop" d="M 100 0 A 100 100, 0, 1, 1, 0 100 L 0 0 Z"/>',
                '<g id="infinity">',
                    '<use href="#loop" />',
                    '<use href="#loop" transform="scale(-1,-1)" />',
                '</g>',
                '<filter id="noise">',
                    '<feTurbulence type="fractalNoise" baseFrequency="0.8" stitchTiles="stitch" numOctaves="1" seed="8"/>',
                    '<feColorMatrix type="saturate" values="0"/>',
                '</filter>',
            '</defs>'
        );
    }

    /// @dev Generate the SVG code for the entire 8x8 grid.
    function renderGrid() public pure returns (string memory) {
        string memory grid;
        for (uint256 i; i < 8; i++) {
            grid = string.concat(
                grid,
                '<use href="#row" transform="translate(0,', str(i*100), ')" />'
            );
        }

        return grid;
    }

    /// @dev Generate the SVG code for rows in the 8x8 grid.
    function renderGridRow() public pure returns (string memory) {
        string memory row;
        for (uint256 i; i < 8; i++) {
            row = string.concat(
                row,
                '<use transform="translate(', str(i*100), ')" href="#box" />'
            );
        }
        return row;
    }

    /// @dev Render the noise layer.
    function renderNoise(Token memory data) public pure returns (string memory) {
        return string.concat(
            '<rect mask="url(#mask)" width="800" height="800" fill="black" filter="url(#noise)" ',
                'style="mix-blend-mode: multiply;" opacity="', data.light ? '0.248"' : '0.8"',
            '/>'
        );
    }

    /// @dev Generate SVG code for the symbols.
    function renderSymbols(Token memory data) public pure returns (string memory) {
        uint space  = 800 / data.grid;
        uint center = space / 4;
        uint width  = space / 2;

        string memory symbols;
        for (uint i = 0; i < data.count; i++) {
            Symbol memory symbol = data.symbols[i];

            uint baseStroke = symbol.isInfinity ? 8 : 4;
            uint stroke = (data.grid < 8 ? baseStroke : baseStroke * 3 / 4) * data.grid / 2;
            uint scale  = width * 1000 / symbol.formWidth;

            symbol.x      = str(i % data.grid * space + center);
            symbol.y      = str(i / data.grid * space + center);
            symbol.stroke = str(stroke);
            symbol.center = str(center);
            symbol.width  = str(width);
            symbol.scale  = scale < 1000
                ? string.concat('0.', str(scale))
                : str(scale / 1000);

            symbols = string.concat(symbols, renderSymbol(symbol));
        }
        return symbols;
    }

    /// @dev Generate SVG code for the symbols.
    function renderSymbol(Symbol memory symbol) public pure returns (string memory) {
        symbol.color.rendered = renderColor(symbol.color);

        string memory rendered = symbol.form == 1 ? renderLoop(symbol)
                               : symbol.form == 2 ? renderInfinitySingle(symbol)
                               : symbol.form == 3 ? render90Loop(symbol)
                               : symbol.form == 4 ? renderInfinityPair(symbol)
                               : symbol.form == 5 ? render180Loop(symbol)
                               : symbol.form == 8 ? renderInfinityCheck(symbol)
                                                  : render360Loop(symbol);

        return string.concat(
            '<g transform="translate(',symbol.x,',',symbol.y,') rotate(',symbol.rotation,')" ',
                'transform-origin="',symbol.center,' ',symbol.center,'" ',
                'stroke-width="', symbol.stroke,
            '">',
                rendered,
            '</g>'
        );
    }

    /// @dev Helper to render a color to its SVG compliant HSL string.
    function renderColor(Color memory color) public pure returns (string memory) {
        if (bytes(color.rendered).length > 0) return color.rendered;

        return string.concat('hsl(', str(color.h), ' ', str(color.s), '% ', str(color.l), '%)');
    }

    /// @dev Render a single loop symbol.
    function renderLoop(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<use href="#loop" transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '" />'
        );
    }

    /// @dev Render two loop symbols, one rotated by 90 degrees.
    function render90Loop(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<g transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '">',
                '<use href="#loop" />',
                '<use href="#loop" transform="translate(200,0) scale(-1,1)" />',
            '</g>'
        );
    }

    /// @dev Render two loop symbols, one rotated by 180 degrees.
    function render180Loop(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<g transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '">',
                '<use href="#loop" />',
                '<use href="#loop" transform="translate(200,200) scale(-1,-1)" />',
            '</g>'
        );
    }

    /// @dev Render four loop symbols to form a square.
    function render360Loop(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<g transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '">',
                '<use href="#loop" />',
                '<use href="#loop" transform="translate(200,0) scale(-1,1)" />',
                '<use href="#loop" transform="translate(0,200) scale(1,-1)" />',
                '<use href="#loop" transform="translate(200,200) scale(-1,-1)" />',
            '</g>'
        );
    }

    /// @dev Check: Render a single infinity.
    function renderInfinitySingle(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<g transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '">',
                '<g transform="translate(200,200)">'
                    '<use href="#infinity" />',
                '</g>'
            '</g>'
        );
    }

    /// @dev Double check: Render an infinity pair.
    function renderInfinityPair(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<g transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '">',
                '<g transform="translate(200,200)">'
                    '<use href="#infinity" />',
                    '<use href="#infinity" transform="rotate(90)" />',
                '</g>'
            '</g>'
        );
    }

    /// @dev Quadruple check: Render an infinity check.
    function renderInfinityCheck(Symbol memory symbol) public pure returns (string memory) {
        return string.concat(
            '<g transform="scale(', symbol.scale, ')" stroke="', symbol.color.rendered, '">',
                '<g transform="translate(200,200)">'
                    '<use href="#infinity" />',
                    '<use href="#infinity" transform="rotate(45)" />',
                    '<use href="#infinity" transform="rotate(90)" />',
                    '<use href="#infinity" transform="rotate(135)" />',
                '</g>'
            '</g>'
        );
    }

    /// @dev Uint to string helper.
    function str(uint n) public pure returns (string memory) {
        return Utilities.uint2str(n);
    }
}