// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SaleOrder, MintRequest, BuyRequest, RentOrder, RentRequest, StakeRequest} from "../common/Structs.sol";

library Utils {
    /**
     * @dev Returns the size of a sale order struct
     */
    function sizeOfSaleOrder(SaleOrder memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 3) + (0x14 * 1) + _item.saleOrderId.length);
    }

    /**
     * @dev Returns the size of a mint request struct
     */
    function sizeOfMintRequest(MintRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 3) +
            (0x14 * 2) +
            _item.nftId.length +
            _item.saleOrderSignature.length +
            _item.transactionId.length);
    }

    /**
     * @dev Returns the size of a buy request struct
     */
    function sizeOfBuyRequest(BuyRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 3) +
            (0x14 * 2) +
            _item.saleOrderSignature.length +
            _item.transactionId.length);
    }

    /**
     * @dev Returns the size of a rent order struct
     */
    function sizeOfRentOrder(RentOrder memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 4) +
            (0x14 * 2) +
            _item.transactionId.length);
    }

    /**
     * @dev Returns the size of a rent request struct
     */
    function sizeOfRentRequest(RentRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 4) +
            (0x14 * 2) +
            _item.transactionId.length);
    }

    /**
     * @dev Returns the size of a sale order struct
     */
    function sizeOfStakeRequest(StakeRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 1) + (0x14 * 1) + _item.poolId.length 
        + _item.internalTxId.length);
    }

}