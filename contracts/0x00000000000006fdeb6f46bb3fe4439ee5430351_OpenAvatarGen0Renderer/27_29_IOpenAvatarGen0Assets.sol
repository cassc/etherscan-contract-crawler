// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {IOpenAvatarGen0AssetsCanvasStore, IOpenAvatarGen0AssetsCanvasStoreRead, IOpenAvatarGen0AssetsCanvasStoreWrite} from './core/interfaces/assets/IOpenAvatarGen0AssetsCanvasStore.sol';
import {IOpenAvatarGen0AssetsPaletteStoreRead, IOpenAvatarGen0AssetsPaletteStoreWrite, IOpenAvatarGen0AssetsPaletteStore} from './core/interfaces/assets/IOpenAvatarGen0AssetsPaletteStore.sol';
import {IOpenAvatarGen0AssetsPatternStoreRead, IOpenAvatarGen0AssetsPatternStoreWrite, IOpenAvatarGen0AssetsPatternStore} from './core/interfaces/assets/IOpenAvatarGen0AssetsPatternStore.sol';

/**
 * @title IOpenAvatarGen0AssetsRead
 * @dev This interface reads asset data
 */
interface IOpenAvatarGen0AssetsRead is
  IOpenAvatarGen0AssetsCanvasStoreRead,
  IOpenAvatarGen0AssetsPatternStoreRead,
  IOpenAvatarGen0AssetsPaletteStoreRead
{

}

/**
 * @title IOpenAvatarGen0AssetsWrite
 * @dev This interface writes asset data
 */
interface IOpenAvatarGen0AssetsWrite is
  IOpenAvatarGen0AssetsCanvasStoreWrite,
  IOpenAvatarGen0AssetsPatternStoreWrite,
  IOpenAvatarGen0AssetsPaletteStoreWrite
{

}

/**
 * @title IOpenAvatarGen0Assets
 * @dev This interface reads and writes asset data
 */
interface IOpenAvatarGen0Assets is IOpenAvatarGen0AssetsRead, IOpenAvatarGen0AssetsWrite {

}