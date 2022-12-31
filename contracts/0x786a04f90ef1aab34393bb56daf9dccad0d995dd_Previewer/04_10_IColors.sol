// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IColors
{

    function getPalette(uint idx) external view returns (string[] calldata colors);
    function getPaletteSize(uint idx) external view returns (uint numColors) ;
    function getSkyPalette(uint idx) external view returns (string[] calldata colors);

    function getNumSkys() external view returns (uint numSkys);
    function getNumPalettes() external view returns (uint numPalettes);

    function getSkyName(uint idx) external view returns (string calldata name);
    function getPaletteName(uint idx) external view returns (string calldata name);

    function getSkyRarities() external view returns (uint8[] memory);
    function geColorPaletteRarities() external view returns (uint8[] memory);

}