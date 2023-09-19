// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Bid, Input} from "./BidStructs.sol";

error InvalidBidParameters(Bid bid);
error InvalidSignature(Input input);
error SenderNotBidder(address sender, address bidder);
error BidAlreadyCancelledOrFilled(Bid bid);
error ETHTransferFailed(address recipient);
error FeeRateTooHigh(uint256 feeRate);
error InvalidPunkIndex(uint256 punkIndex);
error InvalidPunkBaseType();
error InvalidPunkAttributesCount(uint8 punkAttributesCount, uint8 bidAttributesCount);
error PunkMissingAttributes();
error PunkNotForSale(uint256 punkIndex);
error PunkNotGloballyForSale(uint256 punkIndex, address toAddress);
error BidAmountTooLow(uint256 price, uint256 bidAmount);
error BuyPunkFailed(uint256 punkIndex);
error TransferPunkFailed(uint256 punkIndex);
error PunkNotSelected(uint256 punkIndex);
error PunkExcluded(uint256 punkIndex);