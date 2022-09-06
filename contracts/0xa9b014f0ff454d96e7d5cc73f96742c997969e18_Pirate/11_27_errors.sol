// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

error ArgumentMismatch();
error CallerNotEOA();
error IllegalUpgrade(uint256 tokenId, uint256 tier);
error InsufficientFunds();
error InvalidTraitType();
error MintingUnavailable();
error MintLimitExceeded(uint256 limit);
error OutOfRange(uint256 min, uint256 max);
error SoldOut();
error TierUnavailable(uint256 tier);
error TokenNotFound(uint256 value);
error Unauthorized();