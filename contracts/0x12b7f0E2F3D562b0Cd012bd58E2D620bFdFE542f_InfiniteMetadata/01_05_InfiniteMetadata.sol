// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Base64.sol";

import "./InfiniteBags.sol";
import "./InfiniteArt.sol";
import "./Utilities.sol";

/**
@title  InfiniteMetadata
@author VisualizeValue
@notice Renders ERC1155 compatible metadata for Infinity tokens.
*/
library InfiniteMetadata {

    /// @dev Render the JSON Metadata for a given Infinity token.
    /// @param data The render data for our token
    function tokenURI(
        Token memory data
    ) public pure returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Infinity",',
                unicode'"description": "∞",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(abi.encodePacked(InfiniteArt.renderSVG(data))),
                    '",',
                '"attributes": [', attributes(data), ']',
            '}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(metadata)
        );
    }

    /// @dev Render the JSON atributes for a given Infinity token.
    /// @param data The check to render.
    function attributes(Token memory data) public pure returns (string memory) {
        return string.concat(
            trait('Light', light(data.light), ','),
            trait('Grid', grid(data), ','),
            data.light  ? '' : trait('Elements',  elements(data), ','),
            data.light  ? '' : trait('Gradient',  gradient(data), ','),
            data.light  ? '' : trait('Band',      band(data), ','),
            trait('Symbols',   symbols(data), '')
        );
    }

    /// @dev Get the value for the 'Light' attribute.
    function light(bool on) public pure returns (string memory) {
        return on ? 'On' : 'Off';
    }

    /// @dev Get the value for the 'Grid' attribute.
    function grid(Token memory data) public pure returns (string memory) {
        string memory g = Utilities.uint2str(data.grid);

        return string.concat(g, 'x', g);
    }

    /// @dev Get the value for the 'Elements' attribute.
    function elements(Token memory data) public pure returns (string memory) {
        return data.alloy == 0 ? 'Isolate'
             : data.alloy == 1 ? 'Composite'
             : data.alloy == 2 ? 'Compound'
                               : 'Complete';
    }

    /// @dev Get the value for the 'Band' attribute.
    function band(Token memory data) public pure returns (string memory) {
        return (data.continuous || data.alloy < 2) ? 'Continuous' : 'Cut';
    }

    /// @dev Get the value for the 'Gradient' attribute.
    function gradient(Token memory data) public pure returns (string memory) {
        return [
            // [0, 1, 2, 3, 4, 5, _, 7, 8, 9, 10, _, _, _, _, _, 16]
            'None', 'Linear', 'Double Linear', 'Angled Down', 'Ordered', 'Angled Up', '', 'Angled Down', 'Linear Z',
            'Angled', 'Angled Up', '', '', '', '', '', 'Double Linear Z'
        ][data.gradient];
    }

    /// @dev Get the value for the 'Symbols' attribute.
    function symbols(Token memory data) public pure returns (string memory) {
        return data.mapColors ? 'Mapped' : 'Random';
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) public pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

}