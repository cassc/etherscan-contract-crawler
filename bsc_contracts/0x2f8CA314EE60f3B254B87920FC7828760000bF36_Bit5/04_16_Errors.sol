// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Bit5Errors {
    error Unauthorized();
    error WrongSignature();
    error AlreadyProcessed();
    error WrongOrderKind();
    error WrongTokenKind();
    error CanNotBuyOwnedToken();
    error OrderExpired();
    error TokenTransferFailed();
    error InvalidPaymentToken();
    error NotEnoughGlobalBids();
    error CollectionIsNotPrivileged();
    error ExceedsMaxRoyaltyPercentage();
    error AlreadyDefined();
    error CannotAddRoyalties();
}