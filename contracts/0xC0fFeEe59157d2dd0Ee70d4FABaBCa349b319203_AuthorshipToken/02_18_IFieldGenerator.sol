// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFieldGenerator {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }
    struct FieldData {
        string title;
        FieldCategories fieldType;
        string svgString;
    }

    function generateField(uint16 field, uint24[4] memory colors)
        external
        view
        returns (FieldData memory);
}