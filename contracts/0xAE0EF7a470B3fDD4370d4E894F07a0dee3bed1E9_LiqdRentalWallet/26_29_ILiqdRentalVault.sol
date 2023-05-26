// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../library/NftTransferLibrary.sol";

interface ILiqdRentalVault {
    // structs
    enum RentalStatus {
        INRENT,
        EXPIRED
    }
    struct Rental {
        address lender;
        address borrower;
        address wallet; // liqd rental wallet
        address collection;
        uint256 tokenId;
        uint32 expireAt;
        NftTransferLibrary.NftTokenType nftTokenType;
        RentalStatus status;
    }
    struct RentalSignatures {
        bytes lenderSignature; // we need this to handle rentals correctly on backend
        bytes borrowerSignature; // we need this to handle rentals correctly on backend
    }
    struct TokenRentalRequestFromBorrower {
        address lender;
        address borrower;
        // token information
        address collection;
        uint256 tokenId;
        NftTransferLibrary.NftTokenType nftTokenType;
        // request terms
        address payCurrency;
        uint256 payAmount;
        uint32 rentalDuration; // in seconds
        uint32 expireAt;
        uint32 createdAt; // signature creation timestamp, this is important field, user can request rental again after repayment
    }
    struct TokenRentalRequestFromLender {
        address lender;
        // token information
        address collection;
        uint256 tokenId;
        NftTransferLibrary.NftTokenType nftTokenType;
        // request terms
        address payCurrency;
        uint256 payAmount;
        uint32 rentalDuration; // in seconds
        uint32 expireAt;
        uint32 createdAt; // signature creation timestamp, this is important field, user can request rental again after repayment
    }

    struct CollectionRentalRequestFromBorrower {
        address borrower;
        // token information
        address collection;
        NftTransferLibrary.NftTokenType nftTokenType;
        // request terms
        address payCurrency;
        uint256 payAmount;
        uint32 rentalDuration; // in seconds
        uint32 expireAt;
        uint32 createdAt; // signature creation timestamp, this is important field, user can request rental again after repayment
    }

    function invokeVerifier() external view returns (address);

    function queryRental(uint256 rentalId)
        external
        view
        returns (Rental memory rental);
}