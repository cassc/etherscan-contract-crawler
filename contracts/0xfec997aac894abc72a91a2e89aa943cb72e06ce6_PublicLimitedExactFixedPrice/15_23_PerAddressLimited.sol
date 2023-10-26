// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {Seller} from "./Seller.sol";

/**
 * @notice A seller module to limit the number of items purchased per address.
 */
abstract contract PerAddressLimited is Seller {
    /**
     * @notice Thrown when the number of requested purchases exceeds the per-address limit.
     * @dev We're using a signed int for `numLeft` since the value can be negative if the per-address limit is lowered
     * after items have already been purchased.
     */
    error ExceedingMaxPerAddressLimit(uint64 numRequested, int128 numLeft);

    /**
     * @notice Max number of purchases per address.
     * @dev `_maxPerAddress = 0` means this limit will be ignored.
     */
    uint64 private _maxPerAddress;

    /**
     * @notice Tracks the number of items already bought by an address.
     */
    mapping(address => uint64) private _bought;

    /**
     * @notice Sets a new limit.
     */
    function _setMaxPerAddress(uint64 maxPerAddress_) internal {
        _maxPerAddress = maxPerAddress_;
    }

    /**
     * @notice The maximum number of purchases per address.
     */
    function maxPerAddress() public view returns (uint64) {
        return _maxPerAddress;
    }

    /**
     * @notice The number of items already bought by an address.
     */
    function numPurchasedBy(address addr) public view returns (uint64) {
        return _bought[addr];
    }

    // -------------------------------------------------------------------------
    //
    //  Internals
    //
    // -------------------------------------------------------------------------

    /**
     * @inheritdoc Seller
     * @dev Checks if the number of requested purchases is below the limits.  Reverts otherwise.
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 totalCost, bytes memory data)
        internal
        view
        virtual
        override(Seller)
        returns (address, uint64, uint256)
    {
        (to, num, totalCost) = Seller._checkAndModifyPurchase(to, num, totalCost, data);

        // Casting to signed integers to avoid potential underflows if the per-address limit is lowered after items have
        // already been purchased.
        int128 remaining = int128(uint128(_maxPerAddress)) - int128(uint128(_bought[msg.sender]));
        if (int128(uint128(num)) > remaining) {
            revert ExceedingMaxPerAddressLimit(num, remaining);
        }

        return (to, num, totalCost);
    }

    /**
     * @inheritdoc Seller
     * @dev Updating the number of items bought by the purchaser.
     */
    function _beforePurchase(address to, uint64 num, uint256 totalCost, bytes memory data)
        internal
        virtual
        override(Seller)
    {
        Seller._beforePurchase(to, num, totalCost, data);
        _bought[msg.sender] += num;
    }
}