// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**
 * @title LibLoan
 * @author Spice Finance Inc
 */
library LibLoan {
    /// @notice Loan State
    enum LoanState {
        NOT_IN_USE,
        Active,
        Repaid,
        Defaulted
    }

    /// @notice Loan Terms struct
    struct LoanTerms {
        address lender;
        uint256 loanAmount;
        uint160 interestRate;
        uint32 duration;
        address collateralAddress;
        uint256 collateralId;
        address borrower;
        uint256 expiration;
        address currency;
        bool priceLiquidation;
    }

    /// @notice Loan Data struct
    struct LoanData {
        LoanState state;
        LoanTerms terms;
        uint256 startedAt;
        uint256 balance;
        uint256 interestAccrued;
        uint256 updatedAt;
    }

    /// @notice Get LoanTerms struct hash
    /// @param _terms Loan Terms
    /// @return hash struct hash
    function getLoanTermsHash(
        LoanTerms calldata _terms
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "LoanTerms(address lender,uint256 loanAmount,uint160 interestRate,uint32 duration,address collateralAddress,uint256 collateralId,address borrower,uint256 expiration,address currency,bool priceLiquidation)"
                    ),
                    _terms.lender,
                    _terms.loanAmount,
                    _terms.interestRate,
                    _terms.duration,
                    _terms.collateralAddress,
                    _terms.collateralId,
                    _terms.borrower,
                    _terms.expiration,
                    _terms.currency,
                    _terms.priceLiquidation
                )
            );
    }
}