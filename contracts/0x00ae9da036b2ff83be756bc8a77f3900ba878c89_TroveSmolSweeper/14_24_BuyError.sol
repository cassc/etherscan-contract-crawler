// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Errors
 */

enum BuyError {
    NONE,
    BUY_ITEM_REVERTED,
    INSUFFICIENT_QUANTITY_ERC1155,
    EXCEEDING_MAX_SPEND
}