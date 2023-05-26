// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {

    /// @param hardware uint representing hardware selection
    /// @return HardwareData containing svg snippet and hardware title and hardware type
    function generateHardware(uint16 hardware) external view returns (IHardwareSVGs.HardwareData memory);

    struct HardwareSVGs {
        IHardwareSVGs hardwareSVGs1;
        IHardwareSVGs hardwareSVGs2;
        IHardwareSVGs hardwareSVGs3;
        IHardwareSVGs hardwareSVGs4;
        IHardwareSVGs hardwareSVGs5;
        IHardwareSVGs hardwareSVGs6;
        IHardwareSVGs hardwareSVGs7;
        IHardwareSVGs hardwareSVGs8;
        IHardwareSVGs hardwareSVGs9;
        IHardwareSVGs hardwareSVGs10;
        IHardwareSVGs hardwareSVGs11;
        IHardwareSVGs hardwareSVGs12;
        IHardwareSVGs hardwareSVGs13;
        IHardwareSVGs hardwareSVGs14;
        IHardwareSVGs hardwareSVGs15;
        IHardwareSVGs hardwareSVGs16;
        IHardwareSVGs hardwareSVGs17;
        IHardwareSVGs hardwareSVGs18;
        IHardwareSVGs hardwareSVGs19;
        IHardwareSVGs hardwareSVGs20;
        IHardwareSVGs hardwareSVGs21;
        IHardwareSVGs hardwareSVGs22;
        IHardwareSVGs hardwareSVGs23;
        IHardwareSVGs hardwareSVGs24;
        IHardwareSVGs hardwareSVGs25;
        IHardwareSVGs hardwareSVGs26;
        IHardwareSVGs hardwareSVGs27;
        IHardwareSVGs hardwareSVGs28;
        IHardwareSVGs hardwareSVGs29;
        IHardwareSVGs hardwareSVGs30;
        IHardwareSVGs hardwareSVGs31;
        IHardwareSVGs hardwareSVGs32;
        IHardwareSVGs hardwareSVGs33;
        IHardwareSVGs hardwareSVGs34;
        IHardwareSVGs hardwareSVGs35;
        IHardwareSVGs hardwareSVGs36;
        IHardwareSVGs hardwareSVGs37;
        IHardwareSVGs hardwareSVGs38;
    }
}