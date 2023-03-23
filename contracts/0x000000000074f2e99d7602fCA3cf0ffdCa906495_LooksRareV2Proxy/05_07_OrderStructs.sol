// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CollectionType} from "./OrderEnums.sol";

/**
 * @param signer The order's maker
 * @param collection The address of the ERC721/ERC1155 token to be purchased
 * @param collectionType 0 for ERC721, 1 for ERC1155
 * @param tokenIds The IDs of the tokens to be purchased
 * @param amounts Always 1 when ERC721, can be > 1 if ERC1155
 * @param price The *taker bid* price to pay for the order
 * @param currency The order's currency, address(0) for ETH
 * @param startTime The timestamp when the order starts becoming valid
 * @param endTime The timestamp when the order stops becoming valid
 * @param signature split to v,r,s for LooksRare
 */
struct BasicOrder {
    address signer;
    address collection;
    CollectionType collectionType;
    uint256[] tokenIds;
    uint256[] amounts;
    uint256 price;
    address currency;
    uint256 startTime;
    uint256 endTime;
    bytes signature;
}

/**
 * @param amount ERC20 transfer amount
 * @param currency ERC20 transfer currency
 */
struct TokenTransfer {
    uint256 amount;
    address currency;
}