// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IFieldSVGs.sol';
import './IColors.sol';

/// @dev Generate Field SVG
interface IFieldGenerator {
    /// @param field uint representing field selection
    /// @param colors to be rendered in the field svg
    /// @return FieldData containing svg snippet and field title
    function generateField(uint16 field, uint24[4] memory colors) external view returns (IFieldSVGs.FieldData memory);

    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);

    struct FieldSVGs {
        IFieldSVGs fieldSVGs1;
        IFieldSVGs fieldSVGs2;
        IFieldSVGs fieldSVGs3;
        IFieldSVGs fieldSVGs4;
        IFieldSVGs fieldSVGs5;
        IFieldSVGs fieldSVGs6;
        IFieldSVGs fieldSVGs7;
        IFieldSVGs fieldSVGs8;
        IFieldSVGs fieldSVGs9;
        IFieldSVGs fieldSVGs10;
        IFieldSVGs fieldSVGs11;
        IFieldSVGs fieldSVGs12;
        IFieldSVGs fieldSVGs13;
        IFieldSVGs fieldSVGs14;
        IFieldSVGs fieldSVGs15;
        IFieldSVGs fieldSVGs16;
        IFieldSVGs fieldSVGs17;
        IFieldSVGs fieldSVGs18;
        IFieldSVGs fieldSVGs19;
        IFieldSVGs fieldSVGs20;
        IFieldSVGs fieldSVGs21;
        IFieldSVGs fieldSVGs22;
        IFieldSVGs fieldSVGs23;
        IFieldSVGs fieldSVGs24;
    }
}