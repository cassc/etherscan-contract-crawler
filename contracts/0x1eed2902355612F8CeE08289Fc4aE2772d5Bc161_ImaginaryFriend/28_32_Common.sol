// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

uint8 constant NUM_BACKGROUNDS = 13;
uint8 constant NUM_BODIES = 36;
uint8 constant NUM_MOUTHS = 35;
uint8 constant NUM_EYES = 45;

/// @notice The possible values of the Special trait.
enum Special {
    None,
    Devil,
    Angel,
    Both
}

/// @notice The features an ImaginaryFriend can have.
/// @dev The features are base 1 - zero means the corresponding trait is
/// deactivated.
struct Features {
    uint8 background;
    uint8 body;
    uint8 mouth;
    uint8 eyes;
    Special special;
    bool golden;
}

/// @notice A serialized version of `Features`
type FeaturesSerialized is bytes32;