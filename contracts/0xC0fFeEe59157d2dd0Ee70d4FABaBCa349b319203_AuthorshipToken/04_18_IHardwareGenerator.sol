// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IHardwareGenerator {
    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
    struct HardwareData {
        string title;
        HardwareCategories hardwareType;
        string svgString;
    }

    function generateHardware(uint16 hardware)
        external
        view
        returns (HardwareData memory);
}