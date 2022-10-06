// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IError {

    error InvalidEtherAmount(uint256 sent, uint256 required);
    error InvalidReferalCode();
    error ReferalCodeHasAlreadyBeenAssigned();
    error DisableSaleToChangeSupply();
    error InvalidSaleState();
    error InvalidMaxSupply();
    error TokenIdDoesNotExist();
    error PreSaleNotActive();
    error PublicSaleNotActive();
    error MaxSupplyExceeded();
    error WithdrawFailed();
    error PreSaleAllocationExceeded();
    error ArrayLengthMismatch();
    error InvalidMerkleProof();
    error NonEOA();
    error TokenIsLocked();
    error InvalidCaller();
    error InvalidAddress();

    // Staking Errors
    error NotFromApprovedContract();
    error TokenIdHasAlreadyBeenLockedByCaller();
    error TokenIdHasNotBeenLockedByCaller();
    error ContractMustNoLongerBeApproved();
    error TokenIdNotLockedByContract();
    error MustBeTokenOwnerToLock();
    error MustBeTokenOwnerToUnlock();
    
}