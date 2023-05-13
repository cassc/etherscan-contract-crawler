// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoDescriptor

pragma solidity ^0.8.6;

import {IDafoCustomizer} from './IDafoCustomizer.sol';

interface IDafoDescriptor {
    struct Palette {
        string background;
        string fill;
    }

    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function paletteCount() external view returns (uint256);

    function digitCount() external view returns (uint256);

    function roleCount() external view returns (uint256);

    function addManyPalettes(Palette[] calldata _palettes) external;

    function addManyDigits(string[] calldata _digits) external;

    function addManyRoles(string[] calldata _roles) external;

    function addPalette(uint8 index, Palette calldata _palette) external;

    function addDigit(uint8 index, string calldata _digit) external;

    function addRole(uint8 index, string calldata _roles) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);

    function dataURI(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IDafoCustomizer.CustomInput memory customInput
    ) external view returns (string memory);

    function generateSVGImage(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);
}