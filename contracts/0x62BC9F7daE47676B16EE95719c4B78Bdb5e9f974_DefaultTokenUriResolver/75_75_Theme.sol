//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Color} from "solcolor/src/Types.sol";

/**
 * @notice Themes contain color data for styling SVGs.
 * @member customTheme True for all Themes except the default theme.
 * @member textColor The color of the text.
 * @member bgColor The primary background color.
 * @member bgColorAlt The secondary background color.
 */
struct Theme {
    bool customTheme;
    Color textColor;
    Color bgColor;
    Color bgColorAlt;
}