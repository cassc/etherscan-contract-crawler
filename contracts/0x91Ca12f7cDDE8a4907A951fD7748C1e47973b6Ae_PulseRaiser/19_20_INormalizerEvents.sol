// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface INormalizerEvents {
    event AssetDisabled(address indexed asset);
    event AssetEnabled(address indexed asset, address indexed feed);
}