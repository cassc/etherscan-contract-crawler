// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Errors {
    error WithdrawalPercentageWrongSize();
    error WithdrawalPercentageNot100();
    error WithdrawalPercentageZero();
    error MintNotAvailable();
    error InsufficientFunds();
    error SupplyLimitReached();
    error ContractCantMint();
    error InvalidSignature();
    error AccountAlreadyMintedMax();
    error TokenDoesNotExist();
    error NotOwner();
    error NotAuthorized();
    error MaxSupplyTooSmall();
    error CanNotIncreaseMaxSupply();
    error InvalidOwner();
    error TokenNotTransferable();

    error RoyaltiesPercentageTooHigh();
    error NothingToWithdraw();
    error WithdrawFailed();

    /* ReentrancyGuard.sol */
    error ContractLocked();

    /* Signable.sol */
    error NewSignerCantBeZero();

    /* StableMultiMintERC721.sol */
    error PaymentTypeNotEnabled();

    /* AgoriaXLedger.sol */
    error WrongInputSize();
    error IdBeyondSupplyLimit();
    error InvalidBaseContractURL();
    error InvalidBaseURI();
}