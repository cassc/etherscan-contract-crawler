// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Types
 * @notice This library contains order types for the Minthree marketplace.
 */
library Types {
    struct Order {
        bytes signature;
        address seller;
        address collection;
        address currency;
        uint256 price;
        uint256 endTime;
        bytes32 salt;
        uint256 token_id;
    }

    struct Offer {
        bytes signature;
        address offerer;
        address collection;
        uint256 price;
        uint256 endTime;
        bytes32 salt;
        uint256 token_id;
    }

    struct CollectionOffer {
        bytes signature;
        address offerer;
        address collection;
        uint256 price;
        uint8 amount;
        uint256 endTime;
        bytes32 salt;
        uint256 token_id;
    }

    struct Bid {
        address from;
        uint256 bidPrice;
    }
}