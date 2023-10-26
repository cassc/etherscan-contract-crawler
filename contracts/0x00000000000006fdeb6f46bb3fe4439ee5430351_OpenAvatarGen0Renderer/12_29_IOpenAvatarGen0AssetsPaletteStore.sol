// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title IOpenAvatarGen0AssetsPaletteStoreRead
 * @dev This interface allows reading from the palette store.
 */
interface IOpenAvatarGen0AssetsPaletteStoreRead {
  /////////////////////////////////////////////////////////////////////////////
  // Constants
  /////////////////////////////////////////////////////////////////////////////

  function hasAlphaChannel() external view returns (bool);

  function getBytesPerPixel() external view returns (uint8);

  /////////////////////////////////////////////////////////////////////////////
  // Palettes
  /////////////////////////////////////////////////////////////////////////////

  function getNumPaletteCodes() external view returns (uint);

  function getNumPalettes(uint8 code) external view returns (uint);

  function getPalette(uint8 code, uint8 index) external view returns (bytes4[] memory);
}

struct UploadPaletteInput {
  uint8 code;
  uint8 index;
  bytes4[] palette;
}

struct UploadPaletteBatchInput {
  uint8 code;
  uint8 fromIndex;
  bytes4[][] palettes;
}

/**
 * @title IOpenAvatarGen0AssetsPaletteStoreWrite
 * @dev This interface allows writing to the palette store.
 */
interface IOpenAvatarGen0AssetsPaletteStoreWrite {
  function uploadPalette(UploadPaletteInput calldata input) external;

  function uploadPaletteBatch(UploadPaletteBatchInput calldata input) external;

  function uploadPaletteBatches(UploadPaletteBatchInput[] calldata input) external;
}

/**
 * @title IOpenAvatarGen0AssetsPaletteStore
 * @dev This interface allows reading from and writing to the palette store.
 */
interface IOpenAvatarGen0AssetsPaletteStore is
  IOpenAvatarGen0AssetsPaletteStoreRead,
  IOpenAvatarGen0AssetsPaletteStoreWrite
{

}