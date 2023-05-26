// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* TODO: Refactor error codes from string -> bytes32 */

/* For ERC721Essentials.sol */
abstract contract BaseErrorCodes {
    /* solhint-disable const-name-snakecase */
    string internal constant kErrInsufficientFunds = "Insufficient Funds";
    string internal constant kErrSoldOut = "Sold Out";
    string internal constant kErrTokenDoesNotExist = "nonexistent token";
    string internal constant kErrRequestTooLarge = "Requested too many Tokens";
    string internal constant kErrOutsideMintPerTransaction = "Outside mint per tx range";
    string internal constant kErrMintingIsDisabled = "Minting is disabled";
    string internal constant kErrIncorrectConfirmationCode = "Bad confirmation";
    string internal constant kErrExternalCallFailed = "Failure calling external contract";
    /* solhint-enable const-name-snakecase */
}

/* For ERC721PresaleMintWithOffchainAllowlist.sol */
abstract contract AllowlistErrorCodes {
    /* solhint-disable const-name-snakecase */
    string internal constant kErrPublicMintSoldout = "Remaining Tokens are restricted";
    string internal constant kErrRestrictedRequestTooLarge = "Requested too many restricted Tokens";
    /* solhint-enable const-name-snakecase */
}

/* For ERC721ClaimFromContracts.sol */
abstract contract ClaimFromContractErrorCodes {
    /* solhint-disable const-name-snakecase */
    string internal constant kErrAlreadyClaimed = "Already redeemed your new tokens";
    string internal constant kErrOutOfPurchasable = "Remaining mints reserved for claims";
    string internal constant kErrOutOfClaimable = "Remaining mints reserved for purchases";
    string internal constant kErrClaimingNotEnabled = "Claiming is currently disabled";
    /* solhint-enable const-name-snakecase */
}