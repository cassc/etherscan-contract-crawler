// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {IOpenAvatarGen0AssetsCanvasStore, IOpenAvatarGen0AssetsCanvasStoreRead, IOpenAvatarGen0AssetsCanvasStoreWrite} from './IOpenAvatarGen0AssetsCanvasStore.sol';
import {IOpenAvatarGen0AssetsPaletteStoreRead, IOpenAvatarGen0AssetsPaletteStoreWrite, IOpenAvatarGen0AssetsPaletteStore} from './IOpenAvatarGen0AssetsPaletteStore.sol';

struct PatternHeader {
  /// @dev width of the pattern
  uint8 width;
  /// @dev height of the pattern
  uint8 height;
  /// @dev x offset of the pattern within the canvas
  uint8 offsetX;
  /// @dev y offset of the pattern within the canvas
  uint8 offsetY;
  /// @dev the palette code for the pattern
  uint8 paletteCode;
}

struct OptionalPatternHeader {
  /// @dev true if the header exists
  bool exists;
  /// @dev the pattern header
  /// @dev all zeroes is valid header
  PatternHeader header;
}

struct PatternBlob {
  /// @dev the pattern header
  PatternHeader header;
  /// @dev the pattern data
  bytes data;
}

struct UploadPatternInput {
  /// @dev the canvas id
  uint8 canvasId;
  /// @dev index of the layer within the canvas
  uint8 layer;
  /// @dev index of the pattern within the layer
  uint8 index;
  /// @dev width of the pattern
  uint8 width;
  /// @dev height of the pattern
  uint8 height;
  /// @dev x offset of the pattern within the canvas
  uint8 offsetX;
  /// @dev y offset of the pattern within the canvas
  uint8 offsetY;
  /// @dev the palette code for the pattern
  uint8 paletteCode;
  /// @dev the pattern data
  bytes data;
}

/**
 * @title IOpenAvatarGen0AssetsPatternStoreRead
 * @dev This interface reads pattern data
 */
interface IOpenAvatarGen0AssetsPatternStoreRead is IOpenAvatarGen0AssetsCanvasStoreRead {
  /////////////////////////////////////////////////////////////////////////////
  // Layers
  /////////////////////////////////////////////////////////////////////////////

  function getNumLayers(uint8 canvasId) external view returns (uint);

  /////////////////////////////////////////////////////////////////////////////
  // Patterns
  /////////////////////////////////////////////////////////////////////////////

  function getNumPatterns(uint8 canvasId, uint8 layer) external view returns (uint);

  function getPatternHeader(
    uint8 canvasId,
    uint8 layer,
    uint8 index
  ) external view returns (OptionalPatternHeader memory);

  function getPatternData(uint8 canvasId, uint8 layer, uint8 index) external view returns (bytes memory);
}

/**
 * @title IOpenAvatarGen0AssetsPatternStoreWrite
 * @dev This interface writes pattern data
 */
interface IOpenAvatarGen0AssetsPatternStoreWrite is IOpenAvatarGen0AssetsCanvasStoreWrite {
  /////////////////////////////////////////////////////////////////////////////
  // Layers
  /////////////////////////////////////////////////////////////////////////////

  function addLayer(uint8 canvasId, uint8 layer) external;

  function addLayers(uint8 canvasId, uint8[] calldata layers) external;

  /////////////////////////////////////////////////////////////////////////////
  // Patterns
  /////////////////////////////////////////////////////////////////////////////

  function uploadPattern(UploadPatternInput calldata input) external;

  function uploadPatterns(UploadPatternInput[] calldata inputs) external;
}

/**
 * @title IOpenAvatarGen0AssetsPatternStore
 * @dev This interface reads and writes pattern data
 */
interface IOpenAvatarGen0AssetsPatternStore is
  IOpenAvatarGen0AssetsPatternStoreRead,
  IOpenAvatarGen0AssetsPatternStoreWrite,
  IOpenAvatarGen0AssetsCanvasStore
{

}