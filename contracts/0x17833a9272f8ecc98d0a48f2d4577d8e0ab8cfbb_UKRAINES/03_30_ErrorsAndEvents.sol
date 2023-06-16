// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ErrorsAndEvents {

    error SoulboundNotTransferrable();
    
    error SlotIdInvalid();

    error InsufficientFunds();

    error ExceedsMaxSupply();

    error NotMintable();

    error PublicMintUnavailable();

    error InvalidSignature();

    error SignatureAlreadyUsed();

    error MismatchedParameters();

    error TokenLocked();

    error InsufficientPermissions();

    event NewItemCreated(uint indexed tokenId, uint indexed slotId);

}