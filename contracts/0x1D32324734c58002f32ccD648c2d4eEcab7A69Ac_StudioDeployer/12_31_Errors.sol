// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Voucher Auth errors
error InvalidAuthorizationSignature();
error VoucherUsed();
error VoucherNotValidYet(uint256 start, uint256 timeNow);
error AuthorizationExpired(uint256 expiry, uint256 timeNow);

error ContractPaused();
error UserBlackListed();

// Drop Errors
error DropCancelled(uint256 dropId);
error DropEnded(uint256 dropId);
error DropNotFound(uint256 dropId);
error DropNotStarted(uint256 dropId);
error DropStarted(uint256 dropId);
error DuplicateDrop(uint256 dropId);
error ItemsRequired();
error InvalidAddress();
error InvalidDropType();
error InvalidDropStart();
error ItemNotFound(uint256 dropId, uint256 itemId);
error ItemSoldOut(uint256 dropId, uint256 itemId);

// Payment split errors
error PayoutZeroAddress();