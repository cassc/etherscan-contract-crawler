// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title LoanLibrary
 * @author Non-Fungible Technologies, Inc.
 *
 * Contains all data types used across Arcade lending contracts.
 */
library LoanLibrary {
    /**
     * @dev Enum describing the current state of a loan.
     * State change flow:
     * Created -> Active -> Repaid
     *                   -> Defaulted
     */
    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        DUMMY_DO_NOT_USE,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    /**
     * @dev The raw terms of a loan.
     */
    struct LoanTerms {
        // Interest expressed as a rate, unlike V1 gross value.
        // Input conversion: 0.01% = (1 * 10**18) ,  10.00% = (1000 * 10**18)
        // This represents the rate over the lifetime of the loan, not APR.
        // 0.01% is the minimum interest rate allowed by the protocol.
        uint256 proratedInterestRate;
        /// @dev Full-slot variables
        // The amount of principal in terms of the payableCurrency.
        uint256 principal;
        // The token ID of the address holding the collateral.
        /// @dev Can be an AssetVault, or the NFT contract for unbundled collateral
        address collateralAddress;
        /// @dev Packed variables
        // The number of seconds representing relative due date of the loan.
        /// @dev Max is 94,608,000, fits in 96 bits
        uint96 durationSecs;
        // The token ID of the collateral.
        uint256 collateralId;
        // The payable currency for the loan principal and interest.
        address payableCurrency;
        // Timestamp for when signature for terms expires
        uint96 deadline;
        // Affiliate code used to start the loan.
        bytes32 affiliateCode;
    }

    /**
     * @dev Modification of loan terms, used for signing only.
     *      Instead of a collateralId, a list of predicates
     *      is defined by 'bytes' in items.
     */
    struct LoanTermsWithItems {
        // Interest expressed as a rate, unlike V1 gross value.
        // Input conversion: 0.01% = (1 * 10**18) ,  10.00% = (1000 * 10**18)
        // This represents the rate over the lifetime of the loan, not APR.
        // 0.01% is the minimum interest rate allowed by the protocol.
        uint256 proratedInterestRate;
        /// @dev Full-slot variables
        // The amount of principal in terms of the payableCurrency.
        uint256 principal;
        // The tokenID of the address holding the collateral
        address collateralAddress;
        /// @dev Packed variables
        // The number of seconds representing relative due date of the loan.
        /// @dev Max is 94,608,000, fits in 96 bits
        uint96 durationSecs;
        // An encoded list of predicates, along with their verifiers.
        bytes items;
        // The payable currency for the loan principal and interest.
        address payableCurrency;
        // Timestamp for when signature for terms expires
        uint96 deadline;
        // Affiliate code used to start the loan.
        bytes32 affiliateCode;
    }

    /**
     * @dev Predicate for item-based verifications
     */
    struct Predicate {
        // The encoded predicate, to decoded and parsed by the verifier contract.
        bytes data;
        // The verifier contract.
        address verifier;
    }

    /**
     * @dev Snapshot of lending fees at the time of loan creation.
     */
    struct FeeSnapshot {
        // The fee taken when lender claims defaulted collateral.
        uint16 lenderDefaultFee;
        // The fee taken from the borrower's interest repayment.
        uint16 lenderInterestFee;
        // The fee taken from the borrower's principal repayment.
        uint16 lenderPrincipalFee;
    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct LoanData {
        /// @dev Packed variables
        // The current state of the loan.
        LoanState state;
        // Start date of the loan, using block.timestamp.
        uint160 startDate;
        /// @dev Full-slot variables
        // The raw terms of the loan.
        LoanTerms terms;
        // Record of lending fees at the time of loan creation.
        FeeSnapshot feeSnapshot;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes extraData;
    }
}