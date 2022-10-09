// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Strings } from "micro-onchain-metadata-utils/lib/Strings.sol";

/// @title CurationMetadataBuilder
/// @author Iain Nash
/// @notice Curation Metadata Builder Tools
library CurationMetadataBuilder {
    /// @notice Arduino-style map function that takes x from a range and maps to a range of y.
    function map(
        uint256 x,
        uint256 xMax,
        uint256 xMin,
        uint256 yMin,
        uint256 yMax
    ) internal pure returns (uint256) {
        return ((x - xMin) * (yMax - yMin)) / (xMax - xMin) + yMin;
    }

    /// @notice Makes a SVG square rect with the given parameters
    function _makeSquare(
        uint256 size,
        uint256 x,
        uint256 y,
        string memory color
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<rect x="',
                Strings.toString(x),
                '" y="',
                Strings.toString(y),
                '" width="',
                Strings.toString(size),
                '" height="',
                Strings.toString(size),
                '" style="fill: ',
                color,
                '" />'
            );
    }
}