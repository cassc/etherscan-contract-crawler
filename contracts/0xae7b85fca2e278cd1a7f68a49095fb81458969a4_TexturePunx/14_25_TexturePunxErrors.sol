// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TexturePunxErrors {
    error PublicSaleNotActive();
    error QuantityExceedsMaxSupply();
    error QuantityExceedsReservedSupply();
    error NotEnoughETH();
    error AlreadyMinted();
    error TokenDoesNotExist();

    error InvalidDNASequence();

    error InvalidSerialization_SpecifiedValueForInvalidParams();
    error InvalidSerialization_NotUnique();
    error InvalidSerialization_UndefinedTrait(uint8 categoryId);
    error InvalidSerialization_MissingRequiredTrait(uint8 categoryId);
    error InvalidSerialization_TraitExceedsMaxUses(uint8 categoryId, uint8 traitId);


    error NotPermissionedMinter();
    error NotOnWhitelist();

    error InvalidMintRound();
    error InvalidCategoryIndex();
    error InvalidTraitIndex();
    error IndexOutOfBounds();

    error WithdrawTransferFailed();
}