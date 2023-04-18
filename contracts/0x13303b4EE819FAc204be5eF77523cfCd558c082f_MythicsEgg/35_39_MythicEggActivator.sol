// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {BitMaps} from "openzeppelin-contracts/utils/structs/BitMaps.sol";
import {ERC4906} from "ethier/erc721/ERC4906.sol";

import {MythicsEggErrors} from "./MythicsEggErrors.sol";

interface MythicEggActivatorEvents {
    /**
     * @notice Emitted when an egg has been activated.
     */
    event EggActivated(uint256 indexed tokenId);
}

/**
 * @title Mythics: Egg activation module
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
abstract contract MythicEggActivator is ERC4906, MythicsEggErrors, MythicEggActivatorEvents {
    using BitMaps for BitMaps.BitMap;

    /**
     * @notice Throws if activating an egg that has already been activated.
     */
    error EggAlreadyActivated(uint256);

    /**
     * @notice Thrown if one tries to activate too many eggs at once.
     */
    error ActivatingTooManyEggs(uint256 requested, uint256 numLeft);

    /**
     * @notice Keeps track of eggs that have already been activated.
     */
    BitMaps.BitMap private _activated;

    /**
     * @notice The maximum number of eggs that can be activated during one day.
     */
    uint32 internal _maxNumActivationsPerDay = 50;

    /**
     * @notice The last day on which an egg was activated.
     */
    uint32 private _lastActivationDay;

    /**
     * @notice The number of eggs that have been activated today.
     * @dev Will be reset to 0 in `_activate` at the start of each day.
     */
    uint32 private _numActivatedToday;

    /**
     * @notice Helper function to get the current day number.
     */
    function _currentDay() private view returns (uint32) {
        return uint32(block.timestamp / (1 days));
    }

    /**
     * @notice Sets the maximum number of activations per day.
     */
    function _setMaxNumActivationsPerDay(uint32 maxNumActivationsPerDay) internal {
        _maxNumActivationsPerDay = maxNumActivationsPerDay;
    }

    /**
     * @notice Activates an array of eggs.
     * @dev Will revert if the number of eggs to activate exceeds the maximum number of activations per day.
     */
    function _activate(uint256[] calldata tokenIds) internal {
        if (_currentDay() > _lastActivationDay) {
            _numActivatedToday = 0;
            _lastActivationDay = _currentDay();
        }

        uint256 numLeft = _maxNumActivationsPerDay - _numActivatedToday;
        if (tokenIds.length > numLeft) {
            revert ActivatingTooManyEggs(tokenIds.length, numLeft);
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            if (activated(tokenId)) {
                revert EggAlreadyActivated(tokenId);
            }

            if (!_exists(tokenId)) {
                revert NonexistentEgg(tokenId);
            }

            _activated.set(tokenId);
            _refreshMetadata(tokenId);
            emit EggActivated(tokenId);
        }
        _numActivatedToday += uint32(tokenIds.length);
    }

    /**
     * @notice Returns whether an egg has already been activated.
     */
    function activated(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) {
            revert NonexistentEgg(tokenId);
        }

        return _activated.get(tokenId);
    }

    /**
     * @notice Returns whether a token exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool);
}