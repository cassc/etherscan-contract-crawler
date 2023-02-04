// SPDX-License-Identifier: MIT

/// @title Ultra Sound Parts
/// @author -wizard

// Inspired by - Nouns DAO art contract

pragma solidity ^0.8.6;

import {SSTORE2} from "./libs/SSTORE2.sol";
import {IUltraSoundParts} from "./interfaces/IUltraSoundParts.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract UltraSoundParts is IUltraSoundParts, Ownable {
    address[] private symbolPointers;
    address[] private palettePointers;
    address[] private gradientPointers;

    uint16[8] private quantity = [80, 40, 20, 10, 5, 4, 1, 0];

    constructor() {}

    function addSymbol(bytes calldata data) external override onlyOwner {
        _addSymbol(data);
    }

    function addSymbols(bytes[] calldata data) external override onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _addSymbol(data[i]);
        }
    }

    // Note: Palette must be an abi encoded string array
    function addPalette(bytes calldata data) external override onlyOwner {
        _addPalette(data);
    }

    // Note: Palette must be an abi encoded string array
    function addPalettes(bytes[] calldata data) external override onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _addPalette(data[i]);
        }
    }

    // Note: Gradients must be an abi encoded string array
    function addGradient(bytes calldata data) external override onlyOwner {
        _addGradient(data);
    }

    // Note: Gradients must be an abi encoded string array
    function addGradients(bytes[] calldata data) external override onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _addGradient(data[i]);
        }
    }

    function symbols(uint256 index)
        public
        view
        override
        returns (bytes memory)
    {
        address pointer = symbolPointers[index];
        if (pointer == address(0)) revert PartNotFound();
        bytes memory data = SSTORE2.read(symbolPointers[index]);
        return data;
    }

    function palettes(uint256 index)
        public
        view
        override
        returns (bytes memory)
    {
        address pointer = palettePointers[index];
        if (pointer == address(0)) revert PartNotFound();
        bytes memory data = SSTORE2.read(pointer);
        return data;
    }

    function gradients(uint256 index)
        public
        view
        override
        returns (bytes memory)
    {
        address pointer = gradientPointers[index];
        if (pointer == address(0)) revert PartNotFound();
        bytes memory data = SSTORE2.read(pointer);
        return data;
    }

    function quantities(uint256 index) public view override returns (uint16) {
        return quantity[index];
    }

    function symbolsCount() public view override returns (uint256) {
        return symbolPointers.length;
    }

    function palettesCount() public view override returns (uint256) {
        return palettePointers.length;
    }

    function gradientsCount() public view override returns (uint256) {
        return gradientPointers.length;
    }

    function quantityCount() public view override returns (uint256) {
        return quantity.length;
    }

    function _addSymbol(bytes calldata data) internal {
        address pointer = SSTORE2.write(data);
        symbolPointers.push(pointer);
        emit SymbolAdded();
    }

    function _addPalette(bytes calldata data) internal {
        address pointer = SSTORE2.write(data);
        palettePointers.push(pointer);
        emit PaletteAdded();
    }

    function _addGradient(bytes calldata data) internal {
        address pointer = SSTORE2.write(data);
        gradientPointers.push(pointer);
        emit GradientAdded();
    }
}