// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @dev custom error codes common to many contracts are predefined here
 */
interface IDNAErrorCodes {
    error DNA__AlreadyUsed();
    error DNA__AmountIsTooBig();
    error DNA__CannotMintAnymore();
    error DNA__InsufficientMintPrice();
    error DNA__InsufficientMintsLeft();
    error DNA__InvalidAddress();
    error DNA__InvalidMerkleProof();
    error DNA__MismatchedArrayLengths();
    error DNA__MintAmountIsTooSmall();
    error DNA__MustMintWithinMaxSupply();
    error DNA__NoAvailableTokens();
    error DNA__NotEnoughDNA();
    error DNA__NotOwnerOrBurnableContract();
    error DNA__NotReadyYet();
    error DNA__NotDNAId();
    error DNA__ReachedMaxTokens();
    error DNA__TokenIdAlreadyExists();
    error DNA__WithdrawFailed();
}