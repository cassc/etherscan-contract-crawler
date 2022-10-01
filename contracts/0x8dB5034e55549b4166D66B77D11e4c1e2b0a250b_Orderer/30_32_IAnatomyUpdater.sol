// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Anatomy Updater interface
/// @notice Contains event for aatomy update
interface IAnatomyUpdater {
    event UpdateAnatomy(address asset, uint8 weight);
    event AssetRemoved(address asset);
}