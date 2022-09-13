// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

contract EssenceNFTStorage {
    // constant
    uint256 internal constant _VERSION = 2;

    // storage
    uint256 internal _profileId;
    uint256 internal _essenceId;
    bool internal _transferable;
}