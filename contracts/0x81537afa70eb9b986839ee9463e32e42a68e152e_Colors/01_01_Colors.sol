//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
@title  Colors
@notice The colors of honeycombs.
*/
library Colors {
    /// @dev These are sorted in a gradient.
    function COLORS() public pure returns (string[46] memory) {
        return [
            "FF005D",
            "FF0040",
            "FF0011",
            "FF0D00",
            "FF3300",
            "FF4C00",
            "FF6600",
            "FF7700",
            "FF8800",
            "FF9900",
            "FFB300",
            "FFCC00",
            "FFE600",
            "FFF700",
            "FFFF00",
            "F6FF00",
            "EEFF00",
            "D4FF00",
            "B3FF00",
            "99FF00",
            "80FF00",
            "62FF00",
            "00FF11",
            "00FF80",
            "00FFBF",
            "00FFEE",
            "00F7FF",
            "00E6FF",
            "00C3FF",
            "0099FF",
            "0077FF",
            "0055FF",
            "0033FF",
            "3300FF",
            "5500FF",
            "6600FF",
            "7B00FF",
            "9000FF",
            "AA00FF",
            "BB00FF",
            "D400FF",
            "EE00FF",
            "FB00FF",
            "FF00EA",
            "FF00CC",
            "FF00A2"
        ];
    }
}