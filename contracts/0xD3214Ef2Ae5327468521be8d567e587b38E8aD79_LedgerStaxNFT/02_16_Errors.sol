// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    error InsufficientFunds();
    error TokenDoesNotExist();
    error NothingToWithdraw();
    error InvalidOwner();
    error MintNotAvailable();
    error SupplyLimitReached();
    error ArtOfStaxMintPassNotSet();
    error InvalidSignature();
    error AccountAlreadyMintedMax();
    error MaxSupplyTooSmall();
    error CanNotIncreaseMaxSupply();

    /* Signable.sol */
    error NewSignerCantBeZero();

    /* ReentrancyGuard.sol */
    error ContractLocked();
}