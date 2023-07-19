// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    Fees,
    FeeRate,
    Transfer,
    OrderType
} from "../lib/Structs.sol";

interface IExecutor {
    error ETHTransferFailed();
    error PoolTransferFailed();
    error PoolWithdrawFromFailed();
    error PoolDepositFailed();
    error OrderFulfilled();

    event Execution(
        Transfer transfer,
        bytes32 orderHash,
        uint256 listingIndex,
        uint256 price,
        FeeRate makerFee,
        Fees fees,
        OrderType orderType
    );

    event Execution721Packed(
        bytes32 orderHash,
        uint256 tokenIdListingIndexTrader,
        uint256 collectionPriceSide
    );

    event Execution721TakerFeePacked(
        bytes32 orderHash,
        uint256 tokenIdListingIndexTrader,
        uint256 collectionPriceSide,
        uint256 takerFeeRecipientRate
    );

    event Execution721MakerFeePacked(
        bytes32 orderHash,
        uint256 tokenIdListingIndexTrader,
        uint256 collectionPriceSide,
        uint256 makerFeeRecipientRate
    );
}