// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";

struct PurchaseCountsAndLimits {
    uint16 total;
    uint16 totalLimit;
    uint16 generalAdmission;
    uint16 generalAdmissionLimit;
}

/**
 * @title Proof of Conference Tickets - Purchase limit by wallet module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract PurchaseLimiter is AccessControlEnumerable {
    // =========================================================================
    //                           Errors
    // =========================================================================

    error ExceedingAvailableTokens();
    error ExceedingPurchaseLimit();
    error ExceedingGeneralAdmissionPurchaseLimit();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The role allowed to change the purchase limits for a given
     * wallet.
     */
    bytes32 public constant PURCHASE_LIMIT_SETTER_ROLE =
        keccak256("PURCHASE_LIMIT_SETTER_ROLE");

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The number of tickets sold.
     */
    uint16 private _numTicketsSold;

    /**
     * @notice The the number of sellable tickets.
     */
    uint16 private _numTicketsSellable = 4000;

    /**
     * @notice The default total purchase limit for each wallet.
     */
    uint16 private _defaultTotalPurchaseLimit = 10;

    /**
     * @notice The default purchase limit through the general admission sale.
     */
    uint16 private _defaultGeneralAdmissionPurchaseLimit = 2;

    /**
     * @notice Purchase counts and explicit purchase limits by wallet.
     */
    mapping(address => PurchaseCountsAndLimits) private _countsAndLimits;

    // =========================================================================
    //                           Getters
    // =========================================================================

    /**
     * @notice Returns the current number of purchases and limits for a given
     * wallet.
     */
    function purchaseCountsAndLimits(address wallet)
        public
        view
        returns (PurchaseCountsAndLimits memory)
    {
        PurchaseCountsAndLimits memory cl = _countsAndLimits[wallet];
        if (cl.totalLimit == 0) {
            cl.totalLimit = _defaultTotalPurchaseLimit;
        }
        if (cl.generalAdmissionLimit == 0) {
            cl.generalAdmissionLimit = _defaultGeneralAdmissionPurchaseLimit;
        }
        return cl;
    }

    /**
     * @notice The number of tickets that have already been sold.
     */
    function numTicketsSold() external view returns (uint256) {
        return _numTicketsSold;
    }

    /**
     * @notice The total number of tickets that can been sold.
     */
    function numTicketsSellable() external view returns (uint256) {
        return _numTicketsSellable;
    }

    /**
     * @notice Returns the total purchase limit used as default if explicit no
     * limit was set for a given wallet.
     */
    function _defaultTotalLimit() internal view returns (uint16) {
        return _defaultTotalPurchaseLimit;
    }

    /**
     * @notice Returns the general admission purchase limit used as default if
     * no explicit limit was set for a given wallet.
     */
    function _defaultGeneralAdmissionLimit() internal view returns (uint16) {
        return _defaultGeneralAdmissionPurchaseLimit;
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the number of sellable tickets.
     */
    function setNumTicketsSellable(uint16 numSellable)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _numTicketsSellable = numSellable;
    }

    /**
     * @notice Sets the default purchase limits.
     */
    function setDefaultPurchaseLimits(
        uint16 totalLimit,
        uint16 generalAdmissionLimit
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        _defaultTotalPurchaseLimit = totalLimit;
        _defaultGeneralAdmissionPurchaseLimit = generalAdmissionLimit;
    }

    /**
     * @notice Sets explicit purchase limits for a given wallet.
     */
    function setPurchaseLimits(
        address wallet,
        uint16 totalLimit,
        uint16 generalAdmissionLimit
    ) external onlyRole(PURCHASE_LIMIT_SETTER_ROLE) {
        PurchaseCountsAndLimits storage cl = _countsAndLimits[wallet];
        cl.totalLimit = totalLimit;
        cl.generalAdmissionLimit = generalAdmissionLimit;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Checks if a given buyer is allowed to purchase a given number of
     * tokens and tracks them.
     */
    function _checkAndTrackPurchaseLimits(
        address buyer,
        uint256 numTotal,
        uint256 numGA
    ) internal virtual {
        if (_numTicketsSold + numTotal > _numTicketsSellable) {
            revert ExceedingAvailableTokens();
        }

        PurchaseCountsAndLimits memory countsAndLimits =
            purchaseCountsAndLimits(buyer);
        if (countsAndLimits.total + numTotal > countsAndLimits.totalLimit) {
            revert ExceedingPurchaseLimit();
        }
        if (
            countsAndLimits.generalAdmission + numGA
                > countsAndLimits.generalAdmissionLimit
        ) {
            revert ExceedingGeneralAdmissionPurchaseLimit();
        }

        _numTicketsSold += uint16(numTotal);
        _countsAndLimits[buyer].total += uint16(numTotal);
        _countsAndLimits[buyer].generalAdmission += uint16(numGA);
    }
}