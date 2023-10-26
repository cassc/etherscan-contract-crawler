// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {PatternHeader} from '../assets/IOpenAvatarGen0AssetsPatternStore.sol';

struct LayerPatternPalette {
  uint8 layer;
  uint8 pattern;
  uint8 palette;
}

/**
 * @title IOpenAvatarGen0AssetsCanvasLayerCompositor
 * @dev This contract composes palettized patterns into a single image.
 */
interface IOpenAvatarGen0AssetsCanvasLayerCompositor {
  function createLayerComposition(
    uint8 canvasId,
    // is view function, so not concerned about calldata being cheaper
    // need memory because this function is called by other functions that
    // may compute layers dynamically in memory
    LayerPatternPalette[] memory layerPatternPalette
  ) external view returns (bytes memory);

  function drawLayerComposition(
    bytes memory out,
    uint8 canvasId,
    // is view function, so not concerned about calldata being cheaper
    // need memory because this function is called by other functions that
    // may compute layers dynamically in memory
    LayerPatternPalette[] memory layerPatternPalette
  ) external view returns (bytes memory);

  function drawLayer(
    bytes memory image,
    uint8 canvasId,
    uint8 layer,
    uint8 pattern,
    uint8 palette
  ) external view returns (bytes memory);

  function drawMaskedLayer(
    bytes memory image,
    bytes memory mask,
    uint8 canvasId,
    uint8 layer,
    uint8 pattern,
    uint8 palette
  ) external view returns (bytes memory);

  function drawPattern(
    bytes memory image,
    uint8 canvasId,
    PatternHeader memory header,
    bytes memory pattern,
    bytes4[] memory palette
  ) external view returns (bytes memory);

  function drawMaskedPattern(
    bytes memory image,
    bytes memory mask,
    uint8 canvasId,
    PatternHeader memory header,
    bytes memory pattern,
    bytes4[] memory palette
  ) external view returns (bytes memory);
}