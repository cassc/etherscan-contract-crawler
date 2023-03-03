// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IMoonbirds} from "moonbirds/IMoonbirds.sol";

/**
 * @notice Base contract for batched airdrops to a subset of nested tokens.
 */
abstract contract NestedAirdroppableBase {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the number of available airdrops is exceeded.
     */
    error TooManyAirdropsRequested(uint256 numAirdropsLeft);

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The moonbirds contract address.
     */
    IMoonbirds private immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The number of moonbirds left to consider.
     */
    uint256 private _numMoonbirdsLeft;

    // =========================================================================
    //                           Constructor
    // =========================================================================
    constructor(IMoonbirds moonbirds, uint256 numMoonbirds) {
        _moonbirds = moonbirds;
        _numMoonbirdsLeft = numMoonbirds;
    }

    // =========================================================================
    //                           Airdrop
    // =========================================================================

    /**
     * @notice Airdrops something to a list of moonbirds. If a listed bird is
     * not nested it is excluded from the airdrop.
     * @dev Reverts if the maximum number of moonbirds has been considered.
     */
    function _airdrop(uint256[] calldata birbIds) internal {
        if (birbIds.length > _numMoonbirdsLeft) {
            revert TooManyAirdropsRequested(_numMoonbirdsLeft);
        }
        _numMoonbirdsLeft -= birbIds.length;

        for (uint256 idx = 0; idx < birbIds.length;) {
            (bool nested,,) = _moonbirds.nestingPeriod(birbIds[idx]);

            if (nested) {
                _doAirdrop(_moonbirds.ownerOf(birbIds[idx]), birbIds[idx]);
            }
            unchecked {
                ++idx;
            }
        }
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Hook called by `_airdrop` to preform the airdrop to the moonbird
     * owner (e.g. minting a voucher token).
     */
    function _doAirdrop(address receiver, uint256 tokenId) internal virtual;
}