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

    /* MultiMint1155.sol */
    error MismatchLengths();
    error AccountMaxMintAmountExceeded();
    error InvalidMintMaxAmount();
    error InvalidMintPrice();
    error InsufficientBalance();
    error TokenSaleClosed(uint256 tokenId);
    error TokenGatedIdAlreadyUsed(uint256 tokenGatedId);
    error TokenAlreadyMinted();
    error MintDeadlinePassed();
    error TokenGatedIdAlreadyUsedInSeason(
        uint256 tokenGatedId,
        uint256 seasonId
    );
    error TokenNotSupported();
    error InvalidDeadlineLength();
    error OneTokenPerPass();
    error SignatureLengthMismatch();
    error TokenPriceNotSet();
    error DeadlineNotSet();
    error InvalidDeadlines();
}