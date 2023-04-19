// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";

/**
 * @notice Possible transfer restrictions.
 */
enum TransferRestriction {
    None,
    OnlyMint,
    OnlyBurn,
    Frozen
}

/**
 * @notice Implements restrictions for ERC721 transfers.
 * @dev This is intended to facilitate a soft expiry for voucher tokens, having an intermediate stage that still allows
 * voucher to be redeemed but not traded before closing all activity indefinitely.
 * @dev The activation of restrictions is left to the extending contract.
 */
abstract contract ERC721ATransferRestrictedBase is ERC721ACommon {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if an action is disallowed by the current transfer
     * restriction.
     */
    error DisallowedByTransferRestriction(TransferRestriction);

    // =========================================================================
    //                           Transfer Restriction
    // =========================================================================

    /**
     * @notice Returns the current transfer restriction.
     * @dev Hook to be implemented by the consuming contract (e.g. manual
     * setter, time based, etc.)
     */
    function transferRestriction() public view virtual returns (TransferRestriction);

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Blocks transfers depending on the current restrictions.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        TransferRestriction restriction = transferRestriction();
        if (restriction == TransferRestriction.None) {
            return;
        }
        if (restriction == TransferRestriction.OnlyMint && from == address(0)) {
            return;
        }
        if (restriction == TransferRestriction.OnlyBurn && to == address(0)) {
            return;
        }

        revert DisallowedByTransferRestriction(restriction);
    }
}