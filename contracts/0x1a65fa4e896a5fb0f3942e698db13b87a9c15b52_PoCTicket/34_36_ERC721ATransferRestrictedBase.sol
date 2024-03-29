// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {ERC721ACommon} from "ethier/contracts/erc721/ERC721ACommon.sol";

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
 * @dev This is intended to facilitate a soft expiry for voucher tokens, having
 * an intermediate stage that still allows voucher to be redeemed but not traded
 * before closing all activity indefinitely.
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
    error DisallowedByTransferRestriction();

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Flag to bypass the current transfer restriction.
     */
    bool private _bypass;

    // =========================================================================
    //                           Transfer Restriction
    // =========================================================================

    /**
     * @notice Returns the current transfer restriction.
     * @dev Hook to be implemented by the consuming contract (e.g. manual
     * setter, time based, etc.)
     */
    function transferRestriction()
        public
        view
        virtual
        returns (TransferRestriction);

    /**
     * @notice Modifier that allows functions to bypass the transfer
     * restriction.
     */
    modifier bypassTransferRestriction() {
        _bypass = true;
        _;
        _bypass = false;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Blocks transfers depending on the current restrictions.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (_bypass) {
            return;
        }

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

        revert DisallowedByTransferRestriction();
    }

    // =========================================================================
    //                           Approvals
    // =========================================================================

    /**
     * @dev This returns false if all transfers are disabled to indicate to
     * marketplaces that these tokens cannot be sold and should therefore not be
     * listed.
     */
    function isApprovedForAll(address owner_, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (!_bypass && transferRestriction() != TransferRestriction.None) {
            return false;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    /**
     * @notice Reverts if all transfers are disabled to prevent users from
     * approving marketplaces even though the tokens can't be traded.
     */
    function setApprovalForAll(address operator, bool toggle)
        public
        virtual
        override
    {
        if (!_bypass && transferRestriction() != TransferRestriction.None) {
            revert DisallowedByTransferRestriction();
        }

        return super.setApprovalForAll(operator, toggle);
    }

    /**
     * @notice Reverts if all transfers are disabled to prevent users from
     * approving marketplaces even though the tokens can't be traded.
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        if (!_bypass && transferRestriction() != TransferRestriction.None) {
            revert DisallowedByTransferRestriction();
        }

        return super.approve(operator, tokenId);
    }
}