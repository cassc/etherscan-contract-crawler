// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library CustomErrors {
    /**
     * Raised when trying to manipulate editions (CRUD) with invalid data
     */
    error InvalidEditionData();

    error MaxSupplyError();

    error InvalidEditionId();
    /**
     * Raised when trying to mint with invalid data
     */
    error InvalidMintData();

    /**
     * Raised when trying to transfer an NFT to a non ERC721Receiver
     */
    error NotERC721Receiver();

    /**
     * Raised when trying to query a non minted token
     */
    error TokenNotFound();

    /**
     * Raised when transfer fail
     */
    error TransferError();

    /**
     * Generic Not Allowed action
     */
    error NotAllowed();

    /**
     * Generic Not Found error 
     */
    error NotFound();

    /**
     * Raised when direct minting with insufficient funds
     */
    error InsufficientFunds();

    /**
     * Raised when fund transfer fails
     */
    error FundTransferError();

    error MintClosed();
    error MaximumMintAmountReached();
    error BurnRedeemNotAvailable();

}