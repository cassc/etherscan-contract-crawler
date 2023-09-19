// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/**
 * @title Collection Struct Interface
 * @dev   interface to for all the struct required for setup parameters.
 * @author Chain Labs Team
 */
/// @title Collection Struct Interface
/// @author Chain Labs
/// @notice interface for all the struct required for setup parameters.
interface ICollectionStruct {
    struct BaseCollectionStruct {
        string name;
        string symbol;
        address admin;
        uint256 maximumTokens;
        uint16 maxPurchase;
        uint16 maxHolding;
        uint256 price;
        uint256 publicSaleStartTime;
        string projectURI;
    }

    struct Whitelist {
        bytes32 root;
        string cid;
    }

    struct PresaleableStruct {
        uint256 presaleReservedTokens;
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleMaxHolding;
        Whitelist presaleWhitelist;
    }

    struct PaymentSplitterStruct {
        address simplr;
        uint256 simplrShares;
        address[] payees;
        uint256[] shares;
    }
}