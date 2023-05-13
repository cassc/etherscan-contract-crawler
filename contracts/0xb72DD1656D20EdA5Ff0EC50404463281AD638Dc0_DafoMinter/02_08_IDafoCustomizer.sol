// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoCustomizer

pragma solidity ^0.8.6;

import {IDafoDescriptor} from './IDafoDescriptor.sol';

interface IDafoCustomizer {
    struct CustomInput {
        uint256 tokenId;
        uint8 role;
        uint8 palette;
        bool outline;
    }

    function generateInput(
        uint256 unavailableId,
        uint256 tokenMax,
        IDafoDescriptor descriptor
    ) external view returns (CustomInput memory);

    function create(
        uint256 tokenId,
        uint8 role,
        uint8 palette,
        bool outline
    ) external view returns (CustomInput memory);

    function isInBounds(IDafoDescriptor descriptor, IDafoCustomizer.CustomInput calldata _customInput) external view;
}