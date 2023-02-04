// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Parts
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundParts {
    error SenderIsNotDescriptor();
    error PartNotFound();

    event SymbolAdded();
    event PaletteAdded();
    event GradientAdded();

    function addSymbol(bytes calldata data) external;

    function addSymbols(bytes[] calldata data) external;

    function addPalette(bytes calldata data) external;

    function addPalettes(bytes[] calldata data) external;

    function addGradient(bytes calldata data) external;

    function addGradients(bytes[] calldata data) external;

    function symbols(uint256 index) external view returns (bytes memory);

    function palettes(uint256 index) external view returns (bytes memory);

    function gradients(uint256 index) external view returns (bytes memory);

    function quantities(uint256 index) external view returns (uint16);

    function symbolsCount() external view returns (uint256);

    function palettesCount() external view returns (uint256);

    function gradientsCount() external view returns (uint256);

    function quantityCount() external view returns (uint256);
}