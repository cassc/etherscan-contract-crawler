// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

error BidBelowThreshold(uint256 requestBid, uint256 currentBid);
error AccountMismatch(address sent, address expected);
error InvalidRefund(address to, uint256 amount);
error AuctionDoesNotExist(bytes32 id);
error AuctionAlreadyExist(bytes32 id);