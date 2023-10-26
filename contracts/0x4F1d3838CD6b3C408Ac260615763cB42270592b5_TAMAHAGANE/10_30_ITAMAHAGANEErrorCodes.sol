// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @dev custom error codes common to many contracts are predefined here
 */
interface ITAMAHAGANEErrorCodes {
    error TAMAHAGANE__AmountIsTooBig();
    error TAMAHAGANE__CannotMintAnymore();
    error TAMAHAGANE__InsufficientMintPrice();
    error TAMAHAGANE__InsufficientMintsLeft();
    error TAMAHAGANE__InvalidMerkleProof();
    error TAMAHAGANE__MismatchedArrayLengths();
    error TAMAHAGANE__MintAmountIsTooSmall();
    error TAMAHAGANE__MustMintWithinMaxSupply();
    error TAMAHAGANE__NoAvailableTokens();
    error TAMAHAGANE__NotEnoughTamaHagane();
    error TAMAHAGANE__NotOwnerOrBurnableContract();
    error TAMAHAGANE__NotReadyYet();
    error TAMAHAGANE__NotTamaHaganeId();
    error TAMAHAGANE__ReachedMaxTokens();
    error TAMAHAGANE__TokenIdAlreadyExists();
    error TAMAHAGANE__WithdrawFailed();
}